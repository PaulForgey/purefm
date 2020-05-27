//
//  StateImporter.m
//  purefm
//
//  Created by Paul Forgey on 5/23/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "StateImporter.h"

#import <stdint.h>
#import <string.h>

// XXX this is a completely bogus and made-up vendor ID.
static uint8_t const kPatchHdr[4] = { 0xf0, 0x7f, 0x7f, 0x7f };

// system exclusive patch data is arranged type:value where the
// length of the values are type dependent. As this is midi data,
// nothing in here may have the high bit (0x80) set.
// old values must be preserved if items are changed or added
typedef enum {
    // root level items:
    // value types
    kInvalid    = 0,
    kFeedback   = 1,
    kMiddleC,

    // operator type
    kOperator,
    // envelope type
    kEnvelope,
    // lfo type
    kLFO,

    // operator items:
    // value types
    kSum,
    kMod,
    kEnabled,
    kLevel,
    kResync,
    kVelocity,
    kRateScale,
    kBreakpoint,
    kKeyScaleLeft,
    kKeyScaleRight,
    kScaleTypeLeft,
    kScaleTypeRight,
    kDetune,
    kFixed,
    // frequency type
    kFrequency,
    // also uses kEnvelope

    // envelope items:
    // value types
    kKeyUp,
    kLoop,
    kExpr,
    kAfter,
    kLFOScale,
    kBend,
    kScale,
    // envelope stage type
    kStage,

    // envelope stage items:
    // value types
    kDuration,
    kLinearity,
    // also uses kLevel

    // lfo items:
    kWave,
    // also uses kResync, kFrequency, kEnvelope

    // end of a thing
    kEnd,

} ParamKey;

static inline bool
consume(uint8_t const **bytes, int *byteslen, uint8_t *buf, int length) {
    if (*byteslen < length) {
        return false;
    }
    if (buf != NULL) {
        memcpy(buf, *bytes, length);
    }
    *bytes += length;
    *byteslen -= length;
    return true;
}

static inline uint8_t
int7ToMidi(int value) {
    return value & 0x7f;
}

static inline int
midiToInt7(uint8_t value) {
    int8_t s8 = ((int8_t)(value << 1)) >> 1; // sign extend bit 7
    return (int)s8;
}

@implementation StatePatch

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];

    self.name = [coder decodeObjectForKey:@"name"];
    self.data = [coder decodeObjectForKey:@"data"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.data forKey:@"data"];
}

