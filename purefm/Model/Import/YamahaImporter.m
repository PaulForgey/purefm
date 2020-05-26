//
//  YamahaImporter.m
//  purefm
//
//  Created by Paul Forgey on 5/21/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "YamahaImporter.h"
#import "State.h"
#import "Operator.h"
#import "Envelope.h"
#import "EnvelopeStage.h"

#import <math.h>
#import <stdint.h>

static double const middleC = 261.625565;

enum {
    kDX7_Voice = 0,
    kDX7_32Voices = 9,
};

typedef struct dx7_voice_op {
    uint8_t eg_rate[4];
    uint8_t eg_level[4];
    uint8_t breakpoint;
    uint8_t left;
    uint8_t right;
    uint8_t left_curve;
    uint8_t right_curve;
    uint8_t rate_scale;
    uint8_t amp_mod;
    uint8_t velocity;
    uint8_t level;
    uint8_t osc_mode;
    uint8_t freq_coarse;
    uint8_t freq_fine;
    uint8_t detune;
} __attribute((packed)) dx7_voice_op;
static_assert(sizeof(dx7_voice_op) == 21, "");

typedef struct dx7_voice {
    dx7_voice_op ops[6];
    uint8_t pitch_eg_rate[4];
    uint8_t pitch_eg_level[4];
    uint8_t alg;
    uint8_t feedback;
    uint8_t osc_sync;
    uint8_t lfo_speed;
    uint8_t lfo_delay;
    uint8_t lfo_pmd;
    uint8_t lfo_amd;
    uint8_t lfo_sync;
    uint8_t lfo_wave;
    uint8_t pmd;
    uint8_t transpose;
    char name[10];
} __attribute((packed)) dx7_voice;
static_assert(sizeof(dx7_voice) == 155, "");

typedef struct dx7_packed_voice_op {
    uint8_t eg_rate[4];
    uint8_t eg_level[4];
    uint8_t breakpoint;
    uint8_t left;
    uint8_t right;
    uint8_t curves;
    uint8_t detune_rate_scale;
    uint8_t velocity_amp_mod;
    uint8_t level;
    uint8_t freq_coarse_mode;
    uint8_t freq_fine;
} __attribute__((packed)) dx7_packed_voice_op;
static_assert(sizeof(dx7_packed_voice_op) == 17, "");

typedef struct dx7_packed_voice {
    dx7_packed_voice_op ops[6];
    uint8_t pitch_eg_rate[4];
    uint8_t pitch_eg_level[4];
    uint8_t alg;
    uint8_t osc_sync_feedback;
    uint8_t lfo_speed;
    uint8_t lfo_delay;
    uint8_t lfo_pmd;
    uint8_t lfo_amd;
    uint8_t lfo_pmd_wave_sync;
    uint8_t transpose;
    char name[10];
} __attribute__((packed)) dx7_packed_voice;
static_assert(sizeof(dx7_packed_voice) == 128, "");

typedef struct dx7_sysex {
    uint8_t status;
    uint8_t mid;
    uint8_t sub_status;
    uint8_t format;
    uint8_t count_msb;
    uint8_t count_lsb;
    union {
        dx7_voice voice;
        dx7_packed_voice packed_voice[32];
    } data;
    uint8_t checksum;
    uint8_t status_end;
} __attribute__((packed)) dx7_sysex;

typedef struct op_alg {
    int mod, sum;
} op_alg;

