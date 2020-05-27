//
//  engine.hpp
//  purefm
//
//  Created by Paul Forgey on 4/29/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#ifndef engine_hpp
#define engine_hpp

#include "algo.hpp"
#include "voice.hpp"
#include "globals.hpp"

class engine {
    public:
        engine(globals *);
        virtual ~engine();

        void update();
        void midi(unsigned char const *msg);
        int step();

    private:
        void start(int channel, int key, int velocity);
        void pressure(int channel, int key, int pressure);

    private:
        globals *_globals;
        voice *_voices[16];
        patch const *_patch;
        int _round; // rotating voice allocation
        int _expr; // expression input
};

#endif /* engine_hpp */
