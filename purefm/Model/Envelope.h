//
//  Envelope.h
//  purefm
//
//  Created by Paul Forgey on 4/14/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnvelopeStage.h"

#ifdef __cplusplus
# import "globals.hpp"
#endif // __cplusplus

NS_ASSUME_NONNULL_BEGIN

@interface Envelope : NSObject< NSCoding >

@property (nonatomic,readonly) NSArray< EnvelopeStage * > *stages;
@property (nonatomic) NSUInteger keyUp;
@property (nonatomic) BOOL loop;
@property (nonatomic) int expr;
@property (nonatomic) int lfo;
@property (nonatomic) int bend;     // pitch envelope
@property (nonatomic) int scale;    // pitch envelope

+ (void)clampScaleValue:(id _Nullable * _Nonnull)ioValue max:(int)max;

- (id)init;
- (id)initDefaultOp;
- (void)replace:(Envelope *)from;
- (void)toggleKeyUp:(NSUInteger)index;

#ifdef __cplusplus
- (env_patch_ptr::pointer const &)patch;
#endif // __cplusplus

@end

NS_ASSUME_NONNULL_END
