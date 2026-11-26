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

#import <GameplayKit/GameplayKitBase.h>

@class GKEntity;

// A piece of behaviour or data attached to an entity.
@interface GKComponent : NSObject <NSCopying, NSSecureCoding> {
    GKEntity *_entity; // not retained: the entity owns its components
}

@property (nonatomic, readonly, assign) GKEntity *entity;

- (void)updateWithDeltaTime:(NSTimeInterval)seconds;
- (void)didAddToEntity;
- (void)willRemoveFromEntity;

@end

// Updates all components of one class together.
@interface GKComponentSystem<ComponentType : GKComponent *> : NSObject <NSFastEnumeration> {
    Class _componentClass;
    NSMutableArray *_components;
}

@property (nonatomic, readonly) Class componentClass;
@property (nonatomic, readonly, retain) NSArray<ComponentType> *components;

- (ComponentType)objectAtIndexedSubscript:(NSUInteger)idx;
- (instancetype)initWithComponentClass:(Class)cls;
- (void)addComponent:(ComponentType)component;
- (void)addComponentWithEntity:(GKEntity *)entity;
- (void)removeComponentWithEntity:(GKEntity *)entity;
- (void)removeComponent:(ComponentType)component;
- (void)updateWithDeltaTime:(NSTimeInterval)seconds;
- (Class)classForGenericArgumentAtIndex:(NSUInteger)index;

@end
