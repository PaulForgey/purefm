//
//  algo.hpp
//  purefm
//
//  Created by Paul Forgey on 4/29/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#ifndef algo_hpp
#define algo_hpp

#include "op.hpp"
#include "env.hpp"
#include "globals.hpp"

class algo {
    public:
        algo(globals const *);
        virtual ~algo();

        // adjust the algorithm as such:
        // op [0,7] sums from sum, or zero if -1, and
        // modulates from mod, or zero if -1, and
        // if mod <= op, a feedback loop is assumed
        void set_op_node(int op, int sum, int mod);

        void update(patch const *);

        void start(patch const *, int key, int velocity);
        void step(int *output, int lfo, int pitch); // output is 16 elements
        eg_status const *get_eg_status(int i) const { return _ops[i]->get_status(); }

    private:
        globals const *_globals;
        patch const *_patch;
        fb_filter _fb;
        op *_ops[8];

};

#endif /* algo_hpp */
