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

@class GKComponent;

// An object made of components; at most one component per class.
@interface GKEntity : NSObject <NSCopying, NSSecureCoding> {
    NSMutableArray *_components;
}

+ (instancetype)entity;
- (instancetype)init;

- (void)updateWithDeltaTime:(NSTimeInterval)seconds;

@property (nonatomic, readonly, retain) NSArray<GKComponent *> *components;

- (void)addComponent:(GKComponent *)component;
- (void)removeComponentForClass:(Class)componentClass;
- (GKComponent *)componentForClass:(Class)componentClass;

@end
