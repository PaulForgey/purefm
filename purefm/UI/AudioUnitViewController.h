//
//  AudioUnitViewController.h
//  purefm
//
//  Created by Paul Forgey on 4/6/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <CoreAudioKit/CoreAudioKit.h>
#import "Envelope.h"
#import "State.h"
#import "Importer.h"

@interface AudioUnitViewController : AUViewController <AUAudioUnitFactory>

@property (nonatomic) Envelope *envelope; // copyable envelope, if selected
@property Envelope *envelopeClip;
@property (nonatomic,readonly) State *state;
@property (nonatomic,readonly) NSArray< ImportNode * > *imports;

@end
