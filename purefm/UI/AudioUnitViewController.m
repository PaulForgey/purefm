//
//  AudioUnitViewController.m
//  purefm
//
//  Created by Paul Forgey on 4/6/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "AudioUnitViewController.h"
#import "purefmAudioUnit.h"
#import "AlgoView.h"
#import "EnvelopeView.h"
#import "DurationFormatter.h"
#import "FrequencyFormatter.h"
#import "PitchFormatter.h"

@interface AudioUnitViewController ()
@property (weak) IBOutlet NSView *view; // XCode's xib editor doesn't see us as an NSViewController
@property (strong) IBOutlet DurationFormatter *durationFormatter;
@property (strong) IBOutlet DurationFormatter *LFODurationFormatter;
@property (strong) IBOutlet DurationFormatter *pitchDurationFormatter;
@property (strong) IBOutlet FrequencyFormatter *frequencyFormatter;
@property (strong) IBOutlet PitchFormatter *pitchFormatter;
@property (weak) IBOutlet AlgoView *algoView;
@property (weak) IBOutlet EnvelopeView *envelopeView;
@property (weak) IBOutlet EnvelopeView *LFOEnvelopeView;
@property (weak) IBOutlet EnvelopeView *pitchEnvelopeView;
@property (strong) IBOutlet NSArrayController *operatorsController;
@property (strong) IBOutlet NSArrayController *envelopeStageController;
@property (strong) IBOutlet NSArrayController *LFOStageController;
@property (strong) IBOutlet NSArrayController *pitchStageController;
@property (weak) IBOutlet NSTextField *levelText;
@property (weak) IBOutlet NSTextField *durationText;
@property (weak) IBOutlet NSTextField *LFODurationText;
@property (weak) IBOutlet NSTextField *frequencyField;
@property (weak) IBOutlet NSTextField *pitchDurationText;
@property (weak) IBOutlet NSTextField *pitchLevelText;

@end

@implementation AudioUnitViewController {
    purefmAudioUnit *_audioUnit;
    Envelope *_envelopeClip;
    Envelope *_envelope;
    Envelope *_pitchEnvelope;
    State *_state;
}

@dynamic view;
@synthesize envelopeClip = _envelopeClip;
@synthesize envelope = _envelope;
@synthesize state = _state;

#pragma mark properties

- (void) setAudioUnit:(purefmAudioUnit *)unit {
    _audioUnit = unit;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isViewLoaded]) {
            [self connectView];
        }
    });
}

- (purefmAudioUnit *) audioUnit {
    return _audioUnit;
}

#pragma mark view

- (void) viewDidLoad {
    self.preferredContentSize = self.view.frame.size;
    if (_audioUnit != nil) {
        [self connectView];
    }

    [super viewDidLoad];
}

