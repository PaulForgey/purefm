//
//  Envelope.m
//  purefm
//
//  Created by Paul Forgey on 4/14/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "Envelope.h"
#import "env.hpp"
#import "globals.hpp"

#include <memory>

@implementation Envelope {
    NSMutableArray< EnvelopeStage * > *_stages;
    env_patch_ptr::pointer _patch;
    struct eg_status const *_status;
    int _playingStage;
    int _output;
}

@synthesize status = _status;
@synthesize playingStage = _playingStage;
@synthesize output = _output;

// MARK: init / coder

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_stages forKey:@"stages"];
    [coder encodeInteger:(NSInteger)self.keyUp forKey:@"keyUp"];
    [coder encodeBool:self.loop forKey:@"loop"];
    [coder encodeInt:self.expr forKey:@"expr"];
    [coder encodeInt:self.lfo forKey:@"lfo"];
    [coder encodeInt:self.bend forKey:@"bend"];
    [coder encodeInt:self.scale forKey:@"scale"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];

    [self initPatch];

    _stages = [coder decodeObjectForKey:@"stages"];
    self.loop = [coder decodeBoolForKey:@"loop"];
    self.expr = [coder decodeIntForKey:@"expr"];
    self.lfo = [coder decodeIntForKey:@"lfo"];
    self.bend = [coder decodeIntForKey:@"bend"];
    self.scale = [coder decodeIntForKey:@"scale"];

    [self connect:_stages];

    self.keyUp = (NSUInteger)[coder decodeIntegerForKey:@"keyUp"];

    return self;
}

- (id)init {
    self = [super init];
    _stages = [[NSMutableArray alloc] init];

    [self initPatch];

    self.loop = NO;
    self.expr = 0;
    self.lfo = 0;
    self.bend = 0;
    self.scale = 0;

    [self connect:_stages];

    self.keyUp = NSNotFound;

    return self;
}

- (id)initDefaultOp {
    self = [super init];
    [self initPatch];

    _stages = [[NSMutableArray alloc] init];
    EnvelopeStage *es = [[EnvelopeStage alloc] init];
    es.linearity = kLinearity_Linear;
    es.level = 127;
    [_stages addObject:es];

    es = [[EnvelopeStage alloc] init];
    es.linearity = kLinearity_Exp;
    [_stages addObject:es];

    [self connect:_stages];

    self.keyUp = 1;

    self.loop = NO;
    self.expr = 0;
    self.lfo = 0;
    self.bend = 0;
    self.scale = 0;

    return self;
}


- (id)copyWithZone:(NSZone *)zone {
    Envelope *e = [[Envelope allocWithZone:zone] init];
    [e replace:self];

    return e;
}

- (void)replace:(Envelope *)from {
    self.keyUp = from.keyUp;
    self.loop = from.loop;

    [self willChangeValueForKey:@"stages"];
    NSMutableArray< EnvelopeStage * > *stages = [[NSMutableArray alloc] init];
    EnvelopeStage *stage;
    for (stage in from.stages) {
        [stages addObject:[stage copy]];
    }
    [self connect:stages];
    [self didChangeValueForKey:@"stages"];
}

// MARK: patch

- (env_patch_ptr::pointer const &)patch {
    return _patch;
}

- (void)initPatch {
    _patch = std::make_shared<env_patch>();
    _patch->egs.set(std::make_shared<eg_vec>());
}

// stages param is to safely update before replacing ivar
- (void)connect:(NSMutableArray< EnvelopeStage * > *)stages {
    auto egs = std::make_shared<eg_vec>();
    EnvelopeStage *es;
    for (es in stages) {
        egs->push_back([es eg]);
    }
    _patch->egs.set(egs); // empty vec is allowed, just not nullptr
    _stages = stages;
}

// MARK: status

- (void)updateStatus {
    if (_status != NULL) {
        if (_status->stage != _playingStage) {
            [self willChangeValueForKey:@"playingStage"];
            _playingStage = _status->stage;
            [self didChangeValueForKey:@"playingStage"];
        }
        if (_status->output != _output) {
            [self willChangeValueForKey:@"output"];
            _output = _status->output;
            [self didChangeValueForKey:@"output"];
        }
    }
}

// MARK: properties

