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

@class GKEntity, GKGraph;

// A scene's root node (an SKScene or SCNScene).
@protocol GKSceneRootNodeType <NSObject>
@end

// The entities and navigation graphs of a game scene.
@interface GKScene : NSObject <NSCopying, NSSecureCoding> {
    NSMutableArray *_entities;
    NSMutableDictionary *_graphs;
    id _rootNode;
}

+ (instancetype)sceneWithFileNamed:(NSString *)filename;
+ (instancetype)sceneWithFileNamed:(NSString *)filename rootNode:(id<GKSceneRootNodeType>)rootNode;

@property (nonatomic, readonly) NSArray<GKEntity *> *entities;
@property (nonatomic, retain) id<GKSceneRootNodeType> rootNode;
@property (nonatomic, readonly) NSDictionary<NSString *, GKGraph *> *graphs;

- (void)addEntity:(GKEntity *)entity;
- (void)removeEntity:(GKEntity *)entity;
- (void)addGraph:(GKGraph *)graph name:(NSString *)name;
- (void)removeGraph:(NSString *)name;

@end
