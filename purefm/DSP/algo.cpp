//
//  algo.cpp
//  purefm
//
//  Created by Paul Forgey on 4/29/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#include "algo.hpp"
#include <algorithm>

algo::algo(globals const *g, int const &lfo, int const &pitch, int const &pressure) {
    _globals = g;
    _patch = nullptr;

    for (auto &&o : _ops) {
        o = new op(g, lfo, pitch, pressure);
    }
}

algo::~algo() {
    for (auto &&o : _ops) {
        delete o;
        o = nullptr;
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
        _ops[i]->update(op, true);
    }
}

void
algo::set_op_node(int op_num, int sum, int mod) {
    auto &o = _ops[op_num];

    if (sum < 0) {
        o->set_sum(nullptr);
    } else {
        o->set_sum(_ops[sum]);
    }

    if (mod < 0) {
        o->set_mod(nullptr);
    } else if (mod <= op_num) {
        o->set_fb_input(&_fb);
        _ops[mod]->set_fb_output(&_fb);
    } else {
        o->set_mod(_ops[mod]);
    }
}

void
algo::start(patch const *patch, int key, int velocity) {
    _patch = patch;
    if (patch == nullptr) {
        return;
    }

    for (int i = 0; i < 8; ++i) {
        _ops[i]->start(_patch->ops[i], key, velocity);
    }
}

void
algo::step(int *out) {
    if (_patch == nullptr) {
        return;
    }

    for (int i = 0; i < 16; ++i) {
        _fb.step(_patch->feedback);
        int o0 = 0;
        for (int j = 7; j >= 0; --j) {
            op *o = _ops[j];
            o0 = o->step();
        }
        *(out++) = o0;
    }
}
