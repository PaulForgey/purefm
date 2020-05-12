//
//  FrequencyFormatter.h
//  purefm
//
//  Created by Paul Forgey on 4/26/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <Foundation/Foundation.h>

// displays and parses frequency parameter in pitch units as hz

NS_ASSUME_NONNULL_BEGIN

@interface FrequencyFormatter : NSFormatter

@property (nonatomic,readonly) BOOL reformat;
@property (nonatomic) BOOL fixed;
@property (nonatomic) BOOL lfo;

@end

NS_ASSUME_NONNULL_END
