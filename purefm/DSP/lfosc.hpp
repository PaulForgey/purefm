//
//  lfosc.hpp
//  purefm
//
//  Created by Paul Forgey on 5/1/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#ifndef lfosc_hpp
#define lfosc_hpp

#include "oscillator.hpp"
#include "env.hpp"
#include "globals.hpp"

class lfo {
    public:
        lfo(globals const *);
        virtual ~lfo();

        void start(lfo_patch const *patch, int velocity);
        int step();
        void update(lfo_patch const *patch);
        eg_status const *get_status() const { return _env.get_status(); }

    private:
        globals const *_globals;
        lfo_patch const *_patch;
        oscillator _osc;
        envelope _env;
        int _frequency;
};

#endif /* lfosc_hpp */
