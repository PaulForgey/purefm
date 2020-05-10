//
//  State.m
//  purefm
//
//  Created by Paul Forgey on 4/28/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "State.h"
#import "purefmAudioUnit.h"
#import "globals.hpp"

#include <memory>

@implementation State {
    NSArray< Operator * > *_operators;
    Envelope *_pitchEnvelope;
    LFO *_lfo;
    int _portamento;

    patch_ptr::pointer _patch;
    AUParameterTree *_parameterTree;
}

@synthesize parameterTree = _parameterTree;

// MARK: init / coder

- (id)init {
    self = [super init];

    _patch = std::make_shared<patch>();
    [self connect];

    self.feedback = 0;
    self.mono = NO;
    self.middleC = 60;
    self.portamento = 0;

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_operators forKey:@"operators"];
    [coder encodeObject:_pitchEnvelope forKey:@"pitchEnvelope"];
    [coder encodeObject:_lfo forKey:@"lfo"];

    [coder encodeInt:self.feedback forKey:@"feedback"];
    [coder encodeBool:self.mono forKey:@"mono"];
    [coder encodeInt:self.middleC forKey:@"middleC"];
    [coder encodeInt:self.portamento forKey:@"portamento"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    _patch = std::make_shared<patch>();

    _operators = [coder decodeObjectForKey:@"operators"];
    _pitchEnvelope = [coder decodeObjectForKey:@"pitchEnvelope"];
    _lfo = [coder decodeObjectForKey:@"lfo"];

    [self connect];

    self.feedback = [coder decodeIntForKey:@"feedback"];
    self.mono = [coder decodeBoolForKey:@"mono"];
    self.middleC = [coder decodeIntForKey:@"middleC"];
    self.portamento = [coder decodeIntForKey:@"portamento"];

    return self;
}

// MARK: patch

- (void)connect {
    int i;
    for (i = 0; i < 8; ++i) {
        _patch->ops[i] = [self.operators[i] patch];
    }
    if (_lfo != nil) {
        _patch->lfo.set([_lfo patch]);
    }
    if (_pitchEnvelope != nil) {
        _patch->pitch_env.set([_pitchEnvelope patch]);
    }
}
- (patch_ptr::pointer const &)patch {
    return _patch;
}

// MARK: status

- (void)updateStatus {
    struct voice_status const *s;
    if (_status == NULL) {
        return;
    }
    s = _status->voice;
    if (s == NULL) {
        return;
    }
    if (_lfo != nil) {
        _lfo.status = s->lfo;
        [_lfo updateStatus];
    }
    if (_pitchEnvelope != nil) {
        _pitchEnvelope.status = s->pitch;
        [_pitchEnvelope updateStatus];
    }
    if (_operators != nil) {
        int i;
        for (i = 0; i < 8; i++) {
            _operators[i].status = s->ops[i];
            [_operators[i] updateStatus];
        }
    }
}

// MARK: AUParameters

- (void)setParameterTree:(AUParameterTree *)parameterTree {
    _parameterTree = parameterTree;
    self.lfo.parameterTree = parameterTree;

    // refersh current values into parameter tree
    [self setFeedback:self.feedback];
    [self setMono:self.mono];
    [self setMiddleC:self.middleC];
}

- (void)didChange:(NSString *)key {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self willChangeValueForKey:key];
        [self didChangeValueForKey:key];
    });
}

- (void)setParameter:(AUParameter *)parameter value:(AUValue)value {
    switch (parameter.address) {
        case kParam_Feedback:
            _patch->feedback = (int)value;
            [self didChange:@"feedback"];
            break;

        case kParam_Mono:
            _patch->mono = (bool)value;
            [self didChange:@"mono"];
            break;

        case kParam_MiddleC:
            _patch->middle_c = (int)value;
            [self didChange:@"middleC"];
            break;

        case kParam_Portamento:
            [self updatePortamento:(int)value];
            [self didChange:@"portamento"];
            break;

        case kParam_LFOOutput:
        case kParam_LFOFreq:
        case kParam_LFOWave:
            [self.lfo setParameter:parameter value:value];
            break;

    }
}

// MARK: properties

- (void)setFeedback:(int)feedback {
    _patch->feedback = feedback;
    [[_parameterTree parameterWithAddress:kParam_Feedback] setValue:(AUValue)feedback];
}
- (int)feedback {
    return _patch->feedback;
}

- (void)setMono:(BOOL)mono {
    _patch->mono = (bool)mono;
    [[_parameterTree parameterWithAddress:kParam_Mono] setValue:(AUValue)mono];
}
- (BOOL)mono {
    return (BOOL)(_patch->mono);
}

- (void)setMiddleC:(int)middleC {
    _patch->middle_c = middleC;
    [[_parameterTree parameterWithAddress:kParam_MiddleC] setValue:(AUValue)middleC];
}
- (int)middleC {
    return _patch->middle_c;
}

- (void)setPortamento:(int)portamento {
    [self updatePortamento:portamento];
    [[_parameterTree parameterWithAddress:kParam_Portamento] setValue:(AUValue)portamento];
}
- (int)portamento {
    return _portamento;
}

- (NSArray< Operator * > *)operators {
    if (_operators == nil) {
        _operators = @[
            [Operator operatorWithNumber:1],
            [Operator operatorWithNumber:2],
            [Operator operatorWithNumber:3],
            [Operator operatorWithNumber:4],
            [Operator operatorWithNumber:5],
            [Operator operatorWithNumber:6],
            [Operator operatorWithNumber:7],
            [Operator operatorWithNumber:8],
        ];
        int i;
        for (i = 0; i < 7; i++) {
            _operators[i].sum = i+1;
            _operators[i].mod = -1;
        }
        _operators[7].sum = -1;
        _operators[7].mod = 7;
        _operators[0].level = 127;
        [self connect];
        [self updateStatus];
    }
    return _operators;
}

- (Envelope *)pitchEnvelope {
    if (_pitchEnvelope == nil) {
        _pitchEnvelope = [[Envelope alloc] init];
        [self connect];
    }
    return _pitchEnvelope;
}

- (LFO *)lfo {
    if (_lfo == nil) {
        _lfo = [[LFO alloc] init];
        [self connect];
        [self updateStatus];
    }
    return _lfo;
}

- (BOOL)validateMiddleC:(id *)ioValue error:(NSError **)outError {
    [Operator clampMIDIValue:ioValue];
    return YES;
}

- (BOOL)validateFeedback:(id *)ioValue error:(NSError **)outError {
    [Operator clampMIDIValue:ioValue];
    return YES;
}

- (BOOL)validatePortamento:(id *)ioValue error:(NSError **)outError {
    [Operator clampMIDIValue:ioValue];
    return YES;
}

- (void)updatePortamento:(int)value {
    _portamento = value;
    _patch->portamento = tables::duration_param(value);
}

@end
