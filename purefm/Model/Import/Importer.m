//
//  Importer.m
//  purefm
//
//  Created by Paul Forgey on 5/20/20.
//  Copyright © 2020 Paul Forgey. All rights reserved.
//

#import "Importer.h"
#import "YamahaImporter.h"

@implementation ImportNode {
    NSMutableArray< ImportNode * > *_patches;
}

@synthesize patches = _patches;

- (NSMutableArray< ImportNode * > *)patches {
    if (_patches == nil) {
        _patches = [[NSMutableArray alloc] init];
    }
    return _patches;
}

- (id)initWithCoder:(NSCoder *)coder {
    NSAssert(NO, @"base initWithCode called");
    return [super init];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    NSAssert(NO, @"base encodeWithCoder called");
}

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

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    self.name = [coder decodeObjectForKey:@"name"];
    [self.patches addObjectsFromArray:[coder decodeObjectForKey:@"patches"]];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.patches forKey:@"patches"];
}

@end
