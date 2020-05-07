//
//  DurationFormatter.mm
//  purefm
//
//  Created by Paul Forgey on 4/15/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "DurationFormatter.h"
#import "Tables.hpp"

@implementation DurationFormatter {
    double _sampleRate;
    EnvelopeStageLinearity _linearity;
}

@synthesize sampleRate = _sampleRate;

- (void)setLinearity:(EnvelopeStageLinearity)linearity {
    [self willChangeValueForKey:@"reformat"];
    _linearity = linearity;
    [self didChangeValueForKey:@"reformat"];
}

- (EnvelopeStageLinearity)linearity {
    return _linearity;
}

- (NSString *)stringForObjectValue:(id)obj {
    if (_sampleRate < 0) {
        return @"inf?";
    }

    int value = tables::duration_param([obj intValue]);

    switch (_linearity) {
    case kLinearity_Exp: {
        // 6 db per lower 20 bits of samples
        double dbSec = (6.0 * self.sampleRate) / (double)(1 << 20);
        dbSec *= (double)value;

        return [NSString stringWithFormat:@"%.3f db/sec", dbSec];
        }

    case kLinearity_Linear: {
        // 24 bit unit range -> "mv" 0-1000 range
        double unitsSec = ((double)value * _sampleRate) / 16777.216;
        return [NSString stringWithFormat:@"%.3f mv/s", unitsSec];
        }

    case kLinearity_Pitch: {
        // upper 16 bit unit range
        double unitsSec = (double)value * (_sampleRate / 256.0);
        if (unitsSec >= 4096.0) {
            return [NSString stringWithFormat:@"%.3f oct/s", unitsSec / 4096.0];
        }
        if (unitsSec >= (4096.0 / 12.0)) {
            return [NSString stringWithFormat:@"%.3f notes/s", unitsSec / (4096.0 / 12.0)];
        }
        return [NSString stringWithFormat:@"%.3f units/s", unitsSec];
    }

    case kLinearity_Delay: {
        // delay time is time to swing entire 16 bit range at rate
        double secs = ((65536.0 / _sampleRate) * 256.0) / (double)value;

        if (secs >= 60.0) {
            return [NSString stringWithFormat:@"%.3f m", secs / 60.0];
        }
        if (secs >= 1.0) {
            return [NSString stringWithFormat:@"%.3f s", secs];
        }
        return [NSString stringWithFormat:@"%.3f ms", secs * 1000.00];
        }
    }

    return [NSString stringWithFormat:@"%@",obj];

}

- (BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj forString:(NSString *)string errorDescription:(out NSString * _Nullable __autoreleasing *)error {
    return NO;
}

@end
