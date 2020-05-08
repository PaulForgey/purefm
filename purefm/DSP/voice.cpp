//
//  voice.cpp
//  purefm
//
//  Created by Paul Forgey on 4/30/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#include "voice.hpp"
#include "globals.hpp"

voice::voice(globals const *g) :
    _algo(g), _lfo(g), _pitch_env(g) {
    _globals = g;
    _counter = 0;
    _lfo_output = 0;
    _patch = nullptr;
    _key = -256;
    _trigger = false;
    _pitch = 0;
    _pitch_env.init_at(0);
}

voice::~voice() {
}

void
voice::update(patch const *patch) {
    _patch = patch;
    _algo.update(patch);

    if (patch != nullptr) {
        _pitch_env.update(patch->pitch_env.get());
        _lfo.update(patch->lfo.get());
    } else {
        _pitch_env.update(nullptr);
        _lfo.update(nullptr);
    }
}

void
voice::start(patch const *patch, int key, int velocity) {
    _patch = patch;
    if (patch == nullptr) {
        return;
    }

    _key = key;
    _trigger = (velocity > 0);

    _lfo.start(_patch->lfo.get(), velocity);
    _algo.start(patch, key, velocity);
    _pitch_env.start(_patch->pitch_env.get(), 0, _trigger);
}

int
voice::step() {
    if (_patch == nullptr) {
        return 0;
    }

    if (((_counter++) & 0x0f) == 0) {
        // lfo every 16
        _lfo_output = _lfo.step();
        _pitch = _pitch_env.pitch_value(_pitch_env.step(16), _lfo_output);
    }

    return _algo.step(_lfo_output, _pitch);
}
