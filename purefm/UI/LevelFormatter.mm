//
//  LevelFormatter.mm
//  purefm
//
//  Created by Paul Forgey on 4/15/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "LevelFormatter.h"
#import "tables.hpp"
#import "globals.hpp"

@implementation LevelFormatter

- (NSString *)stringForObjectValue:(id)obj {
    int value = tables::level_param([obj intValue]);

    // 6 db per 1 << 20
    double db = -6.0 * ((double)(eg_max - value) / (double)0x100000);
    NSString *fmt;
    if (value == eg_min) {
        fmt = @"-inf db";
    } else {
        fmt = @"%.3f db";
    }

    return [NSString stringWithFormat:fmt, db];
}

- (BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj forString:(NSString *)string errorDescription:(out NSString * _Nullable __autoreleasing *)error {
    return NO;
}

@end
