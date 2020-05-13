//
//  op.hpp
//  purefm
//
//  Created by Paul Forgey on 4/29/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#ifndef op_hpp
#define op_hpp

#include "oscillator.hpp"
#include "env.hpp"
#include "globals.hpp"

#include <algorithm>

class fb_filter {
    public:
        fb_filter() {
            std::fill_n(_buf, 4, 0);
            _ptr = 0;
            _acc = 0;
            _in = 0;
            _out = 0;
        }
        virtual ~fb_filter() {}

        void input(int in) { _in = in; }
        int const *output() const { return &_out; }

        void step(int scale) {
            _acc += _in - _buf[_ptr];
            _buf[_ptr] = _in;
            _ptr = (_ptr + 1) & 3;
            _out = (_acc * scale) >> 9; // 7 bit scale + /4 average
        }

    private:
        int _in, _out;
        int _buf[4];
        int _ptr, _acc;
};

// from this level, all things are normalized to 24 bit ranges
class op {
    public:
        op(globals const *);
        virtual ~op();

        void set_sum(op const *s);
        void set_mod(op const *m);
        void set_fb_input(fb_filter const *);
        void set_fb_output(fb_filter *);

        void start(op_patch const *patch, int key, int velocity);
        void update(op_patch const *patch);
        int step(int lfo, int pitch);
        eg_status const *get_status() const { return _env.get_status(); }

    private:
        globals const *_globals;
        op_patch const *_patch;
        int const *_sum;
        int const *_mod;
        fb_filter *_fb;
        int _out;
        sine_oscillator _osc;
        envelope _env;

        int const _zero = 0;
};

#endif /* op_hpp */
