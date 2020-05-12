//
//  TuningFormatter.m
//  purefm
//
//  Created by Paul Forgey on 5/11/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "TuningFormatter.h"

@implementation TuningFormatter

-(NSString *)stringForObjectValue:(id)obj {
    double d = [obj doubleValue];
    return [NSString stringWithFormat:@"%.3f cents", d / (4096.0 / 12.0) * 100.0];
}

-(BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj forString:(NSString *)string errorDescription:(out NSString * _Nullable __autoreleasing *)error {
    return NO;
}

@end
