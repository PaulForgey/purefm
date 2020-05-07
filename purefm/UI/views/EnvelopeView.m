//
//  EnvelopeView.m
//  purefm
//
//  Created by Paul Forgey on 4/14/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "EnvelopeView.h"

@implementation EnvelopeView {
    NSUInteger _keyUp;
    NSArray< EnvelopeStage * > *_stages;
    NSIndexSet *_selectionIndexes;
    NSRect *parts;
    int partsLen;
}

- (void)dealloc {
    if (parts != NULL) {
        free(parts);
        parts = NULL;
    }
}

- (NSUInteger)keyUp {
    return _keyUp;
}

- (void)setKeyUp:(NSUInteger)keyUp {
    _keyUp = keyUp;
    self.needsDisplay = YES;
}

- (NSArray< EnvelopeStage * > *)stages {
    return _stages;
}

- (void)setStages:(NSArray<EnvelopeStage *> *)stages {
    _stages = stages;
    self.needsDisplay = YES;
}

- (NSIndexSet *)selectionIndexes {
    return _selectionIndexes;
}

- (void)setSelectionIndexes:(NSIndexSet *)selectionIndexes {
    _selectionIndexes = selectionIndexes;
    self.needsDisplay = YES;
}

- (void)mouseDown:(NSEvent *)event {
    if (parts == nil) {
        return;
    }

    NSPoint pt = [self convertPoint:event.locationInWindow fromView:nil];
    int i;

    for (i = 0; i < partsLen; ++i) {
        if ([self mouse:pt inRect:parts[i]]) {
            self.selectionIndexes = [NSIndexSet indexSetWithIndex:i];
            break;
        }
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    if (_stages == nil) {
        [self setBoundsSize:self.frame.size];
    }

    [[NSColor controlBackgroundColor] setFill];
    [NSBezierPath fillRect:self.bounds];
    [[NSColor gridColor] setStroke];
    [NSBezierPath strokeRect:self.bounds];

    if (_stages == nil) {
        return;
    }

    NSBezierPath *lines = [NSBezierPath bezierPath];
    NSArray< NSColor * > *colors = [NSColor alternatingContentBackgroundColors];
    [[NSColor textColor] setStroke];

    if (parts != nil) {
        free(parts);
    }
    partsLen = (int)[_stages count];
    parts = calloc(partsLen, sizeof(NSRect));

    NSPoint origin = self.bounds.origin;
    NSPoint pt = origin;
    float lastY = origin.y;
    int i;

    for (i = 0; i < partsLen; ++i) {
        EnvelopeStage *stage = _stages[i];
        NSRect segrect;
        segrect.origin = pt;
        float w = (float)stage.duration + 10.0;
        segrect.size = NSMakeSize(w, self.bounds.size.height);
        parts[i] = segrect;

        float y = ((float)stage.level / 127.0) * self.bounds.size.height;

        if (i == 0 && stage.linearity == kLinearity_Pitch) {
            lastY = (64.0 / 127.0) * self.bounds.size.height;
        }

        if (NSIntersectsRect(dirtyRect, segrect)) {
            if ([_selectionIndexes containsIndex:i]) {
                [[NSColor selectedControlColor] setFill];
            } else {
                [colors[i % [colors count]] setFill];
            }
            [NSBezierPath fillRect:segrect];

            NSBezierPath *line = [NSBezierPath bezierPath];
            if (_keyUp == i) {
                [[NSColor redColor] setStroke];
            } else {
                [[NSColor gridColor] setStroke];
            }
            [line moveToPoint:segrect.origin];
            [line lineToPoint:NSMakePoint(segrect.origin.x,
                                          segrect.origin.y + segrect.size.height)];
            [line stroke];
            [[NSColor textColor] setStroke];

            NSPoint from = NSMakePoint(pt.x, lastY);
            NSPoint to = NSMakePoint(pt.x+segrect.size.width, y);

            if (stage.linearity == kLinearity_Delay) {
                [lines moveToPoint:NSMakePoint(pt.x, y)];
            } else {
                [lines moveToPoint:from];
            }

            if (stage.linearity == kLinearity_Exp) {
                NSPoint pt1, pt2;

                if (to.y > from.y) {
                    pt1.x = to.x - ((to.x-from.x)/4.0);
                    pt2.x = to.x;
                } else {
                    pt1.x = from.x;
                    pt2.x = from.x + ((to.x-from.x)/4.0);
                }

                pt1.y = from.y;
                pt2.y = to.y;

                [lines curveToPoint:to controlPoint1:pt1 controlPoint2:pt2];
            } else {
                [lines lineToPoint:to];
            }
        }

        pt.x += segrect.size.width;
        lastY = y;
    }
    [lines stroke];
    [self setBoundsSize:NSMakeSize(pt.x, self.bounds.size.height)];
}

@end
