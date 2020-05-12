//
//  op.cpp
//  purefm
//
//  Created by Paul Forgey on 4/29/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#include "op.hpp"
#include "globals.hpp"

#include <cmath>

op::op(globals const *g)
    : _osc(g->t), _env(g) {
    _globals = g;
    _patch = nullptr;
    _sum = &_zero;
    _mod = &_zero;
    _out = 0;
    _fb = nullptr;
}

op::~op() {
}

void
op::update(op_patch const *patch) {
    _patch = patch;
    if (patch != nullptr) {
        _env.update(patch->env.get());
    } else {
        _env.update(nullptr);
    }
}

static inline int
key_scale(int value, int type) {
    if ((type & scale_exp) != 0) {
        value = (int)std::exp2((double)value * (23.0 / 4096.0));
    } else {
        value <<= 11;
    }
    if ((type & scale_up) != 0) {
        return value;
    }
    return -value;
}

void
op::set_sum(op const *s) {
    if (s == nullptr) {
        _sum = &_zero;
    } else {
        _sum = &s->_out;
    }
}

void
op::set_mod(op const *s) {
    if (s == nullptr) {
        _mod = &_zero;
    } else {
        _mod = &s->_out;
    }
}

void
op::set_fb_input(fb_filter const *f) {
    if (f == nullptr) {
        _mod = &_zero;
    } else {
        _mod = f->output();
    }
}

void
op::set_fb_output(fb_filter *f) {
    _fb = f;
}

void
op::start(op_patch const *patch, int key, int velocity) {
    update(patch);
    if (patch == nullptr) {
        return;
    }

    if (velocity == 0) {
        _env.start(patch->env.get(), 0, false);
        return;
    }

    int r = 128 - ((key * _patch->rate_scale) >> 7);

    if (r < 128) {
        r = _globals->t.duration_param(r);
    } else {
        r = 0;
    }

    _env.start(patch->env.get(), r, true);
    _level = patch->level;

    velocity = ((velocity - 96) >> (7 - _patch->velocity));
    _level += (velocity << 17);

    int scale = 0;
    if (key > _patch->breakpoint) {
        scale = key_scale((key - _patch->breakpoint) * _patch->key_scale_right,
            _patch->scale_type_right);
    } else {
        scale = key_scale((_patch->breakpoint - key) * _patch->key_scale_left,
            _patch->scale_type_left);
    }
    _level += scale;

    if (_level > eg_max) {
        _level = eg_max;
    } else if (_level < eg_min) {
        _level = eg_min;
    }

    if (patch->resync) {
        _osc.reset();
    }
}

int
op::step(int lfo, int pitch) {
    if (_patch == nullptr) {
        return 0;
    }
    if (!_patch->enabled) {
        return _out;
    }
    if (_env.idle()) {
        _out = *_sum;
        return _out;
    }

    int frequency = _patch->frequency;
    if (!_patch->fixed) {
        frequency += pitch;
    }

    int bias = _env.op_bias(lfo);

    bool neg;
    int mod = *_mod << 2;
    int out = _osc.step(_globals->t.pitch(frequency), mod, &neg);
    int eg = _env.step(1, bias) + _level;

    out = _globals->t.output(out, eg);
    out = (neg ? -out : out);

    // enter feedback loop _before_ summation
    if (_fb != nullptr) {
        _fb->input(out);
    }

    _out = out + *_sum;
    return _out;
}

