//
//  purefmAudioUnit.m
//  purefm
//
//  Created by Paul Forgey on 4/6/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "purefmAudioUnit.h"
#import "purefmDSPKernel.hpp"
#import "State.h"

#import <AVFoundation/AVFoundation.h>

@interface purefmAudioUnit ()

@property (nonatomic, readwrite) AUParameterTree *parameterTree;
@property AUAudioUnitBusArray *inputBusArray;
@property AUAudioUnitBusArray *outputBusArray;
@end

@implementation purefmAudioUnit {
    double _sampleRate;
    double _envelopeRate;
    double _lfoRate;
    State *_state;
}

@synthesize parameterTree = _parameterTree;
@synthesize sampleRate = _sampleRate;
@synthesize envelopeRate = _envelopeRate;
@synthesize lfoRate = _lfoRate;

- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription options:(AudioComponentInstantiationOptions)options error:(NSError **)outError {
    self = [super initWithComponentDescription:componentDescription options:options error:outError];

    if (self == nil) { return nil; }

	_kernelAdapter = [[purefmDSPKernelAdapter alloc] init];
	self.maximumFramesToRender = _kernelAdapter.maximumFramesToRender;

	[self setupAudioBuses];
	[self setupParameterTree];
    [self updatePatch];
	[self setupParameterCallbacks];

    return self;
}

- (State *)state {
    if (_state == nil) {
        _state = [[State alloc] init];
    }
    return _state;
}

- (void)updatePatch {
    [_kernelAdapter setPatch:[self.state patch]];
    self.state.parameterTree = _parameterTree;
    self.state.status = [_kernelAdapter status];
}

// MARK: AUAudioUnit Setup

- (void)setupAudioBuses {
	// Create the input and output bus arrays.
	_outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self
															 busType:AUAudioUnitBusTypeOutput
															  busses:@[_kernelAdapter.outputBus]];
}

- (void)setupParameterTree {
    // Create parameter objects.
    AUParameter *feedback =
    [AUParameterTree createParameterWithIdentifier:@"feedback"
                                              name:@"Feedback"
                                           address:kParam_Feedback
                                               min:0.0
                                               max:127.0
                                              unit:kAudioUnitParameterUnit_Generic
                                          unitName:nil
                                             flags:kAudioUnitParameterFlag_IsReadable|kAudioUnitParameterFlag_IsWritable
                                      valueStrings:nil
                               dependentParameters:nil];

    AUParameter *lfoWave =
    [AUParameterTree createParameterWithIdentifier:@"lfowave"
                                              name:@"LFO Waveform"
                                           address:kParam_LFOWave
                                               min:0
                                               max:5
                                              unit:kAudioUnitParameterUnit_Indexed
                                          unitName:nil
                                             flags:kAudioUnitParameterFlag_ValuesHaveStrings|kAudioUnitParameterFlag_IsReadable|kAudioUnitParameterFlag_IsWritable
                                      valueStrings:@[
                                                    @"Sine",
                                                    @"Triangle",
                                                    @"Square",
                                                    @"Saw Up",
                                                    @"Saw Down",
                                                    @"Noise"
                                                    ]
                               dependentParameters:nil];

    AUParameter *lfoOutput =
    [AUParameterTree createParameterWithIdentifier:@"lfooutput"
                                              name:@"LFO Output"
                                           address:kParam_LFOOutput
                                               min:0
                                               max:127
                                              unit:kAudioUnitParameterUnit_Generic
                                          unitName:nil
                                             flags:kAudioUnitParameterFlag_DisplayExponential|kAudioUnitParameterFlag_IsWritable|kAudioUnitParameterFlag_IsReadable
                                      valueStrings:nil
                               dependentParameters:nil];

    AUParameter *lfoFrequency =
    [AUParameterTree createParameterWithIdentifier:@"lfofreq"
                                              name:@"LFO Frequency"
                                           address:kParam_LFOFreq
                                               min:-40960.0
                                               max:24575.0
                                              unit:kAudioUnitParameterUnit_Generic
                                          unitName:nil
                                             flags:kAudioUnitParameterFlag_IsWritable|kAudioUnitParameterFlag_IsReadable
                                      valueStrings:nil
                               dependentParameters:nil];

    AUParameter *mono =
    [AUParameterTree createParameterWithIdentifier:@"mono"
                                              name:@"Mono"
                                           address:kParam_Mono
                                               min:0
                                               max:1
                                              unit:kAudioUnitParameterUnit_Boolean
                                          unitName:nil
                                             flags:kAudioUnitParameterFlag_IsReadable|kAudioUnitParameterFlag_IsWritable
                                      valueStrings:nil
                               dependentParameters:nil];

    AUParameter *middleC =
    [AUParameterTree createParameterWithIdentifier:@"middlec"
                                              name:@"Middle C"
                                           address:kParam_MiddleC
                                               min:0
                                               max:127
                                              unit:kAudioUnitParameterUnit_MIDINoteNumber
                                          unitName:nil
                                             flags:kAudioUnitParameterFlag_IsReadable|kAudioUnitParameterFlag_IsWritable
                                      valueStrings:nil
                               dependentParameters:nil];

    AUParameter *portamento =
    [AUParameterTree createParameterWithIdentifier:@"portamento"
                                              name:@"Portamento"
                                           address:kParam_Portamento
                                               min:0
                                               max:127
                                              unit:kAudioUnitParameterUnit_Generic
                                          unitName:nil
                                             flags:kAudioUnitParameterFlag_IsReadable|kAudioUnitParameterFlag_IsWritable
                                      valueStrings:nil
                               dependentParameters:nil];

    AUParameter *tuning =
    [AUParameterTree createParameterWithIdentifier:@"tuning"
                                              name:@"Tuning"
                                           address:kParam_Tuning
                                               min:-2048
                                               max:2047
                                              unit:kAudioUnitParameterUnit_Generic
                                          unitName:nil
                                             flags:kAudioUnitParameterFlag_IsReadable|kAudioUnitParameterFlag_IsWritable
                                      valueStrings:nil
                               dependentParameters:nil];


    // Create the parameter tree.
    _parameterTree = [AUParameterTree createTreeWithChildren:@[
        feedback,
        lfoWave,
        lfoOutput,
        lfoFrequency,
        mono,
        middleC,
        portamento,
        tuning,
    ]];
}

