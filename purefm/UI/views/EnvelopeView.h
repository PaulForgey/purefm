//
//  EnvelopeView.h
//  purefm
//
//  Created by Paul Forgey on 4/14/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Envelope.h"
#import "EnvelopeStage.h"

NS_ASSUME_NONNULL_BEGIN

@interface EnvelopeView : NSControl

@property (nonatomic,nullable) NSArray< EnvelopeStage * > *stages;
@property (nonatomic) NSUInteger keyUp;
@property (nonatomic) NSIndexSet *selectionIndexes;
@property (nonatomic) int playingStage;

@end

NS_ASSUME_NONNULL_END
