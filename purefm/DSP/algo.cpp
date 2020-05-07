//
//  algo.cpp
//  purefm
//
//  Created by Paul Forgey on 4/29/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#include "algo.hpp"
#include <algorithm>

static int const zero = 0;

algo::algo(globals const *g) {
    _globals = g;
    _patch = nullptr;
    
    for (int i = 0; i < 8; ++i) {
        _ops[i] = new op(g, &zero, &zero, &_outputs[i]);
    }

    std::fill_n(_outputs, 8, 0);
    std::fill_n(_fb, 4, 0);

    _fbo = &_outputs[0];
    _fba = 0;
}

algo::~algo() {
    for (auto&& o : _ops) {
        delete o;
    }
}

void
algo::update(patch const *patch) {
    _patch = patch;
    if (patch == nullptr) {
        return;
    }

    for (int i = 0; i < 8; ++i) {
        auto const &op = patch->ops[i];
        set_op_node(i, op->sum, op->mod);
        _ops[i]->update(op);
    }
}

void
algo::set_op_node(int op_num, int sum, int mod) {
    auto&& o = _ops[op_num];

    if (sum < 0) {
        o->set_sum(&zero);
    } else {
        o->set_sum(&_outputs[sum]);
    }

    if (mod < 0) {
        o->set_mod(&zero);
    } else if (mod <= op_num) {
        o->set_mod(&_fbi);
        _fbo = &_outputs[mod];
    } else {
        o->set_mod(&_outputs[mod]);
    }
}

void
algo::start(patch const *patch, int key, int velocity) {
    _patch = patch;
    if (patch == nullptr) {
        return;
    }

    for (int i = 0; i < 8; ++i) {
        _ops[i]->start(_patch->ops[i], key, patch->middle_c, velocity);
    }
}

int
algo::step(int lfo, int pitch) {
    if (_patch == nullptr) {
        return 0;
    }

    // moving average (of 4) feedback filter
    _fba += *_fbo - _fb[0];
    _fb[0] = _fb[1];
    _fb[1] = _fb[2];
    _fb[2] = _fb[3];
    _fb[3] = *_fbo;
    _fbi = (_fba * _patch->feedback) >> 9;

    // work the operators
    for (auto &&o : _ops) {
        o->step(lfo, pitch);
    }

    // output of op1
    return _outputs[0];
}