static op_alg const dx7_alg[32][6] = {
    /*
     * Algorithm 1
     *    6*
     *    5
     * 2  4
     * 1--3
     */
    { { 1, 2 }, { -1, -1 }, { 3, -1}, { 4, -1}, { 5, -1}, { 5, 6 } },
    /*
     * Algorithm 2
     *    6
     *    5
     * 2* 4
     * 1--3
     */
    { { 1, 2 }, { 1, -1 }, { 3, -1}, { 4, -1 }, { 5, -1}, { -1, 6 } },
    /*
     * Algorithm 3
     * 3  6*
     * 2  5
     * 1--4
     */
    { { 1, 3 }, { 2, -1 }, { -1, -1 }, { 4, -1 }, { 5, -1 }, { 5, 6 } },
    /*
     * Algorithm 4
     * 3  6<
     * 2  5
     * 1--4>
     */
    { { 1, 3 }, { 2, -1 }, { -1, -1 }, { 4, -1 }, { 5, -1 }, { 3, 6 } },
    /*
     * Algorithm 5
     * 2  4  6*
     * 1--3--5
     */
    { { 1, 2 }, { -1, -1 }, { 3, 4 }, { -1, -1 }, { 5, -1 }, { 5, 6 } },
    /*
     * Algorithm 6
     * 2  4  6<
     * 1--3--5>
     */
    { { 1, 2 }, { -1, -1 }, { 3, 4 }, { -1, -1 }, { 5, -1 }, { 4, 6 } },
    /*
     * Algorithm 7
     *       6*
     * 2  4--5
     * 1--3
     */
    { { 1, 2 }, { -1, -1 }, { 3, -1 }, { -1, 4 }, { 5, -1 }, { 5, 6 } },
    /*
     * Algorithm 8
     *       6
     * 2  4*-5
     * 1--3
     */
    { { 1, 2 }, { -1, -1 }, { 3, -1 }, { 3, 4 }, { 5, -1 }, { -1, 6 } },
    /*
     * Algorithm 9
     *       6
     * 2* 4--5
     * 1--3
     */
    { { 1, 2 }, { 1, -1 }, { 3, -1 }, { -1, 4 }, { 5, -1 }, { -1, 6 } },
    /*
     * Algorithm 10
     * 3*
     * 2  5--6
     * 1--4
     */
    { { 1, 3 }, { 2, -1 }, { 2, -1 }, { 4, -1 }, { -1, 5 }, { -1, 6 } },
    /*
     * Algorithm 11
     * 3
     * 2  5--6*
     * 1--4
     */
    { { 1, 3 }, { 2, -1 }, { -1, -1 }, { 4, -1 }, { -1, 5 }, { 5, 6 } },
    /*
     * Algorithm 12
     * 2* 4--5--6
     * 1--3
     */
    { { 1, 2 }, { 1, -1 }, { 3, -1 }, { -1, 4 }, { -1, 5 }, { -1, 6 } },
    /*
     * Algorithm 13
     * 2  4--5--6*
     * 1--3
     */
    { { 1, 2 }, { -1, -1 }, { 3, -1 }, { -1, 4 }, { -1, 5 }, { 5, 6 } },
    /*
     * Algorithm 14
     *    5--6*
     * 2  4
     * 1--3
     */
    { { 1, 2 }, { -1, -1 }, { 3, -1 }, { 4, -1 }, { -1, 5 }, { 5, 6 } },
    /*
     * Algorithm 15
     *    5--6
     * 2* 4
     * 1--3
     */
    { { 1, 2 }, { 1, -1 }, { 3, -1 }, { 4, -1 }, { -1, 5 }, { -1, 6 } },
    /*
     * Algorithm 16
     *    4  6*
     * 2--3--5
     * 1
     */
     { { 1, -1 }, { -1, 2 }, { 3, 4 }, { -1, -1 }, { 5, -1 }, { 5, 6 } },
    /*
     * Algorithm 17
     *    4  6
     * 2*-3--5
     * 1
     */
     { { 1, -1 }, { 1, 2 }, { 3, 4 }, { -1, -1 }, { 5, -1 }, { -1, 6 } },
    /*
     * Algorithm 18
     *       6
     *       5
     * 2--3*-4
     * 1
     */
    { { 1, -1 }, { -1, 2 }, { 2, 3 }, { 4, -1 }, { 5, -1 }, { -1, 6 } },
    /*
     * Algorithm 19
     * 3
     * 2  6* 6*
     * 1--4--5
     */
     { { 1, 3 }, { 2, -1 }, { -1, -1 }, { 5, 4 }, { 5, -1 }, { 5, 6 } },
    /*
     * Algorithm 20
     * 3* 3* 5--6
     * 1--2--4
     */
    { { 2, 1 }, { 2, 3 }, { 2, -1 }, { 4, -1 }, { -1, 5 }, { -1, 6 } },
    /*
     * Algorithm 21
     * 3* 3* 6  6
     * 1--2--4--5
     */
     { { 2, 1 }, { 2, 3 }, { 2, -1 }, { 5, 4 }, { 5, -1 }, { -1, 6 } },
    /*
     * Algorithm 22
     * 2  6* 6* 6*
     * 1--3--4--5
     */
    { { 1, 2 }, { -1, -1 }, { 5, 3 }, { 5, 4 }, { 5, -1 }, { 5, 6 } },
    /*
     * Algorithm 23
     *    3  6* 6*
     * 1--2--4--5
     */
    { { -1, 1 }, { 2, 3 }, { -1, -1 }, { 5, 4 }, { 5, -1 }, { 5, 6 } },
    /*
     * Algorithm 24
     *       6* 6* 6*
     * 1--2--3--4--5
     */
    { { -1, 1 }, { -1, 2 }, { 5, 3 }, { 5, 4 }, { 5, -1 }, { 5, 6 } },
    /*
     * Algorithm 25
     *          6* 6*
     * 1--2--3--4--5
     */
    { { -1, 1 }, { -1, 2 }, { -1, 3 }, { 5, 4 }, { 5, -1 }, { 5, 6 } },
    /*
     * Algorithm 26
     *    3  5--6*
     * 1--2--4
     */
    { { -1, 1 }, { 2, 3 }, { -1, -1 }, { 4, -1 }, { -1, 5 }, { 5, 6 } },
    /*
     * Algorithm 27
     *    3* 5--6
     * 1--2--4
     */
    { { -1, 1 }, { 2, 3 }, { 2, -1 }, { 4, -1 }, { -1, 5 }, { -1, 6 } },
    /*
     * Algorithm 28
     *    5*
     * 2  4
     * 1--3--6
     */
     { { 1, 2 }, { -1, -1 }, { 3, 5 }, { 4, -1 }, { 4, -1 }, { -1, 6 } },
    /*
     * Algorithm 29
     *       4  6*
     * 1--2--3--5
     */
    { { -1, 1 }, { -1, 2 }, { 3, 4 }, { -1, -1 }, { 5, -1 }, { 5, 6 } },
    /*
     * Algorithm 30
     *       5*
     *       4
     * 1--2--3--6
     */
    { { -1, 1 }, { -1, 2 }, { 3, 5 }, { 4, -1 }, { 4, -1 }, { -1, 6 } },
    /*
     * Algorithm 31
     *             6*
     * 1--2--3--4--5
     */
    { { -1, 1 }, { -1, 2 }, { -1, 3 }, { -1, 4 }, { 5, -1 }, { 5, 6 } },
    /*
     * Algorithm 32
     * 1--2--3--4--5--6*
     */
    { { -1, 1 }, { -1, 2 }, { -1, 3 }, { -1, 4 }, { -1, 5 }, { 5, 6 } },
};

