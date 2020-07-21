//
//  oscillator.cpp
//  purefm
//
//  Created by Paul Forgey on 5/1/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#include "oscillator.hpp"
#include "globals.hpp"

oscillator::oscillator(tables const &t) : _tables(t) {
    _phase = 0;
    _out = 0;
}

oscillator::~oscillator() {
}

