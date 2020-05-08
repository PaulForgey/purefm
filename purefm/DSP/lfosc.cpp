//
//  lfosc.cpp
//  purefm
//
//  Created by Paul Forgey on 5/1/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#include "lfosc.hpp"
#include "globals.hpp"

lfo::lfo(globals const *g) : _env(g) {
    _globals = g;
    _patch = nullptr;
    _status = nullptr;
}

lfo::~lfo() {
}

void lfo::set_status(voice_status *status) {
    _status = status;
    _env.set_status(&_status->lfo_stage);
}

void
lfo::start(lfo_patch const *patch, int velocity) {
    _patch = patch;
    if (patch == nullptr) {
        return;
    }

    _env.start(patch->env.get(), 0, velocity != 0);
    _frequency = patch->frequency;

    if (velocity > 0 && patch->resync) {
        _osc.reset();
    }
}

void
lfo::update(lfo_patch const *patch) {
    _patch = patch;
    if (patch != nullptr) {
        _env.update(patch->env.get());
    } else {
        _env.update(nullptr);
    }
}

int
lfo::step() {
    int osc, env = eg_max;
    bool neg;

    if (_patch == nullptr) {
        return 0;
    }

    auto const &&f = _patch->wave.get();
    if (f == nullptr) {
        return 0;
    }

    unsigned long pitch = _globals->t.pitch(_frequency);
    osc = _osc.step(*f, _globals->t, pitch, 0, &neg);
    env = _env.step(1) + _patch->level;

    if (_status != nullptr) {
        _status->lfo_output = (env >> 9);
    }

    osc = _globals->t.output(osc, env);
    return neg ? -osc : osc;
}
