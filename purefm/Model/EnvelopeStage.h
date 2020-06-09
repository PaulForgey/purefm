//
//  EnvelopeStage.h
//  purefm
//
//  Created by Paul Forgey on 4/13/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifdef __cplusplus
# include "globals.hpp"
#endif // __cplusplus

typedef enum {
    kLinearity_Exp = 0,
    kLinearity_Linear,
    kLinearity_Attack, // a very inprecise hack to allow DX-7 style behavior
    kLinearity_Delay,
    kLinearity_Pitch,  // alias for Linear but with different presentation
} EnvelopeStageLinearity;

NS_ASSUME_NONNULL_BEGIN

@interface EnvelopeStage : NSObject< NSCoding >

@property (nonatomic) int duration;
@property (nonatomic) int level;
@property (nonatomic) EnvelopeStageLinearity linearity;

#ifdef __cplusplus
- (eg_ptr)eg;
#endif // __cplusplus

@end

@interface PitchStage : EnvelopeStage

@property (nonatomic) BOOL delay;

@end

NS_ASSUME_NONNULL_END
