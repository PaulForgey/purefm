//
//  DurationFormatter.h
//  purefm
//
//  Created by Paul Forgey on 4/15/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnvelopeStage.h"

// displays a duration parameter as an eg rate
// display only

NS_ASSUME_NONNULL_BEGIN

@interface DurationFormatter : NSFormatter

@property double sampleRate;
@property (nonatomic,readonly) BOOL reformat;
@property (nonatomic) EnvelopeStageLinearity linearity;

@end

NS_ASSUME_NONNULL_END
