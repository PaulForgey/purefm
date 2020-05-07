//
//  FrequencyFormatter.m
//  purefm
//
//  Created by Paul Forgey on 4/26/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "FrequencyFormatter.h"
#import <math.h>
#import <stdlib.h>

static double const middleC = 261.625565;

@implementation FrequencyFormatter {
    BOOL _fixed;
    BOOL _lfo;
}

@synthesize lfo = _lfo;

- (void)setFixed:(BOOL)fixed {
    [self willChangeValueForKey:@"reformat"];
    _fixed = fixed;
    [self didChangeValueForKey:@"reformat"];
}

- (BOOL)fixed {
    return _fixed;
}

- (NSString *)editingStringForObjectValue:(id)obj {
    int v = [obj intValue];

    // 4096 pitch units per octave
    double m = exp2((double)v / 4096.0);

    if (_lfo) {
        // LFOs run at 1/16 the speed
        return [NSString stringWithFormat:@"%.3f", m * (middleC / 16.0)];
    }
    if (_fixed) {
        // 0 is middle-C 261.625565
        return [NSString stringWithFormat:@"%.3f", m * middleC];
    }

    return [NSString stringWithFormat:@"%.3f", m];
}

- (NSString *)stringForObjectValue:(id)obj {
    if (_fixed || _lfo) {
        return [NSString stringWithFormat:@"%@ hz", [self editingStringForObjectValue:obj]];
    }
    return [NSString stringWithFormat:@"* %@", [self editingStringForObjectValue:obj]];
}

- (BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj forString:(NSString *)string errorDescription:(out NSString * _Nullable __autoreleasing *)error {
    double v = atof([string UTF8String]);
    if (v <= 0.0) {
        return NO;
    }

    if (_lfo) {
        v /= (middleC / 16.0);
    }
    else if (_fixed) {
        v /= middleC;
    }
    v = 4096.0 * log2(v);

    *obj = @((int)round(v));
    return YES;
}

@end
