//
//  LFO.h
//  purefm
//
//  Created by Paul Forgey on 4/26/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import "Envelope.h"
#ifdef __cplusplus
# import "globals.hpp"
#endif // __cplusplus

typedef enum {
    kLFO_Sine = 0,
    kLFO_Triangle,
    kLFO_Square,
    kLFO_SawUp,
    kLFO_SawDown,
    kLFO_Noise,
} LFOWave;

NS_ASSUME_NONNULL_BEGIN

@interface LFO : NSObject< NSCoding >

#ifdef __cplusplus
- (lfo_patch_ptr::pointer const &)patch;
#endif // __cplusplus

@property (nonatomic) AUParameterTree *parameterTree;
- (void)setParameter:(AUParameter *)parameter value:(AUValue)value;

@property (nonatomic,readonly) Envelope *envelope;
@property (nonatomic) BOOL resync;
@property (nonatomic) LFOWave wave;
@property (nonatomic) int frequency;
@property (nonatomic) int level;

@end

NS_ASSUME_NONNULL_END
