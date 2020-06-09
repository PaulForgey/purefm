//
//  voice.cpp
//  purefm
//
//  Created by Paul Forgey on 4/30/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#include "voice.hpp"
#include "globals.hpp"

#include <algorithm>

static inline uint64_t
bitset(uint64_t bits, int pos) {
    return bits | (1ULL << pos);
}

static inline uint64_t
bitclear(uint64_t bits, int pos) {
    return bits & ~(1ULL << pos);
}

static inline bool
bittest(uint64_t bits, int pos) {
    return (bits & (1ULL << pos)) != 0;
}

static int
highest(uint64_t bits) {
    // special case terminal
    if (bittest(bits, 63)) {
        return 63;
    }
    int i, j;
    for (i = 31, j = 16; ;j >>= 1) {
        uint64_t t = (1ULL << i);
        if (bits == t) {
            return i;
        }
        if (bits > t) {
            if (j == 0) {
                return i;
            }
            i += j;
        } else {
            if (j == 0) {
                return i-1;
            }
            i -= j;
        }
    }
}

voice::voice(globals const *g) :
    _algo(g, _lfo_output, _pitch, _pressure), _lfo(g), _pitch_env(g) {
    _globals = g;
    _counter = 0;
    _lfo_output = 0;
    _patch = nullptr;
    _key = -256;
    _velocity = 0;
    _pitch = 0;
    _pitch_env.init_at(0);
    std::fill_n(_keys, 16, 0);
    std::fill_n(_output, 16, 0);
    for (int i = 0; i < 8; ++i) {
        _status.ops[i] = _algo.get_eg_status(i);
    }
    _status.pitch = _pitch_env.get_status();
    _status.lfo = _lfo.get_status();
    _pressure = 0;
    _pressure_in = 0;
    _priority = 0;
}

voice::~voice() {
}

void
voice::update(patch const *patch) {
    _patch = patch;
    _algo.update(patch);

    if (patch != nullptr) {
        _pitch_env.update(patch->pitch_env.get(), true);
        _lfo.update(patch->lfo.get());
    } else {
        _pitch_env.update(nullptr, true);
        _lfo.update(nullptr);
    }
}

int
voice::highest_key() const {
    if (_keys[1] != 0) {
        return highest(_keys[1])+64;
    }
    return highest(_keys[0]);
}

void
voice::start(patch const *patch, int key, int velocity) {
    _patch = patch;
    if (patch == nullptr) {
        return;
    }

    if (_patch->mono) {
        if (velocity > 0) {
            if (key >= 64) {
                _keys[1] = bitset(_keys[1], key-64);
            } else {
                _keys[0] = bitset(_keys[0], key);
            }
            if (highest_key() > key) {
                return;
            }
        } else {
            if (key >= 64) {
                _keys[1] = bitclear(_keys[1], key-64);
            } else {
                _keys[0] = bitclear(_keys[0], key);
            }
            int k = highest_key();
            if (k >= 0) {
                key = k;
                velocity = _velocity;
            }
        }
    }

    int f = _globals->t.scale(key - _patch->middle_c) + _patch->tuning;
    if (!_patch->mono || _velocity == 0) {
        _freq_eg.set(f << 8, f << 8, _patch->portamento);
    } else {
        _freq_eg.set(_freq_eg.get_level(), f << 8, _patch->portamento);
    }

    _key = key;
    _velocity = velocity;

    _lfo.start(_patch->lfo.get(), velocity);
    _algo.start(patch, key, velocity);
    _pitch_env.start(_patch->pitch_env.get(), 0, 0, velocity > 0);
}

void
voice::pressure(int pressure) {
    _pressure_in = pressure << 5;
}

int
voice::step() {
    if (_patch == nullptr) {
        return 0;
    }

    if (_pressure < _pressure_in) {
        _pressure++;
    }
    else if (_pressure > _pressure_in) {
        _pressure--;
    }

    if ((_counter & 0x0f) == 0) {
        // lfo, pitch every 16 (per eg step)
        if (((_counter >> 4) & _globals->eg_mask) == 0) {
            _lfo_output = _lfo.step();
            int const bias = _pitch_env.pitch_bias(_lfo_output);
            _pitch = _pitch_env.pitch_value(_pitch_env.step(16, bias)) +
                (_freq_eg.step(16) >> 8);
        }

        // run the engine 16 samples ahead
        _algo.step(_output);
    }
    return _output[_counter++ & 0x0f];
}
