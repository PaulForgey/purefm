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

// from this level, all things are normalized to 24 bit ranges
class op {
    public:
        op(globals const *, int const *sum, int const *mod, int *out);
        virtual ~op();

        void set_sum(int const *s) { _sum = s; }
        void set_mod(int const *m) { _mod = m; }
        void set_out(int *o) { _out = o; }

        void start(op_patch const *patch, int key, int middle_c, int velocity);
        void update(op_patch const *patch);
        void step(int lfo, int pitch);

    private:
        globals const *_globals;
        op_patch const *_patch;
        int const *_sum;
        int const *_mod;
        int *_out;
        sine_oscillator _osc;
        envelope _env;
        int _level;
};

#endif /* op_hpp */
