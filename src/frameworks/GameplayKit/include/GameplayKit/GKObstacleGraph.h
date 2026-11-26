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

#import <GameplayKit/GKGraph.h>
#import <GameplayKit/GKObstacle.h>

// A graph whose nodes go around polygon obstacles, connected where nothing
// blocks the straight line between them.
@interface GKObstacleGraph<NodeType : GKGraphNode2D *> : GKGraph {
    NSMutableArray *_obstacles;
    NSMutableDictionary *_obstacleNodes;
    NSMutableSet *_lockedConnections;
    float _bufferRadius;
    Class _nodeClass;
}

@property (nonatomic, readonly) NSArray<GKPolygonObstacle *> *obstacles;
@property (nonatomic, readonly) float bufferRadius;

+ (instancetype)graphWithObstacles:(NSArray<GKPolygonObstacle *> *)obstacles bufferRadius:(float)bufferRadius;
- (instancetype)initWithObstacles:(NSArray<GKPolygonObstacle *> *)obstacles bufferRadius:(float)bufferRadius;
+ (instancetype)graphWithObstacles:(NSArray<GKPolygonObstacle *> *)obstacles bufferRadius:(float)bufferRadius nodeClass:(Class)nodeClass;
- (instancetype)initWithObstacles:(NSArray<GKPolygonObstacle *> *)obstacles bufferRadius:(float)bufferRadius nodeClass:(Class)nodeClass;
- (void)connectNodeUsingObstacles:(NodeType)node;
- (void)connectNodeUsingObstacles:(NodeType)node ignoringObstacles:(NSArray<GKPolygonObstacle *> *)obstaclesToIgnore;
- (void)connectNodeUsingObstacles:(NodeType)node ignoringBufferRadiusOfObstacles:(NSArray<GKPolygonObstacle *> *)obstaclesBufferRadiusToIgnore;
- (void)addObstacles:(NSArray<GKPolygonObstacle *> *)obstacles;
- (void)removeObstacles:(NSArray<GKPolygonObstacle *> *)obstacles;
- (void)removeAllObstacles;
- (void)lockConnectionFromNode:(NodeType)startNode toNode:(NodeType)endNode;
- (void)unlockConnectionFromNode:(NodeType)startNode toNode:(NodeType)endNode;
- (BOOL)isConnectionLockedFromNode:(NodeType)startNode toNode:(NodeType)endNode;
- (Class)classForGenericArgumentAtIndex:(NSUInteger)index;

@end
