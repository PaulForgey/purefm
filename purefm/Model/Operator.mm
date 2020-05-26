//
//  Operator.m
//  purefm
//
//  Created by Paul Forgey on 4/8/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "Operator.h"
#import "Envelope.h"
#import "tables.hpp"
#import "globals.hpp"

#include <memory>

@implementation Operator {
    int _number;
    Envelope *_envelope;
    int _level;
    int _frequency;
    int _detune;

    op_patch _patch;
    struct eg_status const *_status;
}

@synthesize status = _status;

// MARK: init / coder

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:_number forKey:@"number"];
    [coder encodeObject:_envelope forKey:@"envelope"];
    [coder encodeInt:self.sum forKey:@"sum"];
    [coder encodeInt:self.mod forKey:@"mod"];
    [coder encodeBool:self.enabled forKey:@"enabled"];
    [coder encodeInt:self.level forKey:@"level"];
    [coder encodeBool:self.resync forKey:@"resync"];
    [coder encodeInt:self.velocity forKey:@"velocity"];
    [coder encodeInt:self.rateScale forKey:@"rateScale"];
    [coder encodeInt:self.breakpoint forKey:@"breakpoint"];
    [coder encodeInt:self.keyScaleLeft forKey:@"keyScaleLeft"];
    [coder encodeInt:self.keyScaleRight forKey:@"keyScaleRight"];
    [coder encodeInt:self.scaleTypeLeft forKey:@"scaleTypeLeft"];
    [coder encodeInt:self.scaleTypeRight forKey:@"scaleTypeRight"];
    [coder encodeInt:self.frequency forKey:@"frequency"];
    [coder encodeInt:self.detune forKey:@"detune"];
    [coder encodeBool:self.fixed forKey:@"fixed"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];

    _number = [coder decodeIntForKey:@"number"];
    _envelope = [coder decodeObjectForKey:@"envelope"];

    _patch.env.set([_envelope patch]);

    self.sum = [coder decodeIntForKey:@"sum"];
    self.mod = [coder decodeIntForKey:@"mod"];
    self.enabled = [coder decodeBoolForKey:@"enabled"];
    self.level = [coder decodeIntForKey:@"level"];
    self.resync = [coder decodeBoolForKey:@"resync"];
    self.velocity = [coder decodeIntForKey:@"velocity"];
    self.rateScale = [coder decodeIntForKey:@"rateScale"];
    self.breakpoint = [coder decodeIntForKey:@"breakpoint"];
    self.keyScaleLeft = [coder decodeIntForKey:@"keyScaleLeft"];
    self.keyScaleRight = [coder decodeIntForKey:@"keyScaleRight"];
    self.scaleTypeLeft = (ScaleType)[coder decodeIntForKey:@"scaleTypeLeft"];
    self.scaleTypeRight = (ScaleType)[coder decodeIntForKey:@"scaleTypeRight"];
    self.frequency = [coder decodeIntForKey:@"frequency"];
    self.detune = [coder decodeIntForKey:@"detune"];
    self.fixed = [coder decodeBoolForKey:@"fixed"];

    return self;
}

+ (Operator *)operatorWithNumber:(int)n {
    Operator *o = [[Operator alloc] init];
    o->_number = n;
    o->_envelope = [[Envelope alloc] initDefaultOp];
    o->_patch.env.set([o->_envelope patch]);

    // preset loading will overwrite these later
    o.sum = -1;
    o.mod = -1;
    o.enabled = YES;
    o.breakpoint = 60;
    o.resync = NO;
    o.level = 0;
    o.velocity = 0;
    o.frequency = 0;

    return o;
}

// MARK: patch

- (op_patch const *)patch {
    return &_patch;
}

// MARK: status

- (void)updateStatus {
    if (_envelope != nil) {
        [_envelope updateStatus];
    }
}

- (void)setStatus:(const struct eg_status *)status {
    _status = status;
    if (_envelope != nil) {
        _envelope.status = status;
    }
}

// MARK: properties

- (void)setSum:(int)sum {
    [self willChangeValueForKey:@"algoChange"];
    if (sum > 7 || sum < 0) {
        _patch.sum = -1;
    } else {
        _patch.sum = sum;
    }
    [self didChangeValueForKey:@"algoChange"];
}
- (int)sum {
    return _patch.sum;
}

