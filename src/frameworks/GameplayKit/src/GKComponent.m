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

id GKDecodeObject(NSCoder *coder, NSString *key)
{
    if (![coder containsValueForKey:key])
        return nil;
    if (![coder requiresSecureCoding])
        return [coder decodeObjectForKey:key];
    NSSet *classes = [NSSet setWithObjects:[NSArray class], [NSDictionary class],
            [NSSet class], [NSString class], [NSNumber class], [NSData class],
            [NSIndexPath class], [GKEntity class], [GKComponent class],
            [GKGraph class], [GKGraphNode class], [GKObstacle class], nil];
    return [coder decodeObjectOfClasses:classes forKey:key];
}

NSArray *GKArrayFromCollection(id collection)
{
    if ([collection isKindOfClass:[NSArray class]])
        return collection;
    if ([collection isKindOfClass:[NSDictionary class]])
        return [collection allValues];
    if ([collection isKindOfClass:[NSSet class]] ||
        [collection isKindOfClass:[NSOrderedSet class]])
        return [collection allObjects];
    return [NSArray array];
}

@implementation GKComponent

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (GKEntity *)entity
{
    return _entity;
}

- (void)_setEntity:(GKEntity *)entity
{
    _entity = entity;
}

- (void)updateWithDeltaTime:(NSTimeInterval)seconds
{
}

- (void)didAddToEntity
{
}

- (void)willRemoveFromEntity
{
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] init];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    return [super init];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:NSStringFromClass([self class]) forKey:@"_componentName"];
}

@end

@implementation GKComponentSystem

- (instancetype)initWithComponentClass:(Class)cls
{
    self = [super init];
    if (self != nil)
    {
        _componentClass = cls;
        _components = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_components release];
    [super dealloc];
}

- (Class)componentClass
{
    return _componentClass;
}

- (NSArray *)components
{
    return [[_components copy] autorelease];
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    return [_components objectAtIndex:idx];
}

- (void)addComponent:(GKComponent *)component
{
    if (component == nil || ![component isKindOfClass:_componentClass] ||
        [_components indexOfObjectIdenticalTo:component] != NSNotFound)
        return;
    [_components addObject:component];
}

- (void)addComponentWithEntity:(GKEntity *)entity
{
    [self addComponent:[entity componentForClass:_componentClass]];
}

- (void)removeComponentWithEntity:(GKEntity *)entity
{
    GKComponent *component = [entity componentForClass:_componentClass];
    if (component != nil)
        [self removeComponent:component];
}

- (void)removeComponent:(GKComponent *)component
{
    [_components removeObjectIdenticalTo:component];
}

- (void)updateWithDeltaTime:(NSTimeInterval)seconds
{
    for (GKComponent *component in [[_components copy] autorelease])
        [component updateWithDeltaTime:seconds];
}

- (Class)classForGenericArgumentAtIndex:(NSUInteger)index
{
    return _componentClass;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)buffer count:(NSUInteger)len
{
    return [_components countByEnumeratingWithState:state objects:buffer count:len];
}

@end
