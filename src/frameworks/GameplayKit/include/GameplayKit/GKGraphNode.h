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

// A node of a navigation graph.
@interface GKGraphNode : NSObject <NSSecureCoding> {
    NSMutableArray *_connectedNodes;
}

@property (nonatomic, readonly) NSArray<GKGraphNode *> *connectedNodes;

- (void)addConnectionsToNodes:(NSArray<GKGraphNode *> *)nodes bidirectional:(BOOL)bidirectional;
- (void)removeConnectionsToNodes:(NSArray<GKGraphNode *> *)nodes bidirectional:(BOOL)bidirectional;
- (float)estimatedCostToNode:(GKGraphNode *)node;
- (float)costToNode:(GKGraphNode *)node;
- (NSArray *)findPathToNode:(GKGraphNode *)goalNode;
- (NSArray *)findPathFromNode:(GKGraphNode *)startNode;

@end

@interface GKGraphNode2D : GKGraphNode {
    vector_float2 _position;
}
@property (nonatomic) vector_float2 position;
+ (instancetype)nodeWithPoint:(vector_float2)point;
- (instancetype)initWithPoint:(vector_float2)point;
@end

@interface GKGraphNode3D : GKGraphNode {
    vector_float3 _position;
}
@property (nonatomic) vector_float3 position;
+ (instancetype)nodeWithPoint:(vector_float3)point;
- (instancetype)initWithPoint:(vector_float3)point;
@end

@interface GKGridGraphNode : GKGraphNode {
    vector_int2 _gridPosition;
}
@property (nonatomic, readonly) vector_int2 gridPosition;
+ (instancetype)nodeWithGridPosition:(vector_int2)gridPosition;
- (instancetype)initWithGridPosition:(vector_int2)gridPosition;
@end
