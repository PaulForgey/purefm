//
//  globals.hpp
//  purefm-host
//
//  Created by Paul Forgey on 4/30/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#ifndef globals_h
#define globals_h

#include "tables.hpp"
#include "status.h"

#include <atomic>
#include <memory>
#include <utility>
#include <vector>

// model -> engine configuration

//
// safely swaps a pointer between the model and the engine, leaving the
// model's responsibility to free the pointer when it comes back.
// instances are owned by the model.
template<class T>
class ptr_msg {
    public:
        typedef std::shared_ptr<T> pointer;

    public:
        ptr_msg() : _fence(false) {}
        virtual ~ptr_msg() {}

        // producer: set the next message.
        // any prior set either missed or no longer in use will be released.
        // allocation calls happen from this side.
        void set(pointer const &next) {
            while (_fence.test_and_set());
            auto p = std::move(_free);
            _fence.clear();

            std::atomic_store(&_next, next);
            p.reset(); // do potential final release outside spin lock
        }

        // consumer: get the next or current message without allocation calls.
        // return a weak plain pointer, which will invalidate at next call to get().
        // (obviously) assumes single thread consumer.
        T const *get() const  {
            auto &&p = std::atomic_load_explicit(&_next, std::memory_order_relaxed);
            if (p != _used) {
                while (_fence.test_and_set());
                _free = std::move(_used);
                _used = std::move(p);
                _fence.clear();
            }

            return _used.get();
        }

    private:
        // next: potentially new value waiting for engine
        // used: currently used value by engine
        // free: instance to be released from model
        pointer _next;
        mutable pointer _used, _free; // "const"-ness includes get()
        mutable std::atomic_flag _fence;

};

typedef enum {
    eg_exp = 0,
    eg_linear,
    eg_attack,
    eg_delay,
    eg_pitch
} eg_type;

struct eg {
    eg_type type;
    int goal;
    int rate;
};
typedef std::shared_ptr<eg> eg_ptr;

typedef std::vector<eg_ptr const> eg_vec;
typedef ptr_msg< eg_vec > eg_vec_ptr;

struct env_patch {
    bool loop;
    int expr;
    int lfo;
    int bend;
    int scale;
    int key_up;

    eg_vec_ptr egs;
};
typedef ptr_msg< env_patch > env_patch_ptr;

const int scale_up = 0x01;
const int scale_exp = 0x02;

struct op_patch {
    int mod;
    int sum;
    bool enabled;
    int level;
    bool resync;
    int velocity;
    int rate_scale;
    int breakpoint;
    int key_scale_left;
    int key_scale_right;
    int scale_type_left;
    int scale_type_right;
    int frequency;
    bool fixed;

    env_patch_ptr env;
};

class function {
    public:
        function() {}
        virtual ~function() {}

        virtual int generate(tables const &, int phase) const =0;

        // the function has the same value per half
        // the oscillator will call generate() once per period and
        // return the negative value for the second half of the period
        virtual bool constant() const { return false; }
};
typedef ptr_msg<function> function_ptr;

struct lfo_patch {
    int frequency;
    bool resync;

    function_ptr wave;
    env_patch_ptr env;
};
typedef ptr_msg<lfo_patch> lfo_patch_ptr;

struct patch {
    int feedback;
    bool mono;
    int middle_c;
    int portamento;
    int tuning;

    op_patch const *ops[8];
    env_patch_ptr pitch_env;
    lfo_patch_ptr lfo;
};
typedef ptr_msg<patch> patch_ptr;

// global state
struct globals {
    tables t;

    // patch info
    patch_ptr patch;

    // returned engine state
    struct status *status;

    // running info
    int mod_wheel;
    int pitch_bend;
    bool sustain_pedal;

    // eg rate divider mask
    unsigned eg_mask;
};

#endif /* globals_h */
