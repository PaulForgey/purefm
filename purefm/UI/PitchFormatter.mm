//
//  PitchFormatter.m
//  purefm
//
//  Created by Paul Forgey on 4/27/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "PitchFormatter.h"
#import "Tables.hpp"
#import <cstdlib>

@implementation PitchFormatter {
    int _scale;
}

- (void)setScale:(int)scale {
    [self willChangeValueForKey:@"reformat"];
    _scale = scale;
    [self didChangeValueForKey:@"reformat"];
}

- (int)scale {
    return _scale;
}

- (NSString *)stringForObjectValue:(id)obj {
    int v = [obj intValue];

    v = tables::pitch_param(v, 7 - _scale) >> 8;
    div_t octaves = std::div(v, 4096);
    double steps = (double)octaves.rem / (4096.0 / 12.0);

    return [NSString stringWithFormat:@"%d octaves, %.2f steps", octaves.quot, steps];
}

- (BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj forString:(NSString *)string errorDescription:(out NSString * _Nullable __autoreleasing *)error {
    return NO;
}

@end
