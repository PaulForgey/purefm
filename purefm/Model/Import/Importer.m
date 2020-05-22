//
//  Importer.m
//  purefm
//
//  Created by Paul Forgey on 5/20/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "Importer.h"
#import "YamahaImporter.h"

@implementation ImportNode

@end

@implementation ImportedPatch 

- (id)initWithName:(NSString *)name {
    self = [super init];
    self.name = name;
    return self;
}

- (BOOL)isLeaf {
    return YES;
}

- (NSMutableArray< ImportedPatch * > *)patches {
    return nil;
}

- (void)applyTo:(State *)state {
}

@end

@implementation Importer

+ (Importer *)importerWithData:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
    // try all the importers we know until one succeeds or fails but with a specific error set
    NSArray *classes = @[
        [YamahaImporter class],
    ];

    Importer *i = nil;
    NSError *e = nil;
    Class c;
    for (c in classes) {
        i = [c importerWithData:data error:&e];
        if (e != nil || i != nil) {
            break;
        }
    }

    if (error != nil && e != nil) {
        *error = e;
    }
    return i;
}

- (BOOL)isLeaf {
    return NO;
}

@end
