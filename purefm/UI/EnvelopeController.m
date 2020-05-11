//
//  EnvelopeController.m
//  purefm
//
//  Created by Paul Forgey on 5/9/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "EnvelopeController.h"
#import "Envelope.h"
#import "EnvelopeStage.h"
#import "EnvelopeView.h"
#import "DurationFormatter.h"
#import "LevelFormatter.h"
#import "PitchFormatter.h"

@interface EnvelopeController () {
    double _sampleRate;
    BOOL _pitch;
}

@property (strong) IBOutlet DurationFormatter *durationFormatter;
@property (strong) IBOutlet LevelFormatter *levelFormatter;
@property (strong) IBOutlet PitchFormatter *pitchFormatter;
@property (weak) IBOutlet EnvelopeView *envelopeView;
@property (strong) IBOutlet NSArrayController *stages;
@property (weak) IBOutlet NSTextField *durationLabel;
@property (weak) IBOutlet NSTextField *pitchLabel;

@end

@implementation EnvelopeController

@synthesize sampleRate = _sampleRate;
@synthesize pitch = _pitch;

// MARK: init

+ (EnvelopeController *)envelopeController {
    return [[EnvelopeController alloc] initWithNibName:@"EnvelopeController" bundle:nil];
}

// MARK: properties

- (void)setSampleRate:(double)sampleRate {
    _sampleRate = sampleRate;
    self.durationFormatter.sampleRate = sampleRate;
}

- (void)setPitch:(BOOL)pitch {
    _pitch = pitch;
    if (pitch) {
        self.pitchLabel.formatter = self.pitchFormatter;
        self.stages.objectClass = [PitchStage class];
    } else {
        self.pitchLabel.formatter = nil;
        self.stages.objectClass = [EnvelopeStage class];
    }
    self.pitchLabel.needsDisplay = YES;
}

// MARK: view

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (object == self.durationFormatter) {
        self.durationLabel.needsDisplay = YES;
    }
    else if (object == self.pitchFormatter) {
        self.pitchLabel.needsDisplay = YES;
    } else {
        return [super observeValueForKeyPath:keyPath
                                    ofObject:object
                                      change:change
                                     context:context];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];

    [self.envelopeView bind:@"stages"
                   toObject:self.stages
                withKeyPath:@"arrangedObjects"
                    options:nil];

    [self.envelopeView bind:@"playingStage"
                   toObject:self
                withKeyPath:@"envelope.playingStage"
                    options:nil];

    [self.envelopeView bind:@"keyUp"
                   toObject:self
                withKeyPath:@"envelope.keyUp"
                    options:nil];

    [self.durationFormatter bind:@"linearity"
                        toObject:self.stages
                     withKeyPath:@"selection.linearity"
                         options:nil];

    [self.pitchFormatter bind:@"scale"
                     toObject:self
                  withKeyPath:@"envelope.scale"
                      options:nil];

    [self.durationFormatter addObserver:self
                             forKeyPath:@"reformat"
                                options:NSKeyValueObservingOptionNew
                                context:NULL];

    [self.pitchFormatter addObserver:self
                          forKeyPath:@"reformat"
                             options:NSKeyValueObservingOptionNew
                             context:NULL];
}

// MARK: actions

- (IBAction)clickedKeyUp:(id)sender {
    if (self.envelope != nil) {
        NSUInteger index = self.stages.selectionIndexes.firstIndex;
        if (self.envelope.keyUp == index) {
            self.envelope.keyUp = NSNotFound;
        } else {
            self.envelope.keyUp = index;
        }
        self.envelopeView.needsDisplay = YES;
    }
}

- (IBAction)copyEnvelope:(id)sender {
    if (self.envelope != nil) {
        self.clip = [self.envelope copy];
    }
}

- (IBAction)pasteEnvelope:(id)sender {
    if (self.clip != nil) {
        Envelope *e;
        for (e in self.multiSelect) {
            [e replace:self.clip];
        }
        self.envelopeView.needsDisplay = YES;
    }
}

- (IBAction)updateStage:(id)sender {
    self.envelopeView.needsDisplay = YES;
}

@end