@implementation YamahaPatch {
    dx7_voice _voice;
}

- (YamahaPatch *)initWithVoice:(dx7_voice const *)voice {
    self = [super init];
    [self setVoice:voice];
    return self;
}

- (YamahaPatch *)initWithCoder:(NSCoder *)coder {
    self = [super init];

    self.name = [coder decodeObjectForKey:@"name"];
    NSData *data = [coder decodeObjectForKey:@"data"];
    [data getBytes:&_voice length:sizeof(_voice)];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.name forKey:@"name"];
    NSData *data = [NSData dataWithBytes:&_voice length:sizeof(_voice)];
    [coder encodeObject:data forKey:@"data"];
}

- (void)setVoice:(dx7_voice const *)voice {
    _voice = *voice;
    char name[11];
    name[10] = 0;
    strncpy(name, _voice.name, 10);
    self.name = @(name);
}

static int
dx7_level(int level) {
    static int const lut[20] =
        {0, 5, 9, 13, 17, 20, 23, 25, 27, 29, 31, 33, 35, 37, 39, 41, 42, 43, 45, 46};
    if (level < 20) {
        return lut[level];
    }
    return level + 28;
}

static int
dx7_scale(int value) {
    return (int)round(((double)value / 99.0) * 127.0);
}

static int
dx7_duration(int value) {
    return dx7_scale(value) ^ 127;
}

static EnvelopeStage *
dx7_stage(int level, int rate) {
    EnvelopeStage *es = [[EnvelopeStage alloc] init];
    es.level = dx7_level(level);
    es.duration = dx7_duration(rate);
    es.linearity = kLinearity_Attack;

    return es;
}

static ScaleType
dx7_curve(int value) {
    switch(value) {
    case 0:
        return kScale_LinearDown;
    case 1:
        return kScale_ExpDown;
    case 2:
        return kScale_ExpUp;
    case 3:
        return kScale_LinearUp;
    }
    return -1;
}

