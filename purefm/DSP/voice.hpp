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

class voice {
    public:
        voice(globals const *);
        virtual ~voice();

        // out of band global parameters
        void update(patch const *);

        // key up indicated with 0 velocity
        void start(patch const *, int key, int velocity);
        int step();
        void pressure(int pressure);

        int get_key() const { return _key; }
        bool triggered() const { return _velocity != 0; }
        voice_status const *get_status() const { return &_status; }

    private:
        int highest_key() const;

    private:
        algo _algo;
        lfo _lfo;
        int _lfo_output;
        globals const *_globals;
        patch const *_patch;
        envelope _pitch_env;
        int _pitch;
        eg_stage _freq_eg;
        unsigned _counter;
        int _key;
        int _velocity;
        unsigned char _keys[16];
        int _output[16];
        voice_status _status;
        int _pressure; // smoothed value to use
        int _pressure_in; // current value
};

#endif /* voice_hpp */
