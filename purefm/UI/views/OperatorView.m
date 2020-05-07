//
//  OperatorView.m
//  purefm
//
//  Created by Paul Forgey on 4/8/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "OperatorView.h"

@implementation OperatorView {
    NSString *_label;
    BOOL tracking;
    BOOL dragging;
}

@synthesize mouseDownFlags;

- (BOOL)acceptsFirstResponder {
    return self.enabled;
}

- (void)setLabel:(NSString *)label {
    _label = label;
    self.needsDisplay = YES;
}

- (NSString *)label {
    return _label;
}

- (void)mouseDown:(NSEvent *)event {
    // XXX can still select a disabled operator
    self.mouseDownFlags = event.modifierFlags;
    self.highlighted = YES;
    self.needsDisplay = YES;
    tracking = YES;
}

- (void)mouseDragged:(NSEvent *)event {
    if (tracking) {
        if (!dragging) {
            dragging = YES;
            // alternative is a tight loop in mouseDown
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSCursor openHandCursor] push];
            });

            if (self.target != nil &&
                [self.target respondsToSelector:@selector(beginDrag:event:)]) {
                [self.target beginDrag:self event:event];
            }
        } else {
            if (self.target != nil &&
                [self.target respondsToSelector:@selector(drag:event:)]) {
                [self.target drag:self event:event];
            }
        }
    }
}

- (void)mouseUp:(NSEvent *)event {
    if (tracking) {
        self.highlighted = NO;
        self.needsDisplay = YES;
        tracking = NO;
        NSPoint pt = [self convertPoint:event.locationInWindow fromView:nil];
        if ([self mouse:pt inRect:[self bounds]]) {
            [self sendAction:self.action to:self.target];
        }
        if (dragging) {
            dragging = NO;
            [NSCursor pop];

            if (self.target != nil &&
                [self.target respondsToSelector:@selector(endDrag:event:)]) {
                [self.target endDrag:self event:event];
            }
        }
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSRect bounds = [self bounds];

    NSBezierPath *outline = [NSBezierPath bezierPathWithRoundedRect:bounds
                                                            xRadius:10
                                                            yRadius:10];

    [[NSColor gridColor] setStroke];

    NSColor *textColor;
    NSColor *fillColor;

    if (!self.enabled) {
        textColor = [NSColor disabledControlTextColor];
    }
    else if (self.highlighted || self.intValue != 0) {
        textColor = [NSColor selectedControlTextColor];
    }
    else {
        textColor = [NSColor controlTextColor];
    }

    if (self.highlighted || self.intValue != 0) {
        fillColor = [NSColor selectedControlColor];
    }
    else if (!self.enabled) {
        fillColor = [NSColor controlColor];
    }
    else {
        fillColor = [NSColor controlColor];
    }

    [fillColor setFill];
    [outline fill];
    [outline stroke];

    if (_label == nil) {
        return;
    }

    NSDictionary *attrs = @{
                            NSForegroundColorAttributeName: textColor,
                            NSFontAttributeName: [NSFont boldSystemFontOfSize:12.0],
                            };
    NSSize size = [_label sizeWithAttributes:attrs];
    [_label drawAtPoint:NSMakePoint((bounds.size.width/2-size.width/2),
                                    (bounds.size.height/2-size.height/2))
         withAttributes:attrs];
}

@end
