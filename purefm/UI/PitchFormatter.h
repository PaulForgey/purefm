//
//  PitchFormatter.h
//  purefm
//
//  Created by Paul Forgey on 4/27/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <Foundation/Foundation.h>

// displays pitch offset value from pitch envelope in octaves and steps
// display only

NS_ASSUME_NONNULL_BEGIN

@interface PitchFormatter : NSFormatter

@property (nonatomic,readonly) BOOL reformat;
@property (nonatomic) int scale;

@end

NS_ASSUME_NONNULL_END