- (void)setupParameterCallbacks {
    __block State * const *state = &_state;

	// implementorValueObserver is called when a parameter changes value.
	_parameterTree.implementorValueObserver = ^(AUParameter *param, AUValue value) {
        if (*state != nil) {
            [*state setParameter:param value:value];
        }
	};
}

// MARK: AUAudioUnit Overrides

// If an audio unit has input, an audio unit's audio input connection points.
// Subclassers must override this property getter and should return the same object every time.
// See sample code.
- (AUAudioUnitBusArray *)inputBusses {
	return _inputBusArray;
}

// An audio unit's audio output connection points.
// Subclassers must override this property getter and should return the same object every time.
// See sample code.
- (AUAudioUnitBusArray *)outputBusses {
	return _outputBusArray;
}

// Allocate resources required to render.
// Subclassers should call the superclass implementation.
- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
	[super allocateRenderResourcesAndReturnError:outError];
	[_kernelAdapter allocateRenderResources];
    [self willChangeValueForKey:@"sampleRate"];
    _sampleRate = _kernelAdapter.outputBus.format.sampleRate;
    [self didChangeValueForKey:@"sampleRate"];
    [self willChangeValueForKey:@"envelopeRate"];
    if (_sampleRate >= 176400.0) {
        _envelopeRate = _sampleRate / 4.0;
    }
    else if (_sampleRate >= 88200.0) {
        _envelopeRate = _sampleRate / 2.0;
    }
    else {
        _envelopeRate = _sampleRate;
    }
    [self didChangeValueForKey:@"envelopeRate"];
    [self willChangeValueForKey:@"lfoRate"];
    _lfoRate = _envelopeRate / 16.0;
    [self didChangeValueForKey:@"lfoRate"];
	return YES;
}

// Deallocate resources allocated in allocateRenderResourcesAndReturnError:
// Subclassers should call the superclass implementation.
- (void)deallocateRenderResources {
	[_kernelAdapter deallocateRenderResources];

    // Deallocate your resources.
    [super deallocateRenderResources];
}

- (NSDictionary< NSString *, id > *)fullState {
    NSError *error = nil;

    NSMutableDictionary *s = [[NSMutableDictionary alloc] init];
    [s addEntriesFromDictionary:[super fullState]];
    [s setObject:[NSKeyedArchiver archivedDataWithRootObject:_state
                                       requiringSecureCoding:NO
                                                       error:&error]
          forKey:@"pureFMstate"];
    return s;
}

- (void)setFullState:(NSDictionary<NSString *,id> *)fullState {
    NSError *error = nil;
    NSKeyedUnarchiver *decode = [[NSKeyedUnarchiver alloc] initForReadingFromData:[fullState objectForKey:@"pureFMstate"]
                                                                            error:&error];
    if (error != nil) {
        NSLog(@"setFullState: %@", error);
        return;
    }

    decode.requiresSecureCoding = NO;

    [self willChangeValueForKey:@"state"];
    _state = [decode decodeObjectForKey:NSKeyedArchiveRootObjectKey];
    [self updatePatch];
    [self didChangeValueForKey:@"state"];

    [super setFullState:fullState];
}

// MARK: AUAudioUnit (AUAudioUnitImplementation)

// Block which subclassers must provide to implement rendering.
- (AUInternalRenderBlock)internalRenderBlock {
	return _kernelAdapter.internalRenderBlock;
}

@end

