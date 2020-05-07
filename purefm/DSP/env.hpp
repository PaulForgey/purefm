//
//  env.hpp
//  purefm
//
//  Created by Paul Forgey on 4/29/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#ifndef env_hpp
#define env_hpp

#include "globals.hpp"
#include <vector>

class envelope {
    public:
        envelope(globals const *);
        virtual ~envelope();

        void update(env_patch const *);
        void start(env_patch const *, int rate_adj, bool trigger);
        int step();

        // for pitch envelope
        void start_with(env_patch const *, int level, bool trigger);
        int pitch_value(int value, int lfo);
        int op_value(int value, int lfo);

    private:
        void set(int stage);
        void start(int rate_adj);
        void stop();

    private:
        int _level, _out;
        int _step, _goal;
        int _rate_adj;
        int _stage, _key_up;
        bool _trigger, _running;
        env_patch const *_patch;
        eg_vec const *_egs;
        globals const *_globals;
};

#endif /* env_hpp */
