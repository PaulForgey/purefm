//
//  LFO.m
//  purefm
//
//  Created by Paul Forgey on 4/26/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "LFO.h"
#import "Operator.h"
#import "purefmAudioUnit.h"

#include "globals.hpp"
#include "tables.hpp"
#include "oscillator.hpp"

#include <memory>

@implementation LFO {
    Envelope *_envelope;
    LFOWave _wave;
    lfo_patch_ptr::pointer _patch;
    AUParameterTree *_parameterTree;
    struct eg_status const *_status;
}

@synthesize parameterTree = _parameterTree;
@synthesize status = _status;

// MARK: init / coder

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_envelope forKey:@"envelope"];
    [coder encodeBool:self.resync forKey:@"resync"];
    [coder encodeInt:self.wave forKey:@"wave"];
    [coder encodeInt:self.frequency forKey:@"frequency"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    _patch = std::make_shared<lfo_patch>();

    _envelope = [coder decodeObjectForKey:@"envelope"];
    self.resync = [coder decodeBoolForKey:@"resync"];
    self.wave = (LFOWave)[coder decodeIntForKey:@"wave"];
    self.frequency = [coder decodeIntForKey:@"frequency"];

    [self connect];

    return self;
}

- (id)init {
    self = [super init];
    _patch = std::make_shared<lfo_patch>();
    _envelope = [[Envelope alloc] initDefaultOp];

    self.wave = kLFO_Sine;
    self.frequency = 0;
    self.resync = YES;

    [self connect];

    return self;
}

// MARK: patch

- (lfo_patch_ptr::pointer const &)patch {
    return _patch;
}

- (void)connect {
    _patch->env.set([_envelope patch]);
}

// MARK: status

- (void)updateStatus {
    if (_status != NULL && _envelope != nil) {
        _envelope.status = _status;
        [_envelope updateStatus];
    }
}

// MARK: AUParameters

- (void)setParameterTree:(AUParameterTree *)parameterTree {
    _parameterTree = parameterTree;

    // refresh current values into parameter tree
    [self setFrequency:self.frequency];
    [self setWave:self.wave];
}

- (void)didChange:(NSString *)key {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self willChangeValueForKey:key];
        [self didChangeValueForKey:key];
    });
}

- (void)setParameter:(AUParameter *)parameter value:(AUValue)value {
    switch (parameter.address) {
        case kParam_LFOFreq:
            _patch->frequency = value;
            [self didChange:@"frequency"];
            break;

        case kParam_LFOWave:
            [self updateWave:(LFOWave)value];
            [self didChange:@"wave"];
            break;
    }
}

// MARK: properties

- (Envelope *)envelope {
    if (_envelope == nil) {
        _envelope = [[Envelope alloc] init];
        [self connect];
    }
    return _envelope;
}

- (BOOL)validateFrequency:(inout id  _Nullable __autoreleasing *)ioValue error:(out NSError *__autoreleasing  _Nullable *)outError {
    [Operator clampFrequencyValue:ioValue];
    return YES;
}

- (void)setWave:(LFOWave)wave {
    [self updateWave:wave];
    [[_parameterTree parameterWithAddress:kParam_LFOWave] setValue:(AUValue)_wave];
}
- (LFOWave)wave {
    return _wave;
}

- (void)setResync:(BOOL)resync {
    _patch->resync = (bool)resync;
}
- (BOOL)resync {
    return (BOOL)(_patch->resync);
}

- (void)setFrequency:(int)frequency {
    _patch->frequency = frequency;
    [[_parameterTree parameterWithAddress:kParam_LFOFreq] setValue:(AUValue)frequency];
}
- (int)frequency {
    return _patch->frequency;
}

// MARK: non-kvo updates

- (void)updateWave:(LFOWave)wave {
    _wave = wave;

    function_ptr::pointer f;
    switch (wave) {
    case kLFO_Sine:
        f = std::make_shared<sine>();
        break;
    case kLFO_Triangle:
        f = std::make_shared<triangle>();
        break;
    case kLFO_Square:
        f = std::make_shared<square>();
        break;
    case kLFO_SawUp:
        f = std::make_shared<sawup>();
        break;
    case kLFO_SawDown:
        f = std::make_shared<sawdown>();
        break;
    case kLFO_Noise:
        f = std::make_shared<noise>();
        break;
    }
    _patch->wave.set(f);
}

@end
