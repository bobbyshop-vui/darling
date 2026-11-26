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

@implementation GKEntity

+ (BOOL)supportsSecureCoding
{
    return YES;
}

+ (instancetype)entity
{
    return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
    self = [super init];
    if (self != nil)
        _components = [[NSMutableArray alloc] init];
    return self;
}

- (void)dealloc
{
    for (GKComponent *component in _components)
        [component _setEntity:nil];
    [_components release];
    [super dealloc];
}

- (NSArray *)components
{
    return [[_components copy] autorelease];
}

- (GKComponent *)componentForClass:(Class)componentClass
{
    for (GKComponent *component in _components)
    {
        if ([component class] == componentClass)
            return component;
    }
    return nil;
}

// An entity has at most one component of each class, and a component
// belongs to one entity: adding replaces both.
- (void)addComponent:(GKComponent *)component
{
    if (component == nil || [_components indexOfObjectIdenticalTo:component] != NSNotFound)
        return;
    [component retain];
    [self removeComponentForClass:[component class]];
    [[component entity] removeComponentForClass:[component class]];
    [_components addObject:component];
    [component _setEntity:self];
    [component didAddToEntity];
    [component release];
}

- (void)removeComponentForClass:(Class)componentClass
{
    GKComponent *component = [self componentForClass:componentClass];
    if (component == nil)
        return;
    [component retain];
    [component willRemoveFromEntity];
    [component _setEntity:nil];
    [_components removeObjectIdenticalTo:component];
    [component release];
}

- (void)updateWithDeltaTime:(NSTimeInterval)seconds
{
    for (GKComponent *component in [[_components copy] autorelease])
        [component updateWithDeltaTime:seconds];
}

- (id)copyWithZone:(NSZone *)zone
{
    GKEntity *copy = [[[self class] allocWithZone:zone] init];
    for (GKComponent *component in _components)
    {
        GKComponent *componentCopy = [component copyWithZone:zone];
        [copy addComponent:componentCopy];
        [componentCopy release];
    }
    return copy;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [self init];
    if (self != nil)
    {
        for (id component in GKArrayFromCollection(GKDecodeObject(coder, @"_components")))
        {
            if ([component isKindOfClass:[GKComponent class]])
                [self addComponent:component];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_components forKey:@"_components"];
}

@end
