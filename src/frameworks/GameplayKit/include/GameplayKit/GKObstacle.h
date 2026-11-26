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

@interface GKObstacle : NSObject
@end

@interface GKCircleObstacle : GKObstacle {
    float _radius;
    vector_float2 _position;
}
@property (nonatomic, assign) float radius;
@property (nonatomic, assign) vector_float2 position;
+ (instancetype)obstacleWithRadius:(float)radius;
- (instancetype)initWithRadius:(float)radius;
@end

@interface GKPolygonObstacle : GKObstacle <NSSecureCoding> {
    vector_float2 *_vertices;
    NSUInteger _vertexCount;
}
@property (nonatomic, readonly) NSUInteger vertexCount;
+ (instancetype)obstacleWithPoints:(vector_float2 *)points count:(size_t)numPoints;
- (instancetype)initWithPoints:(vector_float2 *)points count:(size_t)numPoints;
- (vector_float2)vertexAtIndex:(NSUInteger)index;
@end

@interface GKSphereObstacle : GKObstacle {
    float _radius;
    vector_float3 _position;
}
@property (nonatomic, assign) float radius;
@property (nonatomic, assign) vector_float3 position;
+ (instancetype)obstacleWithRadius:(float)radius;
- (instancetype)initWithRadius:(float)radius;
@end