+ (void)clampScaleValue:(id *)ioValue max:(int)max{
    int v = [*ioValue intValue];
    if (v < 0) {
        *ioValue = @(0);
    }
    if (v > max) {
        *ioValue = @(max);
    }
}

- (NSArray< EnvelopeStage * > *)stages {
    return _stages;
}

- (void)setKeyUp:(NSUInteger)keyUp {
    _patch->key_up = (int)keyUp;
}
- (NSUInteger)keyUp {
    return _patch->key_up;
}

- (void)toggleKeyUp:(NSUInteger)index {
    if (index == (NSUInteger)(_patch->key_up)) {
        self.keyUp = NSNotFound;
    } else {
        self.keyUp = index;
    }
}

- (void)setLoop:(BOOL)loop {
    _patch->loop = (bool)loop;
}

- (BOOL)loop {
    return (BOOL)_patch->loop;
}

- (void)setExpr:(int)expr {
    _patch->expr = 7 - expr;
}
- (int)expr {
    return 7 - _patch->expr;
}

- (void)setLfo:(int)lfo {
    _patch->lfo = 16 - lfo;
}
- (int)lfo {
    return 16 - _patch->lfo;
}

- (void)setBend:(int)bend {
    _patch->bend = 7 - bend;
}
- (int)bend {
    return 7 - _patch->bend;
}

- (void)setScale:(int)scale {
    _patch->scale = 7 - scale;
}
- (int)scale {
    return 7 - _patch->scale;
}

- (BOOL)validateMod:(id *)ioValue error:(NSError **)outError {
    [Envelope clampScaleValue:ioValue max:7];
    return YES;
}

- (BOOL)validateLfo:(id *)ioValue error:(NSError **)outError {
    [Envelope clampScaleValue:ioValue max:16];
    return YES;
}

- (BOOL)validateBend:(id *)ioValue error:(NSError **)outError {
    [Envelope clampScaleValue:ioValue max:7];
    return YES;
}

- (BOOL)validateScale:(id *)ioValue error:(NSError **)outError {
    [Envelope clampScaleValue:ioValue max:7];
    return YES;
}

// MARK: to-many

// CAREFUL! Mutations which remove EnvelopeState elements must be done
// by reconstructing a new array to swap over. The vectors own the elements
// via shared pointer, and we can not have the last reference being released
// inside the engine.

- (void)insertObject:(EnvelopeStage *)object inStagesAtIndex:(NSUInteger)index {
    NSMutableArray< EnvelopeStage * > *stages = [[NSMutableArray alloc] init];
    NSUInteger i, count = [_stages count];
    for (i = 0; i < index; ++i) {
        [stages addObject:_stages[i]];
    }
    [stages addObject:object];
    for (i = index; i < count; ++i) {
        [stages addObject:_stages[i]];
    }

    int keyUp = _patch->key_up;
    if (keyUp >= (int)index) {
        self.keyUp = keyUp + 1;
    }

    [self connect:stages];
}

- (void)removeObjectFromStagesAtIndex:(NSUInteger)index {
    int keyUp = _patch->key_up;
    if (keyUp == index) {
        self.keyUp = NSNotFound;
    } else if ((int)index < keyUp) {
        self.keyUp = keyUp - 1;
    }

    NSMutableArray< EnvelopeStage * > *stages = [[NSMutableArray alloc] init];
    NSUInteger i, count = [_stages count];
    for (i = 0; i < count; ++i) {
        if (i != index) {
            [stages addObject:_stages[i]];
        }
    }
    [self connect:stages];
}

- (void)replaceObjectInStagesAtIndex:(NSUInteger)index withObject:(id)object {
    NSMutableArray< EnvelopeStage * > *stages = [[NSMutableArray alloc] init];
    NSUInteger i, count = [_stages count];
    for (i = 0; i < count; ++i) {
        if (i != index) {
            [stages addObject:_stages[i]];
        } else {
            [stages addObject:object];
        }
    }
    [self connect:stages];
}

- (void)addStagesObject:(EnvelopeStage *)object {
    NSMutableArray< EnvelopeStage * > *stages = [[NSMutableArray alloc] init];
    EnvelopeStage *es;
    for (es in _stages) {
        [stages addObject:es];
    }
    [stages addObject:object];
    [self connect:stages];
}

@end
