//
//  NoteFormatter.m
//  purefm
//
//  Created by Paul Forgey on 4/26/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "NoteFormatter.h"
#import <ctype.h>

static char const *notes[12] = {
    "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
};

@implementation NoteFormatter

// XXX middle-c (midi 60) is octave "0"

- (NSString *)stringForObjectValue:(id)obj {
    int v = [obj intValue];

    int octave = (v / 12) - 5;
    int note = v % 12;

    return [NSString stringWithFormat:@"%s%d", notes[note], octave];
}

- (BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj forString:(NSString *)string errorDescription:(out NSString * _Nullable __autoreleasing *)error {
    char const *s = string.UTF8String;

    if (!isalpha(s[0])) {
        return NO;
    }

    int note = 0, octave = 0;

    switch (s[0]) {
    case 'c':
    case 'C':
        note = 0;
        break;
    case 'd':
    case 'D':
        note = 2;
        break;
    case 'e':
    case 'E':
        note = 4;
        break;
    case 'f':
    case 'F':
        note = 5;
        break;
    case 'g':
    case 'G':
        note = 7;
        break;
    case 'a':
    case 'A':
        note = 9;
        break;
    case 'b':
    case 'B':
        note = 11;
        break;
    default:
        return NO;
    }
    s++;

    if (*s == '#' || *s == '+') {
        note++;
        s++;
    }

    int neg = 0;

    if (*s == '-') {
        neg = 1;
        s++;
    }

    if (isnumber(*s)) {
        octave = *s - '0';
    }

    if (neg) {
        octave = -octave;
    }

    int value = 60 + (12 * octave) + note;
    *obj = @(value);

    return YES;
}

@end
