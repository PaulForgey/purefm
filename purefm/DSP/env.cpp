//
//  env.cpp
//  purefm
//
//  Created by Paul Forgey on 4/29/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#include "env.hpp"
#include "globals.hpp"

#include <algorithm>

envelope::envelope(globals const *g) {
    _globals = g;
    _level = eg_min;
    _out = eg_min;
    _patch = nullptr;
    _egs = nullptr;
    _trigger = false;
    _running = false;
    _stage = -1;
    _key_up = -1;
}

envelope::~envelope() {
}

int
envelope::pitch_value(int value, int lfo) {
    if (_patch == nullptr) {
        return 0;
    }
    return (value >> (8 + _patch->scale)) +
        (_globals->pitch_bend >> _patch->bend) +
        (lfo >> (8 + _patch->lfo));
}

int
envelope::op_value(int value, int lfo) {
    if (_patch == nullptr) {
        return 0;
    }
    // mod_wheel value is shifted over 5
    return value +
        (((lfo >> 8) >> _patch->lfo) << 8) +
        ((_globals->mod_wheel  >> _patch->expr) << 11);
}

void
envelope::update(env_patch const *patch) {
    _patch = patch;
    if (patch != nullptr) {
        _egs = patch->egs.get();
    } else {
        _egs = nullptr;
    }
}

void
envelope::start(env_patch const *patch, int rate_adj, bool trigger) {
    _patch = patch;
    if (patch == nullptr) {
        return;
    }

    _trigger = trigger;
    _egs = _patch->egs.get();
    _key_up = _patch->key_up;

    if (_key_up >= _egs->size()) {
        _key_up = -1;
    }

    if (trigger) {
        start(rate_adj);
    }
    else if (!_globals->sustain_pedal) {
        stop();
    }
}

void
envelope::start_with(env_patch const *patch, int level, bool trigger) {
    if (trigger) {
        _level = level;
        _out = level;
    }
    start(patch, 0, trigger);
}

void
envelope::start(int rate_adj) {
    _rate_adj = rate_adj;
    _running = true;
    set(0);
}

void
envelope::stop() {
    _running = false;

    if (_patch->loop) {
        set(_key_up);
    } else {
        if (_key_up >= 0) {
            set(_key_up);
        }
    }
}

void
envelope::set(int stage) {
    if (_egs->empty()) {
        _stage = -1;
        return;
    }

    if (stage >= 0 && stage >= _egs->size()) {
        if (_running && _patch->loop) {
            stage = 0;
        } else {
            stage = -1;
        }
    }
    _stage = stage;
    if (stage < 0) {
        return;
    }

    auto const &e = (*_egs)[stage];

    eg_type to_t = e->type;
    _goal = e->goal;
    _step = std::max(e->rate + _rate_adj, 1);

    if (to_t == eg_delay) {
        _level = eg_min;
        _goal = eg_max;
        _out = e->goal;
    }
    else if (to_t == eg_linear) {
        _level = eg_min + (_globals->t.exp((eg_max+1 - _out) >> 6) << 8);
    } else {
        _level = _out;
    }

    if ((_goal < _level && _step > 0) || (_goal > _level && _step < 0)) {
        _step = -_step;
    }
}

int
envelope::step() {
    // no patch? no output
    if (_patch == nullptr) {
        return eg_min;
    }
    // no stages? return output
    if (_stage < 0 || _egs->empty()) {
        return _out;
    }

    if (_running) {
        if (!_trigger && !_globals->sustain_pedal) {
            stop();
        }
        else if (_stage == _key_up) {
            if (!_patch->loop) {
                return _out;
            }
            set(0);
        }
        if (_stage < 0) {
            return _out;
        }
    }

    bool done = false;

    _level += _step;
    if ((_level >= _goal && _step > 0) || (_level <= _goal && _step < 0)) {
        _level = _goal;
        done = true;
    }

    int i;
    auto const &e = (*_egs)[_stage];

    switch (e->type) {
        case eg_exp:
        case eg_pitch:
            _out = _level;
            break;

        case eg_linear:
            i = (_level - eg_min) >> 10;
            if (i > 0) {
                _out = eg_max - (_globals->t.log(i) << 6);
            } else {
                _out = eg_min;
            }
            break;

        case eg_delay:
            // leave alone
            break;
    }

    if (done) {
        set(_stage+1);
    }

    return _out;
}
