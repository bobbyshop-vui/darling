/*
 This file is part of Darling.

 Copyright (C) 2026 Darling developers

 Darling is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Darling is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Darling.  If not, see <http://www.gnu.org/licenses/>.
*/

#import "GKPrivate.h"

@implementation GKScene

+ (BOOL)supportsSecureCoding
{
    return YES;
}

+ (instancetype)sceneWithFileNamed:(NSString *)filename
{
    return [self sceneWithFileNamed:filename rootNode:nil];
}

// A scene archived to a file in the main bundle (with or without its
// extension; GameplayKit scenes saved by Xcode use .sks).
+ (instancetype)sceneWithFileNamed:(NSString *)filename rootNode:(id<GKSceneRootNodeType>)rootNode
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = nil;
    if ([[filename pathExtension] length] > 0)
        path = [bundle pathForResource:[filename stringByDeletingPathExtension] ofType:[filename pathExtension]];
    if (path == nil)
        path = [bundle pathForResource:filename ofType:@"sks"];
    if (path == nil && [[NSFileManager defaultManager] fileExistsAtPath:filename])
        path = filename;
    if (path == nil)
        return nil;

    id object = nil;
    @try
    {
        object = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    }
    @catch (NSException *exception)
    {
        return nil;
    }
    if (![object isKindOfClass:[GKScene class]])
        return nil;
    if (rootNode != nil)
        [object setRootNode:rootNode];
    return object;
}

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _entities = [[NSMutableArray alloc] init];
        _graphs = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_entities release];
    [_graphs release];
    [_rootNode release];
    [super dealloc];
}

- (NSArray *)entities
{
    return [[_entities copy] autorelease];
}

- (NSDictionary *)graphs
{
    return [[_graphs copy] autorelease];
}

- (id<GKSceneRootNodeType>)rootNode
{
    return _rootNode;
}

- (void)setRootNode:(id<GKSceneRootNodeType>)rootNode
{
    [rootNode retain];
    [_rootNode release];
    _rootNode = rootNode;
}

- (void)addEntity:(GKEntity *)entity
{
    if (entity != nil && [_entities indexOfObjectIdenticalTo:entity] == NSNotFound)
        [_entities addObject:entity];
}

- (void)removeEntity:(GKEntity *)entity
{
    [_entities removeObjectIdenticalTo:entity];
}

- (void)addGraph:(GKGraph *)graph name:(NSString *)name
{
    if (graph != nil && name != nil)
        [_graphs setObject:graph forKey:name];
}

- (void)removeGraph:(NSString *)name
{
    if (name != nil)
        [_graphs removeObjectForKey:name];
}

- (id)copyWithZone:(NSZone *)zone
{
    GKScene *copy = [[[self class] allocWithZone:zone] init];
    [copy->_entities addObjectsFromArray:_entities];
    [copy->_graphs addEntriesFromDictionary:_graphs];
    [copy setRootNode:_rootNode];
    return copy;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [self init];
    if (self != nil)
    {
        for (id entity in GKArrayFromCollection(GKDecodeObject(coder, @"_entities")))
        {
            if ([entity isKindOfClass:[GKEntity class]])
                [_entities addObject:entity];
        }
        id graphs = GKDecodeObject(coder, @"_graphs");
        if ([graphs isKindOfClass:[NSDictionary class]])
            [_graphs addEntriesFromDictionary:graphs];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_entities forKey:@"_entities"];
    [coder encodeObject:_graphs forKey:@"_graphs"];
}

@end
