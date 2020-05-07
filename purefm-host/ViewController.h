//
//  ViewController.h
//  purefm-host
//
//  Created by Paul Forgey on 4/6/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : NSViewController

@property (weak) IBOutlet NSView *extensionView;

@property AVAudioUnit *audioUnit;
@property AVAudioEngine *engine;

@end

