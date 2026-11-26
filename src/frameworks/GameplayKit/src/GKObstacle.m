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
#include <stdlib.h>
#include <string.h>

@implementation GKObstacle
@end

@implementation GKCircleObstacle

+ (instancetype)obstacleWithRadius:(float)radius
{
    return [[[self alloc] initWithRadius:radius] autorelease];
}

- (instancetype)initWithRadius:(float)radius
{
    self = [super init];
    if (self != nil)
        _radius = radius;
    return self;
}

- (float)radius { return _radius; }
- (void)setRadius:(float)radius { _radius = radius; }
- (vector_float2)position { return _position; }
- (void)setPosition:(vector_float2)position { _position = position; }

@end

@implementation GKPolygonObstacle

+ (BOOL)supportsSecureCoding
{
    return YES;
}

+ (instancetype)obstacleWithPoints:(vector_float2 *)points count:(size_t)numPoints
{
    return [[[self alloc] initWithPoints:points count:numPoints] autorelease];
}

- (instancetype)initWithPoints:(vector_float2 *)points count:(size_t)numPoints
{
    self = [super init];
    if (self != nil)
    {
        _vertexCount = points != NULL ? numPoints : 0;
        if (_vertexCount > 0)
        {
            _vertices = malloc(sizeof(vector_float2) * _vertexCount);
            memcpy(_vertices, points, sizeof(vector_float2) * _vertexCount);
        }
    }
    return self;
}

- (void)dealloc
{
    free(_vertices);
    [super dealloc];
}

- (NSUInteger)vertexCount
{
    return _vertexCount;
}

- (vector_float2)vertexAtIndex:(NSUInteger)index
{
    if (index >= _vertexCount)
    {
        [NSException raise:NSRangeException format:@"-[GKPolygonObstacle vertexAtIndex:]: index %lu beyond count %lu", (unsigned long)index, (unsigned long)_vertexCount];
    }
    return _vertices[index];
}

// The vertices are archived as x, y float pairs.
- (instancetype)initWithCoder:(NSCoder *)coder
{
    NSUInteger count = (NSUInteger)[coder decodeIntegerForKey:@"numVertices"];
    NSUInteger length = 0;
    const float *floats = (const float *)[coder decodeBytesForKey:@"vertices" returnedLength:&length];
    if (floats == NULL || length < count * 2 * sizeof(float))
        count = 0;
    vector_float2 *points = count > 0 ? malloc(sizeof(vector_float2) * count) : NULL;
    for (NSUInteger i = 0; i < count; i++)
    {
        points[i].x = floats[2 * i];
        points[i].y = floats[2 * i + 1];
    }
    self = [self initWithPoints:points count:count];
    free(points);
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    float *floats = _vertexCount > 0 ? malloc(sizeof(float) * 2 * _vertexCount) : NULL;
    for (NSUInteger i = 0; i < _vertexCount; i++)
    {
        floats[2 * i] = _vertices[i].x;
        floats[2 * i + 1] = _vertices[i].y;
    }
    [coder encodeInteger:(NSInteger)_vertexCount forKey:@"numVertices"];
    [coder encodeBytes:(const uint8_t *)floats length:sizeof(float) * 2 * _vertexCount forKey:@"vertices"];
    free(floats);
}

@end

@implementation GKSphereObstacle

+ (instancetype)obstacleWithRadius:(float)radius
{
    return [[[self alloc] initWithRadius:radius] autorelease];
}

- (instancetype)initWithRadius:(float)radius
{
    self = [super init];
    if (self != nil)
        _radius = radius;
    return self;
}

- (float)radius { return _radius; }
- (void)setRadius:(float)radius { _radius = radius; }
- (vector_float3)position { return _position; }
- (void)setPosition:(vector_float3)position { _position = position; }

@end
