//
//  OperatorView.h
//  purefm
//
//  Created by Paul Forgey on 4/8/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface OperatorDragger

-(void)beginDrag:(id)sender event:(NSEvent *)event;
-(void)drag:(id)sender event:(NSEvent *)event;
-(void)endDrag:(id)sender event:(NSEvent *)event;

@end

@interface OperatorView : NSControl

@property (nonatomic) NSString *label;
@property (nonatomic) NSEventModifierFlags mouseDownFlags;

@end