- (void)applyTo:(State *)state {
    static double const pmd[8] = {
        0.0, 0.5, 1.0, 2.0, 3.0, 4.0, 7.0, 12.0
    };
    static double const lfo[100] = {
        0.0625, 0.1248, 0.3115, 0.4354, 0.6198,
        0.7444, 0.9305, 1.1164, 1.2842, 1.4969,
        1.5678, 1.7390, 1.9102, 2.0813, 2.2525,
        2.4237, 2.5807, 2.7377, 2.8947, 3.0517,
        3.2087, 3.3668, 3.5249, 3.6830, 3.8411,
        3.9991, 4.1594, 4.3197, 4.4800, 4.6403,
        4.8005, 4.9536, 5.1066, 5.2597, 5.4127,
        5.5658, 5.7249, 5.8841, 6.0432, 6.2024,
        6.3616, 6.5200, 6.6785, 6.8370, 6.9955,
        7.1540, 7.3005, 7.4470, 7.5935, 7.7399,
        7.8864, 8.0206, 8.1548, 8.2889, 8.4231,
        8.5573, 8.7126, 8.8680, 9.0234, 9.1787,
        9.3341, 9.6696,10.0052, 10.3408, 10.6763,
        11.0119, 11.9637, 12.9155, 13.8672, 14.8190,
        15.7708, 16.6402, 17.5097, 18.3791, 19.2486,
        20.1180, 21.0407, 21.9634, 22.8861, 23.8088,
        24.7315, 25.7597, 26.7880, 27.8162, 28.8445,
        29.8727, 31.2282, 32.5837, 33.9392, 35.2947,
        36.6502, 37.8125, 38.9748, 40.1370, 41.2993,
        42.4616, 43.6398, 44.8180, 45.9962, 47.1744
    };


    int i, o;
    for (o = 0; o < 6; ++o) {
        dx7_voice_op const *dx7_op = &_voice.ops[5-o];
        Operator *op = state.operators[o];
        Envelope *e = [[Envelope alloc] init];

        for (i = 0; i < 4; ++i) {
            [e addStagesObject:dx7_stage(dx7_op->eg_level[i], dx7_op->eg_rate[i])];
        }
        e.keyUp = 3;
        e.expr = (dx7_op->amp_mod & 3) * 127 / 3;
        e.lfo = dx7_scale(_voice.lfo_amd);
        [op.envelope replace:e];

        op_alg const *alg = &dx7_alg[_voice.alg][o];
        op.mod = alg->mod;
        op.sum = alg->sum;
        op.enabled = YES;
        op.level = dx7_level(dx7_op->level);
        op.resync = _voice.osc_sync ? YES : NO;
        op.velocity = (dx7_op->velocity & 7);
        op.rateScale = (dx7_op->rate_scale & 7) * 127 / 7;
        op.breakpoint = (int)(dx7_op->breakpoint) + 0x15;
        op.keyScaleLeft = dx7_scale(dx7_op->left);
        op.keyScaleRight = dx7_scale(dx7_op->right);
        op.scaleTypeLeft = dx7_curve(dx7_op->left_curve);
        op.scaleTypeRight = dx7_curve(dx7_op->right_curve);

        double v;
        if (dx7_op->osc_mode != 0) {
            op.fixed = YES;
            v = pow(10.0, (double)(dx7_op->freq_coarse & 3) + (double)(dx7_op->freq_fine) / 100.0);
            v /= middleC;
        } else {
            op.fixed = NO;
            v = (double)(dx7_op->freq_coarse);
            if (v < 0) {
                v = 0.5;
            }
            v *= 1.0 + ((double)(dx7_op->freq_fine) / 100.0);
        }
        if (v != 0.0) {
            v = 4096.0 * log2(v);
        }
        op.frequency = (int)round(v);
        op.detune = (dx7_op->detune - 7) * 4;
    }
    state.operators[6].enabled = NO;
    state.operators[6].sum = 7;
    state.operators[6].mod = -1;
    state.operators[7].enabled = NO;
    state.operators[7].sum = -1;
    state.operators[7].mod = -1;

    Envelope *e = [[Envelope alloc] init];
    for (i = 0; i < 4; ++i) {
        EnvelopeStage *es = [[EnvelopeStage alloc] init];
        es.linearity = kLinearity_Pitch;
        es.duration = dx7_duration(_voice.pitch_eg_rate[i]);
        es.level = dx7_scale(_voice.pitch_eg_level[i]);
        [e addStagesObject:es];
    }
    e.keyUp = 3;
    [state.pitchEnvelope replace:e];
    state.pitchEnvelope.scale = 6;
    state.pitchEnvelope.lfo = (int)round((pmd[_voice.pmd & 7] * (double)dx7_scale(_voice.lfo_pmd)) / 12.0);

    double v = lfo[_voice.lfo_speed] / (middleC * 16.0);
    v = 4096.0 * log2(v);
    state.lfo.frequency = (int)round(v);

    e = [[Envelope alloc] init];
    EnvelopeStage *es = [[EnvelopeStage alloc] init];
    es.linearity = kLinearity_Delay;
    es.level = 0;
    // WRONG: this is spitball, and there is a proper translation somewhere
    es.duration = dx7_duration(_voice.lfo_delay);
    [e addStagesObject:es];
    es = [[EnvelopeStage alloc] init];
    es.linearity = kLinearity_Delay;
    es.level = 127;
    es.duration = 0;
    [e addStagesObject:es];
    e.keyUp = -1;
    [state.lfo.envelope replace:e];

    state.feedback = (1 << _voice.feedback) - 1;
    state.middleC = (48 - _voice.transpose) + 36;
}

