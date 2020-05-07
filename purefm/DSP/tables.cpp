//
//  DSPTables.cpp
//  purefm
//
//  Created by Paul Forgey on 4/15/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#include "tables.hpp"
#include <cmath>

void
tables::init(double sampleRate)
{
    int n;

    // 14 bits around the quarter arc for
    // 16 bits around the sine wave with
    // 16 bits of output per half for
    // 17 bits total out output
    for (n = 0; n < 0x4000; ++n) {
        // use odd samples for an even amount per quandrant
        double x = (double)n + 0.5;

        // logsin of quarter arc
        double y = std::sin(x / (double)0x8000 * M_PI);
        y = -std::log2(y);
        _logsin[n] = (int)std::round(y * (double)0x4000);

        // log complementing each exp
        x = x / (double)0x4000;
        y = -std::log2(x);
        _log[n] = (int)std::round(y * (double)0x4000);

        // exp complementing each log or logsin
        y = std::exp2(x);
        _exp[n ^ 0x3fff] = (int)std::round(y * (double)0x8000);
    }

    double const hz = middleC * (65536.0 / sampleRate);

    for (n = 0; n < 0x1000; ++n) {
        double y = hz * std::exp2((double)n / 4096.0);
        _notes[n] = (long)std::round(y * 65536.0);
    }

    for (n = 0; n < 12; ++n) {
        _scale[n] = (int)std::round(4096.0 * (double(n) / 12.0));
    }
}

// global, stateless utility conversions

int
tables::duration_param(int v)
{
    v = 0x80 - v;

    if (v > 0x2c) {
        double e = std::exp2((double)v * (16.0 / 128.0));
        v = (int)std::round(e);
    }

    return v;
}

int
tables::level_param(int v)
{
    // 24 bit range (lower 6 bits are dropped by the engine)
    // maximum output 0xfe0000
    // (0x1000000 - 0xfe0000) >> 6 = 0x800, -0.75db attenuation

    // XXX have this actually even lower allowing headroom
    return (v - 64) << 17;
}

int
tables::pitch_param(int value, int scale)
{
    // value is centered at 64.
    value -= 64;

    // at scale 7, range is effectivly one midi note per value increment
    value = (value * 341) + (value / 3);
    value >>= scale;

    return value << 8; // high 16 bits of 24 bit value
}
