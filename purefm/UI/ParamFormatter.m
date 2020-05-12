//
//  ParamFormatter.m
//  purefm
//
//  Created by Paul Forgey on 5/12/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "ParamFormatter.h"
#import <stdlib.h>
#import <math.h>

@implementation ParamFormatter

- (NSString *)stringForObjectValue:(id)obj {
    return [NSString stringWithFormat:@"%d", [obj intValue]];
}

- (BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj forString:(NSString *)string errorDescription:(out NSString * _Nullable __autoreleasing *)error {
    char const *s = [string UTF8String];
    if (s[0] == 'l') {
        double level = atof(s+1) / 99.0;
        if (level < 0.0) {
            level = 0.0;
        } else if (level > 1.0) {
            level = 1.0;
        }
        if (self.invert) {
            level = 1.0 - level;
        }
        *obj = [NSNumber numberWithInt:(int)round(level * 127.0)];
        return YES;
    }

    int level = atoi(s);
    if (level < 0) {
        level = 0;
    } else if (level > 127) {
        level = 127;
    }
    *obj = [NSNumber numberWithInt:level];
    return YES;
}

@end
