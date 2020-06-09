//
//  engine.mm
//  purefm
//
//  Created by Paul Forgey on 4/29/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#include "engine.hpp"

#include <algorithm>

engine::engine(globals *g) {
    _globals = g;
    _now = 0ULL;
    for (auto &&v : _voices) {
        v = new voice(g);
    }
}

engine::~engine() {
    for (auto &&v : _voices) {
        delete v;
    }
}

void
engine::update() {
    _patch = _globals->patch.get();
    for (auto &&v : _voices) {
        v->update(_patch);
    }
}

void
engine::start(int channel, int key, int velocity) {
    if (_patch == nullptr) {
        return;
    }

    int v = 0; // voices are kept in a minheap by oldest use (unless mono)

    if (_patch->mono) {
        v = channel;
    } else {
        for (int i = 0; i < _poly; ++i) {
            if (_voices[i]->get_key() == key) {
                v = i;
                break;
            }
        }
    }

    voice *voice = _voices[v];
    _globals->status->voice = voice->get_status();
    voice->start(_patch, key, velocity);

    if (!_patch->mono) {
        // mark playing voice as currently now and fix it up in the minheap
        // now will overflow after 584 million years playing 1000 notes/sec
        voice->set_priority(++_now);
        int v0 = v;

        // work down first
        while (v < _poly) {
            int l = (v << 1) + 1;
            int r = l + 1;

            if (l >= _poly) {
                break;
            }
            if (r < _poly &&
                _voices[r]->get_priority() < _voices[l]->get_priority()) {
                // compare and potentially swap with lower of two branches
                l = r;
            }
            if (_voices[l]->get_priority() < _voices[v]->get_priority()) {
                // move down
                std::swap(_voices[l], _voices[v]);
                v = l;
            } else {
                break;
            }
        }

        if (v0 == v) {
            // no violations down, so move up
            for (;;) {
                int p = (v - 1) >> 1;

                if (p == v ||
                    _voices[p]->get_priority() < _voices[v]->get_priority()) {
                    break;
                }
                std::swap(_voices[p], _voices[v]);
                v = p;
            }
        }
    }
}

void
engine::pressure(int channel, int key, int pressure) {
    if (_patch == nullptr) {
        return;
    }
    if (_patch->mono) {
        auto &v = _voices[channel];
        if (key == -1 || v->get_key() == key) {
            v->pressure(pressure);
        }
    } else {
        for (auto &v : _voices) {
            if (key == -1 || v->get_key() == key) {
                v->pressure(pressure);
            }
        }
    }
}

int
engine::step() {
    auto &mod = _globals->mod_wheel;
    if (mod < _expr) {
        ++mod;
    }
    else if (mod > _expr) {
        --mod;
    }

    int out = 0;
    for (auto &&v : _voices) {
        out += v->step();
    }
    return out;
}

void
engine::midi(const unsigned char *msg) {
    unsigned char cmd = msg[0];
    unsigned char channel = cmd & 0x0f;
    switch(cmd & 0xf0) {
    case 0x80: // note off
        start(channel, msg[1], 0);
        break;

    case 0x90: // note on
        start(channel, msg[1], msg[2]);
        break;

    case 0xa0: // polyphonic pressure
        pressure(channel, msg[1], msg[2]);
        break;

    case 0xb0: // control
        switch(msg[1]) {
            case 64: // sustain pedal
                _globals->sustain_pedal = (msg[2] != 0);
                break;

            default:
                if (_patch != nullptr &&
                    (msg[1] == _patch->expr1 || msg[1] == _patch->expr2)) {
                    _expr = (int)msg[2] << 5;
                }
                break;
        }
        break;

    case 0xd0: // channel pressure
        pressure(channel, -1, msg[1]);
        break;
        
    case 0xe0: // pitch bend
        _globals->pitch_bend = (((int)msg[1] + ((int)(msg[2]) << 7)) - 0x2000) << 2;
        break;
    }
}
