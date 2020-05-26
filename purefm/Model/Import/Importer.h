//
//  Importer.h
//  purefm
//
//  Created by Paul Forgey on 5/20/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "State.h"

NS_ASSUME_NONNULL_BEGIN

@interface ImportNode : NSObject< NSCoding >

@property NSString *name;
@property (nonatomic,readonly) NSMutableArray< ImportNode * > *patches;

@end

@interface ImportedPatch : ImportNode

- (void)applyTo:(State *)state;

@end

@interface Importer : ImportNode

+ (Importer *)importerWithData:(NSData *)data error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
