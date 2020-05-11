//
//  EnvelopeController.h
//  purefm
//
//  Created by Paul Forgey on 5/9/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Envelope.h"

NS_ASSUME_NONNULL_BEGIN

@interface EnvelopeController : NSViewController

@property Envelope *envelope;
@property Envelope *clip;
@property NSArray< Envelope * > *multiSelect; // for pasting
@property BOOL hasClip;
@property (nonatomic) double sampleRate;
@property (nonatomic) BOOL pitch;

+ (EnvelopeController *)envelopeController;

@end

NS_ASSUME_NONNULL_END
