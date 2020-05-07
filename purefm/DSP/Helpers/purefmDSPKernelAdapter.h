//
//  purefmDSPKernelAdapter.h
//  purefm
//
//  Created by Paul Forgey on 4/6/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

#ifdef __cplusplus
# import "globals.hpp"
#endif // __cplusplus

@class AudioUnitViewController;

NS_ASSUME_NONNULL_BEGIN

@interface purefmDSPKernelAdapter : NSObject

@property (nonatomic) AUAudioFrameCount maximumFramesToRender;
@property (nonatomic, readonly) AUAudioUnitBus *inputBus;
@property (nonatomic, readonly) AUAudioUnitBus *outputBus;

#ifdef __cplusplus
- (void)setPatch:(patch_ptr::pointer const &)patch;
#endif // __cplusplus

- (void)allocateRenderResources;
- (void)deallocateRenderResources;
- (AUInternalRenderBlock)internalRenderBlock;

@end

NS_ASSUME_NONNULL_END
