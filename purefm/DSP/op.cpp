//
//  op.cpp
//  purefm
//
//  Created by Paul Forgey on 4/29/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#include "op.hpp"
#include "globals.hpp"

#include <algorithm>
#include <cmath>

op::op(
    globals const *g, int const *s, int const *m, int *o)
    : _osc(g->t), _env(g) {
    _globals = g;
    _sum = s;
    _mod = m;
    _out = o;
    _patch = nullptr;
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
op::start(op_patch const *patch, int key, int middle_c, int velocity) {
    _patch = patch;
    if (patch == nullptr) {
        return;
    }

    if (velocity == 0) {
        _env.start(patch->env.get(), 0, false);
        return;
    }

    int note = key - middle_c;

    _frequency = patch->frequency;
    if (!patch->fixed) {
        _frequency += _globals->t.scale(note);
    }
    _env.start(patch->env.get(), (note * _patch->rate_scale) >> 2, true);
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

    _level = std::max(_level, eg_min);
    _level = std::min(_level, eg_max);

    if (patch->resync) {
        _osc.reset();
    }
}

void
op::step(int lfo, int pitch) {
    if (_patch == nullptr) {
        return;
    }

    if (!_patch->enabled) {
        *_out = *_sum;
        return;
    }

    int frequency = _frequency;
    if (!_patch->fixed) {
        frequency += pitch;
    }

    int bias = 0;

    bool neg;
    int mod = *_mod << 2;
    int out = _osc.step(_globals->t.pitch(frequency), mod, &neg);
    int env = _env.op_value(_env.step(), lfo);
    env += bias + _level;

    out = _globals->t.output(out, env);
    out = (neg ? -out : out) + *_sum;
    *_out = out;
}
