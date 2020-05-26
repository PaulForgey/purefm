//
//  AudioUnitViewController.m
//  purefm
//
//  Created by Paul Forgey on 4/6/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "AudioUnitViewController.h"
#import "EnvelopeController.h"
#import "purefmAudioUnit.h"
#import "AlgoView.h"
#import "EnvelopeView.h"
#import "DurationFormatter.h"
#import "FrequencyFormatter.h"
#import "PitchFormatter.h"
#import "StateImporter.h"

@interface AudioUnitViewController ()
@property (weak) IBOutlet NSView *view; // XCode's xib editor doesn't see us as an NSViewController
@property (strong) IBOutlet DurationFormatter *portamentoFormatter;
@property (strong) IBOutlet FrequencyFormatter *frequencyFormatter;
@property (weak) IBOutlet AlgoView *algoView;
@property (strong) IBOutlet NSArrayController *operatorsController;
@property (weak) IBOutlet NSTextField *frequencyField;
@property (weak) IBOutlet NSView *operatorEnvelopeView;
@property (weak) IBOutlet NSView *lfoEnvelopeView;
@property (weak) IBOutlet NSView *pitchEnvelopeView;
@property (weak) IBOutlet NSBrowser *importBrowser;
@property (strong) IBOutlet NSTreeController *importsController;

@end

@implementation AudioUnitViewController {
    purefmAudioUnit *_audioUnit;
    EnvelopeController *_operatorEnvelopeController;
    EnvelopeController *_lfoEnvelopeController;
    EnvelopeController *_pitchEnvelopeController;

    Envelope *_pitchEnvelope;
    State *_state;
    NSTimer *_refresh;
}

@dynamic view;
@synthesize state = _state;

// MARK: properties

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

// MARK: view

- (void)viewWillDisappear {
    [_refresh invalidate];
    _refresh = nil;
    [super viewWillDisappear];
}

- (void)viewWillAppear {
    _refresh = [NSTimer scheduledTimerWithTimeInterval:0.100
                                               repeats:YES
                                               block:^(NSTimer * _Nonnull timer) {
        [self.state updateStatus];
    }];

    [super viewWillAppear];
}

- (void)viewDidLoad {
    self.preferredContentSize = self.view.frame.size;
    _operatorEnvelopeController = [EnvelopeController envelopeController];
    [self.operatorEnvelopeView addSubview:_operatorEnvelopeController.view];
    _operatorEnvelopeController.hasClip = YES;

    _lfoEnvelopeController = [EnvelopeController envelopeController];
    [self.lfoEnvelopeView addSubview:_lfoEnvelopeController.view];

    _pitchEnvelopeController = [EnvelopeController envelopeController];
    [self.pitchEnvelopeView addSubview:_pitchEnvelopeController.view];
    _pitchEnvelopeController.pitch = YES;

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
    } else if (object == _frequencyFormatter){
        [[self frequencyField] abortEditing];
        self.frequencyField.needsDisplay = YES;
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

    [self.frequencyFormatter addObserver:self
                              forKeyPath:@"reformat"
                                 options:NSKeyValueObservingOptionNew
                                 context:NULL];

    [self.algoView bind:@"operators"
               toObject:self
            withKeyPath:@"state.operators"
                options:nil];

    // do not bind through this one; it's a silly hack to avoid multiple selection
    [self bind:@"envelope" toObject:self.operatorsController
                        withKeyPath:@"selection.envelope"
                            options:nil];

    [_operatorEnvelopeController bind:@"envelope"
                             toObject:self
                          withKeyPath:@"envelope"
                              options:nil];

    [_operatorEnvelopeController bind:@"sampleRate"
                             toObject:self
                          withKeyPath:@"audioUnit.envelopeRate"
                              options:nil];

    [_operatorEnvelopeController bind:@"multiSelect"
                             toObject:self.operatorsController
                          withKeyPath:@"selectedObjects.@unionOfObjects.envelope"
                              options:nil];

    [_lfoEnvelopeController bind:@"envelope"
                        toObject:self
                     withKeyPath:@"state.lfo.envelope"
                         options:nil];

    [_lfoEnvelopeController bind:@"sampleRate"
                        toObject:self
                     withKeyPath:@"audioUnit.lfoRate"
                         options:nil];

    [_pitchEnvelopeController bind:@"envelope"
                          toObject:self
                       withKeyPath:@"state.pitchEnvelope"
                           options:nil];

    [_pitchEnvelopeController bind:@"sampleRate"
                          toObject:self
                       withKeyPath:@"audioUnit.envelopeRate"
                           options:nil];

    [self.portamentoFormatter bind:@"sampleRate"
                          toObject:self
                       withKeyPath:@"audioUnit.envelopeRate"
                           options:nil];

    [self.frequencyFormatter bind:@"fixed"
                     toObject:self.operatorsController
                  withKeyPath:@"selection.fixed"
                      options:nil];

    self.portamentoFormatter.linearity = kLinearity_Pitch;
}

// MARK: actions

- (IBAction)algoChanged:(id)sender {
    [self.state willChangeValueForKey:@"operators"];
    [self.state didChangeValueForKey:@"operators"];
    [_audioUnit updatePatch];
}

- (IBAction)enabledChanged:(id)sender {
    self.algoView.needsDisplay = YES;
}

- (IBAction)save:(id)sender {
    [_audioUnit.stash addPatch:_state];
}

- (IBAction)openImport:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes = @[@"syx", @"SYX"];

    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK) {
            return;
        }

        Importer *n = nil;
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfURL:panel.URL
                                             options:0
                                               error:&error];

        if (data == nil) {
            [[NSAlert alertWithError:error] runModal];
        } else {
            n = [Importer importerWithData:data error:&error];
            if (n != nil) {
                NSArray *paths = panel.URL.pathComponents;
                n.name = [paths lastObject];
                [self.audioUnit addImport:n];
            }
        }
    }];
}

- (IBAction)load:(id)sender {
    NSArray< ImportedPatch * > *selected = [self.importsController selectedObjects];
    if ([selected count] == 1) {
        [selected[0] applyTo:_state];
        [_audioUnit updatePatch];
        [_algoView arrange];
        _algoView.needsDisplay = YES;
    }
}

// MARK: factory

- (AUAudioUnit *)createAudioUnitWithComponentDescription:(AudioComponentDescription)desc error:(NSError **)error {
    self.audioUnit = [[purefmAudioUnit alloc] initWithComponentDescription:desc error:error];
    return _audioUnit;
}

@end
