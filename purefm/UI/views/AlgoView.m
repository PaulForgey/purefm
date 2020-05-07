//
//  AlgoView.m
//  purefm
//
//  Created by Paul Forgey on 4/8/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "AlgoView.h"
#import "OperatorView.h"
#import "Operator.h"

@implementation AlgoView {
    // private
    OperatorView *operatorViews[8];     // operators
    OperatorView *phaseViews[8];        // phase targets
    OperatorView *sumViews[8];          // sum targets
    Operator *_feedback;                 // feedback input op, if any

    // properties
    NSIndexSet *_selectionIndexes;              // current selection
    NSArray< Operator * > *_operators;  // what we are editing
}

- (void)setSelectionIndexes:(NSIndexSet *)set {
    _selectionIndexes = set;
    // select the operators according to the index set
    NSUInteger n;
    for (n = 0; n < 8; ++n) {
        operatorViews[n].intValue = (int)[_selectionIndexes containsIndex:n];
    }
}

- (NSIndexSet *)selectionIndexes {
    return _selectionIndexes;
}

- (NSArray< Operator * > *)operators {
    return _operators;
}

- (void)setOperators:(NSArray<Operator *> *)operators {
    _operators = operators;
    self.feedback = nil;

    NSAssert([operators count] == 8, @"count is %lu, not 8", [operators count]);

    int n;
    for (n = 0; n < 8; ++n) {
        int mod = _operators[n].mod;

        if (mod >= 0 && mod <= n) {
            self.feedback = _operators[n];
        }
        operatorViews[n].hidden = NO;
    }
    [self arrange];
}

- (void)awakeFromNib {
    [super awakeFromNib];

    int n;
    for (n = 0; n < 8; ++n) {
        OperatorView *operatorView = [[OperatorView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 30.0, 30.0)];
        operatorView.hidden = YES;
        operatorView.label = [NSString stringWithFormat:@"%d", n+1];
        operatorView.tag = (NSUInteger)n;
        operatorView.target = self;
        operatorView.action = @selector(clicked:);
        [self addSubview:operatorView];
        operatorViews[n] = operatorView;

        OperatorView *phaseView = [[OperatorView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 30.0, 15.0)];
        phaseView.hidden = YES;
        phaseView.label = @"ω";
        phaseView.tag = (NSUInteger)n;
        [self addSubview:phaseView];
        phaseViews[n] = phaseView;

        OperatorView *sumView = [[OperatorView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 15.0, 30.0)];
        sumView.hidden = YES;
        sumView.label = @"∑";
        sumView.tag = (NSUInteger)n;
        [self addSubview:sumView];
        sumViews[n] = sumView;
    }

    [self setSelectionIndexes:_selectionIndexes];
}

- (void)beginDrag:(id)sender event:(NSEvent *)event {
    int op = (int)((OperatorView *)sender).tag;
    int i;

    // non-feedback phase: if prior op has no modulator, it's available
    if (op > 0) {
        Operator *o = self.operators[op-1];

        if (o.mod == -1) {
            phaseViews[op-1].hidden = NO;
        } else if (o.mod == op) {
            // consecutive prior ops may also be us
            for (i = op-1; i >=0; i--) {
                o = self.operators[i];
                if (o.mod == -1) {
                    phaseViews[i].hidden = NO;
                    break;
                } else if (o.mod != op) {
                    break;
                }
            }
        }
    }
    // feedback phase: top of the stack is available
    for (i = op; i < 8; ++i) {
        Operator *o = self.operators[i];

        if (o.mod <= i) {
            phaseViews[i].hidden = NO;
            break;
        }
        if (o.mod != i+1) {
            break;
        }
    }

    // prior ops not summed
    for (i = op-1; i >= 0; i--) {
        Operator *o = self.operators[i];
        if (o.sum != i+1) {
            sumViews[i].hidden = NO;
        }
    }
}

- (void)highlightDrag:(NSPoint)pt opView:(OperatorView *)opView {
    if (!opView.hidden && [self mouse:pt inRect:opView.frame]) {
        opView.highlighted = YES;
    } else {
        opView.highlighted = NO;
    }
}

- (void)drag:(id)sender event:(NSEvent *)event {
    NSPoint pt = [self convertPoint:event.locationInWindow fromView:nil];

    int i;
    for (i = 0; i < 8; ++i) {
        [self highlightDrag:pt opView:phaseViews[i]];
        [self highlightDrag:pt opView:sumViews[i]];
    }
}

- (void)endDrag:(id)sender event:(NSEvent *)event {
    int i;
    int mod = -1, sum = -1;

    NSPoint pt = [self convertPoint:event.locationInWindow fromView:nil];
    int op = (int)((OperatorView *)sender).tag;

    for (i = 0; i < 8; ++i) {
        if (mod == -1 && !phaseViews[i].hidden && [self mouse:pt inRect:phaseViews[i].frame]) {
            mod = i;
        }
        if (sum == -1 && !sumViews[i].hidden && [self mouse:pt inRect:sumViews[i].frame]) {
            sum = i;
        }

        sumViews[i].hidden = YES;
        phaseViews[i].hidden = YES;
    }

    if (sum != -1) {
        [self sum:op sum:sum];
        [self sendAction:self.action to:self.target];
    }
    if (mod != -1) {
        [self mod:op mod:mod];
        [self sendAction:self.action to:self.target];
    }
}

