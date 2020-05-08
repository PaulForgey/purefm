//
//  voice.hpp
//  purefm
//
//  Created by Paul Forgey on 4/30/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#ifndef voice_hpp
#define voice_hpp

#include "algo.hpp"
#include "env.hpp"
#include "lfosc.hpp"
#include "globals.hpp"
#include <utility>

class voice {
    public:
        voice(globals const *);
        virtual ~voice();

        // out of band global parameters
        void update(patch const *);

        // key up indicated with 0 velocity
        void start(patch const *, int key, int velocity);
        int step();

        int get_key() const { return _key; }

    private:
        algo _algo;
        lfo _lfo;
        int _lfo_output;
        globals const *_globals;
        patch const *_patch;
        envelope _pitch_env;
        int _pitch;
        unsigned _counter;
        int _key;
        bool _trigger;
};

#endif /* voice_hpp */