- (void)setMod:(int)mod {
    [self willChangeValueForKey:@"algoChange"];
    if (mod > 7 || mod < 0) {
        _patch.mod = -1;
    } else {
        _patch.mod = mod;
    }
    [self didChangeValueForKey:@"algoChange"];
}
- (int)mod {
    return _patch.mod;
}

- (void)setEnabled:(BOOL)enabled {
    _patch.enabled = enabled;
}
- (BOOL)enabled {
    return _patch.enabled;
}

- (void)setLevel:(int)level {
    _level = level;
    _patch.level = tables::level_param(level);
}
- (int)level {
    return _level;
}

- (void)setResync:(BOOL)resync {
    _patch.resync = (bool)resync;
}
- (BOOL)resync {
    return (BOOL)(_patch.resync);
}

- (void)setVelocity:(int)velocity {
    _patch.velocity = velocity;
}
- (int)velocity {
    return _patch.velocity;
}

- (void)setRateScale:(int)rateScale {
    _patch.rate_scale = rateScale;
}
- (int)rateScale {
    return _patch.rate_scale;
}

- (void)setBreakpoint:(int)breakpoint {
    _patch.breakpoint = breakpoint;
}
- (int)breakpoint {
    return _patch.breakpoint;
}

- (void)setScaleTypeLeft:(ScaleType)scaleTypeLeft {
    _patch.scale_type_left = (int)scaleTypeLeft;
}
- (ScaleType)scaleTypeLeft {
    return (ScaleType)_patch.scale_type_left;
}

- (void)setScaleTypeRight:(ScaleType)scaleTypeRight {
    _patch.scale_type_right = (int)scaleTypeRight;
}
- (ScaleType)scaleTypeRight {
    return (ScaleType)_patch.scale_type_right;
}

- (void)setKeyScaleLeft:(int)keyScaleLeft {
    _patch.key_scale_left = keyScaleLeft;
}
- (int)keyScaleLeft {
    return _patch.key_scale_left;
}

- (void)setKeyScaleRight:(int)keyScaleRight {
    _patch.key_scale_right = keyScaleRight;
}
- (int)keyScaleRight {
    return _patch.key_scale_right;
}

- (void)setFrequency:(int)frequency {
    _frequency = frequency;
    _patch.frequency = frequency + _detune;
}
- (int)frequency {
    return _frequency;
}

- (void)setDetune:(int)detune {
    _detune = detune;
    _patch.frequency = _frequency + detune;
}
- (int)detune {
    return _detune;
}

- (void)setFixed:(BOOL)fixed {
    _patch.fixed = (bool)fixed;
}
- (BOOL)fixed {
    return (BOOL)(_patch.fixed);
}

+ (void)clampMIDIValue:(id *)ioValue {
    int v = [*ioValue intValue];
    if (v < 0) {
        *ioValue = @(0);
    }
    if (v > 127) {
        *ioValue = @(127);
    }
}

+ (void)clampFrequencyValue:(id *)ioValue {
    int v = [*ioValue intValue];
    // 16 bit range (if transposed to unsigned domain),
    // which at 4096 pitch units per octave is also a 16 octave range.
    // "middle" C (0) is actually -2 octaves,
    // so range is from -40960 (-0xA000) to 24575 (0x5fff)
    if (v < -40960) {
        *ioValue = @(-40960);
    }
    if (v > 24575) {
        *ioValue = @(24575);
    }
}

- (BOOL)validateLevel:(id *)ioValue error:(NSError **)outError {
    [Operator clampMIDIValue:ioValue];
    return YES;
}

- (BOOL)validateVelocity:(id *)ioValue error:(NSError **)outError {
    [Envelope clampScaleValue:ioValue max:7];
    return YES;
}

- (BOOL)validateRateScale:(id *)ioValue error:(NSError **)outError {
    [Operator clampMIDIValue:ioValue];
    return YES;
}

- (BOOL)validateBreakpoint:(id *)ioValue error:(NSError **)outError {
    [Operator clampMIDIValue:ioValue];
    return YES;
}

- (BOOL)validateKeyScaleLeft:(id *)ioValue error:(NSError **)outError {
    [Operator clampMIDIValue:ioValue];
    return YES;
}

- (BOOL)validateKeyScaleRight:(id *)ioValue error:(NSError **)outError {
    [Operator clampMIDIValue:ioValue];
    return YES;
}

- (BOOL)validateFrequency:(id *)ioValue error:(NSError **)outError {
    [Operator clampFrequencyValue:ioValue];
    return YES;
}


@end

