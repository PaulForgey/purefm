//
//  AlgoView.h
//  purefm
//
//  Created by Paul Forgey on 4/8/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Operator.h"

NS_ASSUME_NONNULL_BEGIN

@interface AlgoView : NSControl

@property (nonatomic) NSIndexSet *selectionIndexes;
@property (nonatomic) NSArray< Operator * > *operators;
@property (nonatomic,nullable) Operator *feedback;

@end

NS_ASSUME_NONNULL_END