@end

@implementation YamahaImporter

- (YamahaImporter *)initWithVoice:(dx7_voice const *)voice {
    self = [super init];
    [self.patches addObject:[[YamahaPatch alloc] initWithVoice:voice]];
    return self;
}

- (YamahaImporter *)initWithVoices:(dx7_packed_voice const *)voices {
    self = [super init];
    YamahaPatch *nodes[32];

    int n;
    for (n = 0; n < 32; ++n) {
        dx7_voice voice;
        dx7_packed_voice const *p = &voices[n];

        int o;
        for (o = 0; o < 6; ++o) {
            dx7_packed_voice_op const *pop = &p->ops[o];
            dx7_voice_op *op = &voice.ops[o];

            memcpy(op->eg_rate, pop->eg_rate, sizeof(pop->eg_rate));
            memcpy(op->eg_level, pop->eg_level, sizeof(pop->eg_level));
            op->breakpoint = pop->breakpoint;
            op->left = pop->left;
            op->right = pop->right;
            op->left_curve = (pop->curves >> 2) & 3;
            op->right_curve = pop->curves & 3;
            op->detune = pop->detune_rate_scale >> 3;
            op->rate_scale = pop->detune_rate_scale & 7;
            op->velocity = pop->velocity_amp_mod >> 2;
            op->amp_mod = pop->velocity_amp_mod & 3;
            op->level = pop->level;
            op->freq_coarse = pop->freq_coarse_mode >> 1;
            op->osc_mode = pop->freq_coarse_mode & 1;
            op->freq_fine = pop->freq_fine;
        }

        memcpy(voice.pitch_eg_rate, p->pitch_eg_rate, 4);
        memcpy(voice.pitch_eg_level, p->pitch_eg_level, 4);
        voice.alg = p->alg;
        voice.osc_sync = p->osc_sync_feedback >> 3;
        voice.feedback = p->osc_sync_feedback & 7;
        voice.lfo_speed = p->lfo_speed;
        voice.lfo_delay = p->lfo_delay;
        voice.lfo_pmd = p->lfo_pmd;
        voice.lfo_amd = p->lfo_amd;
        voice.pmd = p->lfo_pmd_wave_sync >> 4;
        voice.lfo_wave = (p->lfo_pmd_wave_sync >> 1) & 7;
        voice.lfo_sync = p->lfo_pmd_wave_sync & 1;
        voice.transpose = p->transpose;
        memcpy(voice.name, p->name, 10);

        nodes[n] = [[YamahaPatch alloc] initWithVoice:&voice];
    }

    [self.patches addObjectsFromArray:[NSArray arrayWithObjects:nodes count:32]];
    return self;
}

+ (YamahaImporter *)importerWithData:(NSData *)data error:(NSError **)error {
    dx7_sysex sysex;

    NSUInteger length = [data length];
    if (length != 163 && length != 4104) {
        return nil;
    }

    [data getBytes:&sysex range:NSMakeRange(0, length)];
    if (sysex.mid != 0x43) {
        return nil; // not yamaha
    }

    YamahaImporter *n = nil;

    switch (sysex.format) {
        case kDX7_Voice: // 1 voice
            if (sysex.count_msb != 1 || sysex.count_lsb != 155) {
                return nil;
            }
            n = [[YamahaImporter alloc] initWithVoice:&sysex.data.voice];
            break;

        case kDX7_32Voices: // 32 voices packed
            if (sysex.count_msb != 0x20 || sysex.count_lsb != 0) {
                return nil;
            }
            n = [[YamahaImporter alloc] initWithVoices:sysex.data.packed_voice];
            break;

        default:
            break; // we only recognize the above forms
    }

    return n;
}

@end