- (void)updateState {
    [self willChangeValueForKey:@"state"];
    _state = self.audioUnit.state;
    [self didChangeValueForKey:@"state"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"state"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateState];
        });
    } else if (object == _durationFormatter) {
        self.durationText.needsDisplay = YES;
    } else if (object == _pitchDurationFormatter) {
        self.pitchDurationText.needsDisplay = YES;
    } else if (object == _frequencyFormatter){
        self.frequencyField.needsDisplay = YES;
    } else if (object == _pitchFormatter){
        self.pitchLevelText.needsDisplay = YES;
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

- (void) connectView {
    [self updateState];

    [self.audioUnit addObserver:self
                     forKeyPath:@"state"
                        options:NSKeyValueObservingOptionNew
                        context:NULL];

    [self.durationFormatter addObserver:self
                             forKeyPath:@"reformat"
                                options:NSKeyValueObservingOptionNew
                                context:NULL];

    [self.frequencyFormatter addObserver:self
                              forKeyPath:@"reformat"
                                 options:NSKeyValueObservingOptionNew
                                 context:NULL];

    [self.pitchDurationFormatter addObserver:self
                                  forKeyPath:@"reformat"
                                     options:NSKeyValueObservingOptionNew
                                     context:NULL];

    [self.pitchFormatter addObserver:self
                          forKeyPath:@"reformat"
                             options:NSKeyValueObservingOptionNew
                             context:NULL];

    [self.algoView bind:@"operators"
               toObject:self
            withKeyPath:@"state.operators"
                options:nil];

    // do not bind through this one (it's a silly hack)
    [self bind:@"envelope" toObject:self.operatorsController
                        withKeyPath:@"selection.envelope"
                            options:nil];

    [self.envelopeView bind:@"stages"
                   toObject:self.envelopeStageController
                withKeyPath:@"arrangedObjects"
                    options:nil];

    [self.envelopeView bind:@"keyUp"
                   toObject:self.operatorsController
                withKeyPath:@"selection.envelope.keyUp"
                    options:nil];

    [self.LFOEnvelopeView bind:@"stages"
                      toObject:self.LFOStageController
                   withKeyPath:@"arrangedObjects"
                       options:nil];

    [self.LFOEnvelopeView bind:@"keyUp"
                      toObject:self.state.lfo.envelope
                   withKeyPath:@"keyUp"
                       options:nil];

    [self.pitchEnvelopeView bind:@"stages"
                        toObject:self.pitchStageController
                     withKeyPath:@"arrangedObjects"
                         options:nil];

    [self.pitchEnvelopeView bind:@"keyUp"
                        toObject:self.state.pitchEnvelope
                     withKeyPath:@"keyUp"
                         options:nil];

    [self.durationFormatter bind:@"sampleRate"
                        toObject:self
                     withKeyPath:@"audioUnit.envelopeRate"
                         options:nil];

    [self.durationFormatter bind:@"linearity"
                        toObject:self.envelopeStageController
                     withKeyPath:@"selection.linearity"
                         options:nil];

    [self.LFODurationFormatter bind:@"sampleRate"
                           toObject:self
                        withKeyPath:@"audioUnit.LFORate"
                            options:nil];

    [self.LFODurationFormatter bind:@"linearity"
                           toObject:self.LFOStageController
                        withKeyPath:@"selection.linearity"
                            options:nil];

    [self.pitchDurationFormatter bind:@"sampleRate"
                             toObject:self
                          withKeyPath:@"audioUnit.envelopeRate"
                              options:nil];

    [self.pitchDurationFormatter bind:@"linearity"
                             toObject:self.pitchStageController
                          withKeyPath:@"selection.linearity"
                              options:nil];

    [self.pitchFormatter bind:@"scale"
                     toObject:self.state.pitchEnvelope
                  withKeyPath:@"scale"
                      options:nil];

    [self.frequencyFormatter bind:@"fixed"
                     toObject:self.operatorsController
                  withKeyPath:@"selection.fixed"
                      options:nil];


    self.pitchDurationFormatter.linearity = kLinearity_Pitch;
}

#pragma mark actions

- (IBAction)algoChanged:(id)sender {
    [self.state willChangeValueForKey:@"operators"];
    [self.state didChangeValueForKey:@"operators"];
    [_audioUnit updatePatch];
}

- (IBAction)envelopeStageChanged:(id)sender {
    self.envelopeView.needsDisplay = YES;
    self.LFOEnvelopeView.needsDisplay = YES;
    self.pitchEnvelopeView.needsDisplay = YES;
}

- (IBAction)clickedKeyUp:(id)sender {
    if (_envelope != nil) {
        NSUInteger index = _envelopeView.selectionIndexes.firstIndex;
        if (_envelope.keyUp == index) {
            self.envelope.keyUp = NSNotFound;
        } else {
            self.envelope.keyUp = index;
        }
    }
}

- (IBAction)clickedLFOKeyUp:(id)sender {
    NSUInteger index = _LFOEnvelopeView.selectionIndexes.firstIndex;
    [self.state.lfo.envelope toggleKeyUp:index];
}

- (IBAction)clickedPitchKeyUp:(id)sender {
    NSUInteger index = _pitchEnvelopeView.selectionIndexes.firstIndex;
    [self.state.pitchEnvelope toggleKeyUp:index];
}

- (IBAction)copyEnvelope:(id)sender {
    if (_envelope != nil) {
        self.envelopeClip = [_envelope copy];
    }
}

- (IBAction)pasteEnvelope:(id)sender {
    if (_envelopeClip == nil) {
        return;
    }

    NSUInteger i;
    for (i = 0; i < 8; ++i) {
        if ([_operatorsController.selectionIndexes containsIndex:i]) {
            [self.state.operators[i].envelope replace:_envelopeClip];
        }
    }
}

- (IBAction)fixedChanged:(id)sender {
    self.frequencyField.needsDisplay = YES;
}

- (IBAction)enabledChanged:(id)sender {
    self.algoView.needsDisplay = YES;
}

#pragma mark factory

- (AUAudioUnit *)createAudioUnitWithComponentDescription:(AudioComponentDescription)desc error:(NSError **)error {
    self.audioUnit = [[purefmAudioUnit alloc] initWithComponentDescription:desc error:error];
    return _audioUnit;
}

@end