- (void)sum:(int)op sum:(int)sum {
    Operator *operator;
    int i;

    // break any modulation paths through us and any prior summation to us
    for (i = 0; i < op; ++i) {
        operator = self.operators[i];
        if (operator.mod >= op) {
            operator.mod = -1;
        }
        if (operator.sum == op) {
            operator.sum = -1;
        }
    }
    for (i = op; i < 8; ++i) {
        operator = self.operators[i];
        if (operator.mod != -1 && operator.mod < op) {
            operator.mod = -1;
            self.feedback = nil;
        }
        if (operator.sum == op) {
            operator.sum = -1;
        }
    }

    // and hook it up
    operator = self.operators[sum];
    operator.sum = op;
    [self arrange];
}

- (void)mod:(int)op mod:(int)mod {
    Operator *operator = self.operators[mod];

    // break summation chain if next op is the new modulator
    if (operator.sum == op) {
        operator.sum = -1;
    }

    // mark new feedback
    if (op <= mod) {
        if (_feedback != nil) {
            _feedback.mod = -1;
        }
        self.feedback = operator;
    }

    // and hook it up
    operator.mod = op;

    [self arrange];
}

- (void)clicked:(id)sender {
    OperatorView *operatorView = (OperatorView *)sender;
    NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
    NSUInteger index = operatorView.tag;

    if (operatorView.mouseDownFlags & NSEventModifierFlagShift) {
        // select range
        if (_selectionIndexes != nil) {
            NSUInteger firstIndex = [_selectionIndexes firstIndex];
            NSUInteger length;
            if (firstIndex < index) {
                length = (index - firstIndex)+1;
            } else {
                length = (firstIndex - index)+1;
                firstIndex = index;
            }
            [set addIndexesInRange:NSMakeRange(firstIndex, length)];
        } else {
            [set addIndex:index];
        }
    }
    else if (operatorView.mouseDownFlags & NSEventModifierFlagCommand) {
        // toggle in existing selection set
        if (_selectionIndexes != nil) {
            [set addIndexes:_selectionIndexes];
        }
        if ([set containsIndex:index]) {
            [set removeIndex:index];
        } else {
            [set addIndex:index];
        }
    }
    else {
        // select single
        [set addIndex:index];
    }
    self.selectionIndexes = set;
}

// recursively position operator at row and column for its chain
// returns number of columns over to start next chain
- (int)arrange:(int)op row:(int)row column:(int)column {
    // row,column is at this point
    NSPoint pt = NSMakePoint(5.0+(float)column * 35.0, 5.0+(float)row * 35.0);
    // and move the operator to it
    [operatorViews[op] setFrameOrigin:pt];

    int width = 1; // we're taking up at least one
    Operator *o = self.operators[op];

    if (o.mod == op+1) {
        // place modulation chain above us
        // (if modulator is not next immediate operator, we're in a chain
        // of oeprators all modulated by it. Only do this for the last one)
        int n = [self arrange:o.mod row:row+1 column:column];
        width += n;
        column += n;

        if (row == 0) {
            // fix up summations in row 0
            int sum = op+1 +n;

            if (sum >= 8) {
                sum = -1;
            }
            o.sum = sum;
        }
    }

    if (op < 7 && row == 0 && o.mod == -1) {
        // fix up summations in row 0
        o.sum = op+1;
    }

    if (o.sum != -1) {
        // place next in summation chain
        width += [self arrange:o.sum row:row column:column+1];
    }

    // place the summation and phase buttons
    [phaseViews[op] setFrameOrigin:NSMakePoint(pt.x, pt.y+35.0)];
    [sumViews[op] setFrameOrigin:NSMakePoint(pt.x+35.0, pt.y)];

    return width;
}

// visually arrange the operators, as well as normalize bottom level sums
- (void)arrange {
    [self arrange:0 row:0 column:0];
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    int n;

    [super drawRect:dirtyRect];

    [[NSColor gridColor] setStroke];
    [NSBezierPath strokeRect:self.bounds];
    [[NSColor controlBackgroundColor] setFill];
    [NSBezierPath fillRect:self.bounds];

    NSBezierPath *grid = [NSBezierPath bezierPath];
    CGFloat const dashes[] = { 1.0, 2.0 };
    [grid setLineDash:dashes count:2 phase:0.0];
    for (n = 0; n < 9; ++n) {
        CGFloat z = 2.5+35.0*(CGFloat)n;

        [grid moveToPoint:NSMakePoint(z, 0.0)];
        [grid lineToPoint:NSMakePoint(z, 290.0)];

        [grid moveToPoint:NSMakePoint(0.0, z)];
        [grid lineToPoint:NSMakePoint(290.0, z)];
    }
    [grid stroke];

    if (_operators == nil) {
        return;
    }

    NSBezierPath *lines = [NSBezierPath bezierPath];
    [[NSColor textColor] setStroke];

    // draw connecting lines to modulators
    for (n = 0; n < 8; ++n) {
        Operator *op = self.operators[n];
        operatorViews[n].enabled = op.enabled;

        if (op.mod >= 0) {
            NSPoint to = [operatorViews[n] frame].origin;
            to.x += 15.0;
            to.y += 30.0;

            NSPoint from = [operatorViews[op.mod] frame].origin;
            from.x += 15.0;

            if (op.mod > n) {
                [lines moveToPoint:to];
                [lines lineToPoint:NSMakePoint(to.x, from.y-2.5)];
                [lines lineToPoint:NSMakePoint(from.x, from.y-2.5)];
                [lines lineToPoint:from];
            } else {
                [lines moveToPoint:to];
                [lines lineToPoint:NSMakePoint(to.x, to.y+2.5)];
                [lines lineToPoint:NSMakePoint(to.x+17.5, to.y+2.5)];
                [lines lineToPoint:NSMakePoint(to.x+17.5, from.y-2.5)];
                [lines lineToPoint:NSMakePoint(from.x, from.y-2.5)];
                [lines lineToPoint:from];
            }
        }
    }

    [lines stroke];
}

@end
