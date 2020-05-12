//
//  purefmAudioUnit.h
//  purefm
//
//  Created by Paul Forgey on 4/6/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "purefmDSPKernelAdapter.h"
#import "State.h"

enum {
    kParam_Feedback = 0,
    kParam_LFOWave,
    kParam_LFOOutput,
    kParam_LFOFreq,
    kParam_Mono,
    kParam_MiddleC,
    kParam_Portamento,
    kParam_Tuning,
};

@interface purefmAudioUnit : AUAudioUnit

@property (nonatomic, readonly) State *state;
@property (nonatomic, readonly) purefmDSPKernelAdapter *kernelAdapter;
@property (readonly) double sampleRate;
@property (readonly) double envelopeRate;
@property (readonly) double lfoRate;

- (void)updatePatch;

- (void)setupAudioBuses;
- (void)setupParameterTree;
- (void)setupParameterCallbacks;
@end
