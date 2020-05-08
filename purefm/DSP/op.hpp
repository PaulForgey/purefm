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
        }
        virtual ~fb_filter() {}

        void set_input(int const *in) { _in = in; }

        int operator()() {
            _acc += *_in - _buf[_ptr];
            _buf[_ptr] = *_in;
            _ptr = (_ptr + 1) & 3;
            return _acc >> 2;
        }

    private:
        int const *_in;
        int _buf[4];
        int _ptr, _acc;
};

// from this level, all things are normalized to 24 bit ranges
class op {
    public:
        op(globals const *, int const *sum, int const *mod, int *out, int *out2);
        virtual ~op();

        void set_sum(int const *s) { _sum = s; }
        void set_mod(int const *m) { _mod = m; }

        void start(op_patch const *patch, int key, int middle_c, int velocity);
        void update(op_patch const *patch);
        void step(int lfo, int pitch);
        op_status const *get_status() const { return &_status; }

    private:
        globals const *_globals;
        op_patch const *_patch;
        int const *_sum;
        int const *_mod;
        int *_out, *_out2;
        sine_oscillator _osc;
        envelope _env;
        int _level;
        op_status _status;
};

#endif /* op_hpp */
