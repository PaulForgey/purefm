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
    _rate_adj = 0;
    _level_adj = 0;
    _at = 0;
    _key_up = -1;
    _end = 0;
    _patch = nullptr;
    _egs = nullptr;
    _trigger = false;
    _run = false;
    _idle = true;
    _type = eg_exp;
    _status.output = (eg_min >> 12);
    _status.stage = 0;
}

envelope::~envelope() {
}

int
envelope::pitch_value(int value) {
    if (_patch == nullptr) {
        return value;
    }
    return (value >> (8 + _patch->scale)) +
            (_globals->pitch_bend >> _patch->bend);
}

int
envelope::pitch_bias(int lfo) {
    if (_patch == nullptr) {
        return 0;
    }
    return (lfo >> (8 + _patch->lfo)) << 8;
}

int
envelope::op_bias(int lfo) {
    if (_patch == nullptr) {
        return 0;
    }
    // mod_wheel value is shifted over 5
    return ((lfo >> (8 + _patch->lfo)) << 8) +
           ((_globals->mod_wheel >> (5 + _patch->expr)) << 16);
}

void
envelope::update(env_patch const *patch) {
    _patch = patch;
    _key_up = 0;
    _end = 0;
    if (patch != nullptr) {
        _egs = patch->egs.get();
        if (_egs != nullptr) {
            int const key_up = _patch->key_up;
            _end = (int)_egs->size();
            if (key_up >= 0 && key_up < _end) {
                _key_up = key_up;
            } else {
                _key_up = -1;
            }
        }
    } else {
        _egs = nullptr;
    }
}

void
envelope::start(env_patch const *patch, int level_adj, int rate_adj, bool trigger) {
    update(patch);
    if (_egs == nullptr || _egs->empty()) {
        return;
    }

    _trigger = trigger;
    if (trigger) {
        _rate_adj = rate_adj;
        _level_adj = level_adj;
        run();
    } else if (!_globals->sustain_pedal) {
        stop();
    }
}

void
envelope::run() {
    _run = true;
    set(0);

}

void
envelope::stop() {
    _run = false;
    if (_key_up >= 0) {
        set(_key_up);
    }
}

void
envelope::set(int at) {
    _idle = false;
    if (_run && (at == _key_up || at == _end)) {
        if (_patch->loop && _at > 0) {
            at = 0;
        } else {
            _idle = true;
            return;
        }
    }
    _status.stage = at;
    if (at < 0 || at >= _end) {
        _idle = true;
        return;
    }
    _at = at;
    auto const &eg = (*_egs)[at];

    int goal = eg->goal + _level_adj;
    if (goal < eg_min) {
        goal = eg_min;
    } else if (goal > eg_max) {
        goal = eg_max;
    }

    int rate = eg->rate - _rate_adj;
    if (rate < 0) {
        rate = 0;
    } else if (rate > 0x7f) {
        rate = 0x7f;
    }
    rate = _globals->t.duration_param(rate);

    _type = eg->type;

    switch (eg->type) {
    case eg_linear:
        // if transitioning to a linear output, translate its starting state
        _level = eg_min + (_globals->t.exp((eg_max+1 - _out) >> 6) << 8);
        break;

    case eg_delay:
        // delay immediately outputs its goal for the count of eg_min->eg_max
        _level = eg_min;
        _out = goal;
        goal = eg_max;
        break;

    case eg_attack:
        // revert to eg_exp if not actually attacking
        if (_level >= goal) {
            _type = eg_exp;
        } else {
            // DX-7 style behavior with eg_attack: start at minimum level
            _level = std::max(_level, -0x14c000);
        }
        break;

    default:
        // otherwise whatever form of prior output is starting point
        _level = _out;
        break;
    }

    _stage.set(_level, goal, rate);
}

int
envelope::step(int count, int bias) {
    if (!_trigger && _run && !_globals->sustain_pedal) {
        stop();
    }

    if (_stage.done()) {
        if (!_idle) {
            set(_at+1);
        } else {
            int const out = _out + bias;
            _status.output = out >> 12;
            return out;
        }
    }

    if (_type == eg_attack) {
        int const m = ((17 << 20) - (_level - eg_min)) >> 20;
        _level = _stage.step(count * m);
    } else {
        _level = _stage.step(count);
    }
    int i;

    switch(_type) {
    case eg_linear:
        i = (_level - eg_min) >> 10;
        if (i > 0) {
            _out = eg_max - (_globals->t.log(i) << 6);
        } else {
            _out = eg_min;
        }
        break;

    case eg_delay:
        break;

    default:
        _out = _level;
        break;
    }

    int const out = _out + bias;
    _status.output = out >> 12;
    return out;
}
