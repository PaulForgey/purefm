//
//  State.h
//  purefm
//
//  Created by Paul Forgey on 4/28/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import "Operator.h"
#import "LFO.h"
#import "Envelope.h"
#import "status.h"

#ifdef __cplusplus
# import "globals.hpp"
#endif // __cplusplus

NS_ASSUME_NONNULL_BEGIN

@interface State : NSObject< NSCoding >

@property (nonatomic) AUParameterTree *parameterTree;
@property (nonatomic) struct status const *status;

@property (nonatomic,readonly) NSArray< Operator * > *operators;
@property (nonatomic,readonly) Envelope *pitchEnvelope;
@property (nonatomic,readonly) LFO *lfo;

@property (nonatomic) int feedback;
@property (nonatomic )BOOL mono;
@property (nonatomic) int middleC;
@property (nonatomic) int portamento;

@property (readonly) int pitchStage;

#ifdef __cplusplus
- (patch_ptr::pointer const &)patch;
#endif // __cplusplus

- (void)setParameter:(AUParameter *)parameter value:(AUValue)value;
- (void)updateStatus;

@end

NS_ASSUME_NONNULL_END
