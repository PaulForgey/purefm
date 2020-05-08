//
//  Operator.h
//  purefm
//
//  Created by Paul Forgey on 4/8/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Envelope.h"
#import "status.h"

#ifdef __cplusplus
# import "globals.hpp"
#endif // __cplusplus

typedef enum {
    kScale_LinearDown = 0x00,
    kScale_LinearUp   = 0x01,
    kScale_ExpDown    = 0x02,
    kScale_ExpUp      = 0x03
} ScaleType;

NS_ASSUME_NONNULL_BEGIN

@interface Operator : NSObject< NSCoding >

+(Operator *)operatorWithNumber:(int)n;

+ (void)clampMIDIValue:(id _Nullable * _Nonnull)ioValue;
+ (void)clampFrequencyValue:(id _Nullable * _Nonnull)ioValue;

#ifdef __cplusplus
- (op_patch const *)patch;
#endif // __cplusplus

@property (nonatomic) struct op_status const *status;

@property (nonatomic,readonly) int number;
@property (nonatomic,readonly) Envelope *envelope;
@property (nonatomic,readonly) BOOL algoChange;

@property (nonatomic) int sum;
@property (nonatomic) int mod;
@property (nonatomic) BOOL enabled;
@property (nonatomic) int level;
@property (nonatomic) BOOL resync;
@property (nonatomic) int velocity;
@property (nonatomic) int rateScale;
@property (nonatomic) int breakpoint;
@property (nonatomic) int keyScaleLeft;
@property (nonatomic) int keyScaleRight;
@property (nonatomic) ScaleType scaleTypeLeft;
@property (nonatomic) ScaleType scaleTypeRight;
@property (nonatomic) int frequency;
@property (nonatomic) BOOL fixed;

@property (readonly) int output;

- (void)updateStatus;

@end

NS_ASSUME_NONNULL_END
