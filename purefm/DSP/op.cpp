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

op::op(globals const *g, int const &lfo, int const &pitch)
    : _osc(g->t), _env(g), _lfo(lfo), _pitch(pitch) {
    _globals = g;
    _patch = nullptr;
    _sum = &_zero;
    _mod = &_zero;
    _out = 0;
    _eg = 0;
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
        _env.start(patch->env.get(), 0, 0, false);
        return;
    }

    int level = _patch->level;

    if (key > _patch->breakpoint) {
        level += key_scale((key - _patch->breakpoint) * _patch->key_scale_right,
            _patch->scale_type_right);
    } else {
        level += key_scale((_patch->breakpoint - key) * _patch->key_scale_left,
            _patch->scale_type_left);
    }
    velocity = ((velocity - 96) >> (7 - _patch->velocity));
    level += (velocity << 17);

    if (level < eg_min) {
        level = eg_min;
    } else if (level > eg_max) {
        level = eg_max;
    }

    int r = ((key * _patch->rate_scale) >> 7);
    _env.start(patch->env.get(), eg_min + level, r, true);

    if (patch->resync) {
        _osc.reset();
    }
}

int
op::step() {
    if (_patch == nullptr) {
        return 0;
    }
    if (!_patch->enabled || _env.idle()) {
        _out = *_sum;
        return _out;
    }

    int frequency = _patch->frequency;
    if (!_patch->fixed) {
        frequency += _pitch;
    }

    bool neg;
    int mod = *_mod << 2;
    int out = _osc.step(_globals->t.pitch(frequency), mod, &neg);

    if ((++_count & _globals->eg_mask) == 0) {
        int bias = _env.op_bias(_lfo);
        _eg = _env.step(1, bias);
    }

    out = _globals->t.output(out, _eg);
    out = (neg ? -out : out);

    // enter feedback loop _before_ summation
    if (_fb != nullptr) {
        _fb->input(out);
    }

    _out = out + *_sum;
    return _out;
}

