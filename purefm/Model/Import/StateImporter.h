//
//  StateImporter.h
//  purefm
//
//  Created by Paul Forgey on 5/23/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "Importer.h"
#import "State.h"

NS_ASSUME_NONNULL_BEGIN

@interface StatePatch : ImportedPatch< NSCoding >

@property NSData *data;

@end

@interface StateImporter : Importer

+ (StateImporter *)importerWithData:(NSData *)data error:(NSError **)error;

- (void)import:(NSData *)data;
- (void)addPatch:(State *)state;

@end

NS_ASSUME_NONNULL_END
