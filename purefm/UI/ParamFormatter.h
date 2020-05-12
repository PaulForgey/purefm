//
//  ParamFormatter.h
//  purefm
//
//  Created by Paul Forgey on 5/12/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <Foundation/Foundation.h>

// allows general params in MIDI range 0-127 to be entered in alternate
// ways

NS_ASSUME_NONNULL_BEGIN

@interface ParamFormatter : NSFormatter

@property BOOL invert;

@end

NS_ASSUME_NONNULL_END