- (BOOL)parseStage:(uint8_t const **)bytes length:(int *)length stage:(EnvelopeStage *)es {
    while (*length > 0) {
        uint8_t pair[2];
        if (!consume(bytes, length, pair, 1)) {
            return NO;
        }
        switch(pair[0]) {
        case kEnd:
            return YES;

        default:
            if (!consume(bytes, length, pair+1, 1)) {
                return NO;
            }
            switch(pair[0]) {
            case kLinearity:
                es.linearity = pair[1];
                break;

            case kDuration:
                es.duration = pair[1];
                break;

            case kLevel:
                es.level = pair[1];
                break;

            default:
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL)parseEnvelope:(uint8_t const **)bytes length:(int *)length envelope:(Envelope *)envelope {
    [envelope removeAllStages];

    while (*length > 0) {
        uint8_t pair[2];
        if (!consume(bytes, length, pair, 1)) {
            return NO;
        }

        EnvelopeStage *es = nil;

        switch(pair[0]) {
        case kStage:
            es = [[EnvelopeStage alloc] init];
            if (![self parseStage:bytes length:length stage:es]) {
                return NO;
            }
            [envelope addStagesObject:es];
            break;

        case kEnd:
            return YES;

        default:
            if (!consume(bytes, length, pair+1, 1)) {
                return NO;
            }
            switch(pair[0]) {
            case kKeyUp:
                envelope.keyUp = midiToInt7(pair[1]);
                break;

            case kLoop:
                envelope.loop = pair[1];
                break;

            case kExpr:
                envelope.expr = pair[1];
                break;

            case kAfter:
                envelope.after = pair[1];
                break;

             case kLFOScale:
                envelope.expr = pair[1];
                break;

            case kBend:
                envelope.bend = pair[1];
                break;

             case kScale:
                envelope.scale = pair[1];
                break;

            default:
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL)parseFrequency:(uint8_t const **)bytes length:(int *)length s16:(int16_t *)s16 {
    uint8_t buf[3];
    if (!consume(bytes, length, buf, 3)) {
        return NO;
    }
    // high bits overflow
    *s16 = (int16_t)buf[0] + ((int16_t)buf[1] << 7) + ((int16_t)buf[2] << 14);
    return YES;
}

- (BOOL)parseOperator:(uint8_t const **)bytes length:(int *)length state:(State *)state {
    // first byte is operator num
    uint8_t num;
    if (!consume(bytes, length, &num, 1) || num < 1 || num > 8) {
        return NO;
    }
    Operator *op = state.operators[num-1];
    int16_t s16;

    while (*length > 0) {
        uint8_t pair[2];
        if (!consume(bytes, length, pair, 1)) {
            return NO;
        }
        switch(pair[0]) {
        case kEnvelope:
            if (![self parseEnvelope:bytes length:length envelope:op.envelope]) {
                return NO;
            }
            break;

        case kFrequency:
            if (![self parseFrequency:bytes length:length s16:&s16]) {
                return NO;
            }
            op.frequency = s16;
            break;

        case kDetune:
            if (![self parseFrequency:bytes length:length s16:&s16]) {
                return NO;
            }
            op.detune = s16;
            break;

        case kEnd:
            return YES;

        default:
            if (!consume(bytes, length, pair+1, 1)) {
                return NO;
            }
            switch(pair[0]) {
            case kSum:
                op.sum = midiToInt7(pair[1]);
                break;

            case kMod:
                op.mod = midiToInt7(pair[1]);
                break;

            case kEnabled:
                op.enabled = pair[1];
                break;

            case kLevel:
                op.level = pair[1];
                break;

            case kResync:
                op.resync = pair[1];
                break;

            case kVelocity:
                op.velocity = pair[1];
                break;

            case kRateScale:
                op.rateScale = pair[1];
                break;

            case kBreakpoint:
                op.breakpoint = pair[1];
                break;

            case kKeyScaleLeft:
                op.keyScaleLeft = pair[1];
                break;

            case kKeyScaleRight:
                op.keyScaleRight = pair[1];
                break;

            case kScaleTypeLeft:
                op.scaleTypeLeft = pair[1];
                break;

            case kScaleTypeRight:
                op.scaleTypeRight = pair[1];
                break;

            case kFixed:
                op.fixed = pair[1];
                break;

            default:
                return NO;
            }
        }
    }

    return YES;
}

- (BOOL)parseLFO:(uint8_t const **)bytes length:(int *)length lfo:(LFO *)lfo {
    while (*length > 0) {
        uint8_t pair[2];
        int16_t s16;

        if (!consume(bytes, length, pair, 1)) {
            return NO;
        }

        switch(pair[0]) {
        case kEnvelope:
            if (![self parseEnvelope:bytes length:length envelope:lfo.envelope]) {
                return NO;
            }
            break;

        case kFrequency:
            if (![self parseFrequency:bytes length:length s16:&s16]) {
                return NO;
            }
            lfo.frequency = s16;
            break;

        case kEnd:
            return YES;

        default:
            if (!consume(bytes, length, pair+1, 1)) {
                return NO;
            }

            switch(pair[0]) {
            case kResync:
                lfo.resync = pair[1];
                break;

            case kWave:
                lfo.wave = pair[1];
                break;

            default:
                return NO;
            }
        }
    }

    return YES;
}

- (void)applyTo:(State *)state {
    uint8_t const *bytes = [self.data bytes];
    int length = (int)[self.data length];

    // eat the header, which has already been vetted
    if (!consume(&bytes, &length, NULL, 4)) {
        return;
    }

    while (length > 0) {
        uint8_t pair[2];
        if (!consume(&bytes, &length, pair, 1)) {
            break;
        }
        switch(pair[0]) {
        case 0xf7: // end of system exclusive
        case kEnd:
            break;

        case kOperator:
            if (![self parseOperator:&bytes length:&length state:state]) {
                length = 0;
            }
            break;

        case kEnvelope:
            if (![self parseEnvelope:&bytes length:&length envelope:state.pitchEnvelope]) {
                length = 0;
            }
            break;

        case kLFO:
            if (![self parseLFO:&bytes length:&length lfo:state.lfo]) {
                length = 0;
            }
            break;

        default:
            if (!consume(&bytes, &length, pair+1, 1)) {
                break;
            }

            switch(pair[0]) {
            case kFeedback:
                state.feedback = pair[1];
                break;

            case kMiddleC:
                state.middleC = pair[1];
                break;

            default:
                length = 0;
                break;
            }
        }
    }
}

@end

@implementation StateImporter

+ (StateImporter *)importerWithData:(NSData *)data error:(NSError **)error {
    StateImporter *importer = nil;

    uint8_t hdr[4];
    if ([data length] >= 4) {
        [data getBytes:hdr length:4];
        if (memcmp(hdr, kPatchHdr, 4) == 0) {
            importer = [[StateImporter alloc] init];
            [importer import:data];
        }
    }

    return importer;
}

- (void)import:(NSData *)data {
    StatePatch *patch = [[StatePatch alloc] init];
    patch.name = [NSString stringWithFormat:@"Patch %lu", [self.patches count]];

    patch.data = data;

    [self willChangeValueForKey:@"patches"];
    [self.patches addObject:patch];
    [self didChangeValueForKey:@"patches"];
}

- (NSData *)serializeEnvelopeStage:(EnvelopeStage *)es {
    uint8_t const bytes[] = {
        kStage,
        kLinearity, es.linearity,
        kDuration, es.duration,
        kLevel, es.level,
        kEnd,
    };
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

- (NSData *)serializeEnvelope:(Envelope *)e {
    NSMutableData *data = [[NSMutableData alloc] init];

    uint8_t pair[2];
    pair[0] = kEnvelope;
    [data appendBytes:pair length:1];

    pair[0] = kKeyUp;
    pair[1] = int7ToMidi((int)e.keyUp);
    [data appendBytes:pair length:2];

    pair[0] = kLoop;
    pair[1] = e.loop;
    [data appendBytes:pair length:2];

    pair[0] = kExpr;
    pair[1] = e.expr;
    [data appendBytes:pair length:2];

    pair[0] = kAfter;
    pair[1] = e.after;
    [data appendBytes:pair length:2];

    pair[0] = kLFOScale;
    pair[1] = e.lfo;
    [data appendBytes:pair length:2];

    pair[0] = kBend;
    pair[1] = e.bend;
    [data appendBytes:pair length:2];

    pair[0] = kScale;
    pair[1] = e.scale;
    [data appendBytes:pair length:2];

    EnvelopeStage *es;
    for (es in e.stages) {
        [data appendData:[self serializeEnvelopeStage:es]];
    }

    pair[0] = kEnd;
    [data appendBytes:pair length:1];

    return data;
}

- (NSData *)serializeFrequency:(int)freq forType:(uint8_t)t {
    uint8_t bytes[4];
    bytes[0] = t;
    bytes[1] = freq & 0x7f;
    bytes[2] = (freq >> 7) & 0x7f;
    bytes[3] = (freq >> 14) & 0x7f; // sign extend when deserializing
    return [NSData dataWithBytes:bytes length:4];
}

- (NSData *)serializeOperator:(Operator *)op {
    NSMutableData *data = [[NSMutableData alloc] init];

    uint8_t pair[2];
    pair[0] = kOperator;
    pair[1] = op.number;
    [data appendBytes:pair length:2];

    pair[0] = kSum;
    pair[1] = int7ToMidi(op.sum);
    [data appendBytes:pair length:2];

    pair[0] = kMod;
    pair[1] = int7ToMidi(op.mod);
    [data appendBytes:pair length:2];

    pair[0] = kEnabled;
    pair[1] = op.enabled;
    [data appendBytes:pair length:2];

    pair[0] = kLevel;
    pair[1] = op.level;
    [data appendBytes:pair length:2];

    pair[0] = kResync;
    pair[1] = op.resync;
    [data appendBytes:pair length:2];

    pair[0] = kVelocity;
    pair[1] = op.velocity;
    [data appendBytes:pair length:2];

    pair[0] = kRateScale;
    pair[1] = op.rateScale;
    [data appendBytes:pair length:2];

    pair[0] = kBreakpoint;
    pair[1] = op.breakpoint;
    [data appendBytes:pair length:2];

    pair[0] = kKeyScaleLeft;
    pair[1] = op.keyScaleLeft;
    [data appendBytes:pair length:2];

    pair[0] = kKeyScaleRight;
    pair[1] = op.keyScaleRight;
    [data appendBytes:pair length:2];

    pair[0] = kScaleTypeLeft;
    pair[1] = op.scaleTypeLeft;
    [data appendBytes:pair length:2];

    pair[0] = kScaleTypeRight;
    pair[1] = op.scaleTypeRight;
    [data appendBytes:pair length:2];

    pair[0] = kFixed;
    pair[1] = op.fixed;
    [data appendBytes:pair length:2];

    [data appendData:[self serializeFrequency:op.frequency forType:kFrequency]];
    [data appendData:[self serializeFrequency:op.detune forType:kDetune]];
    [data appendData:[self serializeEnvelope:op.envelope]];

    pair[0] = kEnd;
    [data appendBytes:pair length:1];

    return data;
}

- (NSData *)serializeLFO:(LFO *)lfo {
    NSMutableData *data = [[NSMutableData alloc] init];

    uint8_t pair[2];
    pair[0] = kLFO;
    [data appendBytes:pair length:1];

    pair[0] = kResync;
    pair[1] = lfo.resync;
    [data appendBytes:pair length:2];

    pair[0] = kWave;
    pair[1] = lfo.wave;
    [data appendBytes:pair length:2];

    [data appendData:[self serializeFrequency:lfo.frequency forType:kFrequency]];
    [data appendData:[self serializeEnvelope:lfo.envelope]];

    pair[0] = kEnd;
    [data appendBytes:pair length:1];

    return data;
}

- (NSData *)serializeState:(State *)state {
    NSMutableData *data = [[NSMutableData alloc] init];

    uint8_t pair[2];
    pair[0] = kFeedback;
    pair[1] = state.feedback;
    [data appendBytes:pair length:2];

    pair[0] = kMiddleC;
    pair[1] = state.middleC;
    [data appendBytes:pair length:2];

    Operator *o;
    for (o in state.operators) {
        [data appendData:[self serializeOperator:o]];
    }

    [data appendData:[self serializeEnvelope:state.pitchEnvelope]];
    [data appendData:[self serializeLFO:state.lfo]];

    pair[0] = kEnd;
    [data appendBytes:pair length:1];

    return data;
}

- (void)addPatch:(State *)state {
    StatePatch *patch = [[StatePatch alloc] init];
    patch.name = [NSString stringWithFormat:@"Patch %lu", [self.patches count]];

    NSMutableData *data = [[NSMutableData alloc] init];
    [data appendBytes:kPatchHdr length:4];

    [data appendData:[self serializeState:state]];

    uint8_t const end = 0xf7;
    [data appendBytes:&end length:1];
    patch.data = data;

    [self willChangeValueForKey:@"patches"];

    StatePatch *p;
    BOOL found = NO;
    int n = 0;
    for (p in self.patches) {
        if ([p.data isEqualToData:data]) {
            found = YES;
            patch = (StatePatch *)self.patches[n];
            self.patches[n] = self.patches[0];
            self.patches[0] = patch;
            break;
        }
        n++;
    }

    if (!found) {
        [self.patches addObject:patch];
    }
    
    [self didChangeValueForKey:@"patches"];
}

@end
