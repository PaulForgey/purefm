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
#include <algorithm>

class eg_stage {
    public:
        eg_stage() {
            _level = eg_min;
            _goal = eg_min;
            _rate = 0;
        }
        virtual ~eg_stage() {}

        void set(int level, int goal, int rate) {
            _level = level;
            _goal = goal;

            rate = std::max(rate, 1);
            if (goal < level) {
                _rate = -rate;
            } else {
                _rate = rate;
            }
        }

        bool done() const { return _level == _goal; }
        int get_level() const { return _level; }

        int step(int count) {
            if (!done()) {
                _level += _rate * count;
                if (_rate < 0) {
                    _level = std::max(_goal, _level);
                } else {
                    _level = std::min(_goal, _level);
                }
            }
            return _level;
        }

    private:
        int _level, _goal, _rate;
};

class envelope {
    public:
        envelope(globals const *);
        virtual ~envelope();

        eg_status const *get_status() const { return &_status; }
        void update(env_patch const *, bool reset);
        void start(env_patch const *, int level_adj, int rate_adj, bool trigger);
        int step(int count, int bias);
        int out() const { return _out; }
        void init_at(int out) { _out = out; _level = out; }

        // for pitch envelope
        int pitch_bias(int lfo);
        int pitch_value(int value);
        int op_bias(int lfo, int pressure);

        bool idle() const { return _idle && _level == eg_min; }

    private:
        void run();
        void stop();
        void set(int at);

        int to_linear(int) const;
        int to_exp(int) const;

    private:
        int _level, _out;
        int _at;
        eg_type _type;
        eg_stage _stage;
        bool _trigger, _run, _idle;
        eg_vec const *_egs;
        int _key_up, _end;
        int _level_adj, _rate_adj;
        eg_status _status;

        env_patch const *_patch;
        globals const *_globals;
};

#endif /* env_hpp */
