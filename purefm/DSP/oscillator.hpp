//
//  oscillator.hpp
//  purefm
//
//  Created by Paul Forgey on 4/28/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#ifndef oscillator_hpp
#define oscillator_hpp

#include "tables.hpp"
#include "globals.hpp"

#include <cstdlib>

class sine : public function {
    public:
        int generate(tables const &t, int phase) const {
            if ((phase & 0x4000) != 0) {
                phase = (phase & 0x3fff) ^ 0x3fff;
            }
            return t.logsin(phase);
        }
};

class triangle : public function {
    public:
        int generate(tables const &t, int phase) const {
            if ((phase & 0x4000) != 0) {
                phase = (phase & 0x3fff) ^ 0x3fff;
            }
            return t.log(phase);
        }
};

class square : public function {
    public:
        int generate(tables const &, int phase) const { return 0; }
        bool constant() const { return true; }
};

class sawup : public function {
    public:
        int generate(tables const &t, int phase) const {
            return t.log(phase >> 1);
        }
};

class sawdown : public sawup {
    public:
        int generate(tables const &t, int phase) const {
            return sawup::generate(t, phase ^ 0x7fff);
        }
};

class noise : public function {
    public:
        int generate(tables const &, int phase) const {
            return (std::rand() & 0xf) << 14 | (std::rand() & 0x3fff);
        }
        bool constant() const { return true; }
};

class oscillator {
    public:
        oscillator();
        virtual ~oscillator();

        void reset() { _phase = 0; }

        template< class T >
        int step(T const &f, tables const &t, long pitch, int offset, bool *neg) {
            long prev = (_phase & 0xffffffff);
            _phase += pitch;
            long next = (_phase & 0xffffffff);

            long phase = (next + (offset << 8)) >> 16;
            if ((phase & 0x8000) != 0) {
                *neg = true;
                phase ^= 0x7fff;
            } else {
                *neg = false;
            }

            // only stroke constant() functions one per period
            if (!f.constant() || (next < prev)) {
                _out = f.generate(t, phase & 0x7fff);
            }

            return _out;
        }

    private:
        long _phase;
        int _out;
};

// convenience sine oscillator for the operators
class sine_oscillator : public oscillator {
    public:
        sine_oscillator(tables const &t) : _tables(t) {}
        virtual ~sine_oscillator() {}

        int step(long pitch, int offset, bool *neg) {
            return oscillator::step(_sine, _tables, pitch, offset, neg);
        }

    private:
        sine _sine;
        tables const &_tables;
};

#endif /* oscillator_hpp */
