//
//  EnvelopeStage.m
//  purefm
//
//  Created by Paul Forgey on 4/13/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "EnvelopeStage.h"
#import "Operator.h"
#import "globals.hpp"
#import "tables.hpp"

#include <memory>

@implementation EnvelopeStage {
    eg_ptr _eg;     // actual engine parameters
    int _level;     // in UI/MIDI terms
}

// MARK: patch

- (eg_ptr const &)eg {
    return _eg;
}

// MARK: init / coder

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:self.duration forKey:@"duration"];
    [coder encodeInt:self.level forKey:@"level"];
    [coder encodeInt:self.linearity forKey:@"linearity"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    _eg = std::make_shared<eg>();

    self.duration = [coder decodeIntForKey:@"duration"];
    self.level = [coder decodeIntForKey:@"level"];
    self.linearity = (EnvelopeStageLinearity)[coder decodeIntForKey:@"linearity"];

    return self;
}

- (id)init {
    self = [super init];
    _eg = std::make_shared<eg>();

    self.duration = 0;
    self.level = 0;
    self.linearity = kLinearity_Exp;
    
    return self;
}

-(id)copyWithZone:(NSZone *)zone {
    EnvelopeStage *es = [[EnvelopeStage allocWithZone:zone] init];
    es.duration = self.duration;
    es.level = self.level;
    es.linearity = self.linearity;

    return es;
}

// MARK: properties

- (void)setLevel:(int)level {
    _level = level;
    [self setPatchLevel:(tables::level_param(level))];
}
- (int)level {
    return _level;
}

- (void)setPatchLevel:(int)level {
    _eg->goal = level;
}

- (void)setDuration:(int)duration {
    _eg->rate = duration;
}
- (int)duration {
    return _eg->rate;
}

- (void)setLinearity:(EnvelopeStageLinearity)linearity {
    switch (linearity) {
    case kLinearity_Exp:
        _eg->type = eg_exp;
        break;
    case kLinearity_Delay:
        _eg->type = eg_delay;
        break;
    case kLinearity_Pitch:
        _eg->type = eg_pitch;
        break;
    case kLinearity_Linear:
        _eg->type = eg_linear;
        break;
    case kLinearity_Attack:
        _eg->type = eg_attack;
    }
}

- (EnvelopeStageLinearity)linearity {
    switch (_eg->type) {
    case eg_exp:
        return kLinearity_Exp;
    case eg_linear:
        return kLinearity_Linear;
    case eg_attack:
        return kLinearity_Attack;
    case eg_pitch:
        return kLinearity_Pitch;
    case eg_delay:
        return kLinearity_Delay;
    }
    return kLinearity_Exp;
}

- (BOOL)validateDuration:(id *)ioValue error:(NSError **)outError {
    [Operator clampMIDIValue:ioValue];
    return YES;
}

- (BOOL)validateLevel:(id *)ioValue error:(NSError **)outError {
    [Operator clampMIDIValue:ioValue];
    return YES;
}

@end

// MARK: PitchStage

@implementation PitchStage {
    int _level;
}

// MARK: init / coder

- (id)init {
    self = [super init];
    self.linearity = kLinearity_Pitch;
    self.level = 64;
    return self;
}

// MARK: properties

- (void)setDelay:(BOOL)delay {
    if (delay) {
        self.linearity = kLinearity_Delay;
    } else {
        self.linearity = kLinearity_Pitch;
    }
}

- (BOOL)delay {
    return (self.linearity == kLinearity_Delay);
}

- (void)setLevel:(int)level {
    _level = level;
    [super setPatchLevel:(tables::pitch_param(level, 0))];
}
- (int)level {
    return _level;
}

@end
