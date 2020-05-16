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

    voice *v = _voices[channel];
    if (!_patch->mono) {
        int n = _round++;
        // always refer to a voice already playing this note, otherwise
        // round robin allocate one
        for (int i = 0; i < 16; ++i) {
            v = _voices[(i+n) & 0xf];
            if (v->get_key() == key) {
                break;
            }
        }
    }
    _globals->status->voice = v->get_status();
    v->start(_patch, key, velocity);
}

int
engine::step() {
    auto &&mod = _globals->mod_wheel;
    if (mod < _expr) {
        ++mod;
    }
    else if (mod > _expr) {
        --mod;
    }

    int out = 0;
    for (auto && v : _voices) {
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

    case 0xb0: // control
        switch(msg[1]) {
            case 1: // modulation wheel
                _expr = msg[2] << 5;
                break;

            case 64: // sustain pedal
                _globals->sustain_pedal = (msg[2] != 0);
                break;
        }
        break;
        
    case 0xe0: // pitch bend
        _globals->pitch_bend = (((int)msg[1] + ((int)(msg[2]) << 7)) - 0x2000) << 2;
        break;
    }
}
