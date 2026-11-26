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
#include <math.h>

static NSValue *GKObjectKey(id object)
{
    return [NSValue valueWithNonretainedObject:object];
}

// Whether segments ab and cd cross at a point inside both (touching ends
// do not count).
static BOOL GKSegmentsCross(vector_float2 a, vector_float2 b, vector_float2 c, vector_float2 d)
{
    float d1 = (d.x - c.x) * (a.y - c.y) - (d.y - c.y) * (a.x - c.x);
    float d2 = (d.x - c.x) * (b.y - c.y) - (d.y - c.y) * (b.x - c.x);
    float d3 = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
    float d4 = (b.x - a.x) * (d.y - a.y) - (b.y - a.y) * (d.x - a.x);
    return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
           ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0));
}

static BOOL GKPolygonContainsPoint(GKPolygonObstacle *obstacle, vector_float2 point)
{
    BOOL inside = NO;
    NSUInteger count = [obstacle vertexCount];
    for (NSUInteger i = 0, j = count - 1; i < count; j = i++)
    {
        vector_float2 vi = [obstacle vertexAtIndex:i], vj = [obstacle vertexAtIndex:j];
        if (((vi.y > point.y) != (vj.y > point.y)) &&
            (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x))
            inside = !inside;
    }
    return count > 2 && inside;
}

static BOOL GKSegmentBlocked(vector_float2 a, vector_float2 b, NSArray *obstacles)
{
    vector_float2 middle = { (a.x + b.x) / 2, (a.y + b.y) / 2 };
    for (GKPolygonObstacle *obstacle in obstacles)
    {
        NSUInteger count = [obstacle vertexCount];
        for (NSUInteger i = 0; i < count; i++)
        {
            if (GKSegmentsCross(a, b, [obstacle vertexAtIndex:i], [obstacle vertexAtIndex:(i + 1) % count]))
                return YES;
        }
        if (GKPolygonContainsPoint(obstacle, middle))
            return YES;
    }
    return NO;
}

@implementation GKObstacleGraph

+ (instancetype)graphWithObstacles:(NSArray *)obstacles bufferRadius:(float)bufferRadius
{
    return [[[self alloc] initWithObstacles:obstacles bufferRadius:bufferRadius] autorelease];
}

+ (instancetype)graphWithObstacles:(NSArray *)obstacles bufferRadius:(float)bufferRadius nodeClass:(Class)nodeClass
{
    return [[[self alloc] initWithObstacles:obstacles bufferRadius:bufferRadius nodeClass:nodeClass] autorelease];
}

- (instancetype)initWithObstacles:(NSArray *)obstacles bufferRadius:(float)bufferRadius
{
    return [self initWithObstacles:obstacles bufferRadius:bufferRadius nodeClass:[GKGraphNode2D class]];
}

- (instancetype)initWithObstacles:(NSArray *)obstacles bufferRadius:(float)bufferRadius nodeClass:(Class)nodeClass
{
    self = [super initWithNodes:[NSArray array]];
    if (self != nil)
    {
        _obstacles = [[NSMutableArray alloc] init];
        _obstacleNodes = [[NSMutableDictionary alloc] init];
        _lockedConnections = [[NSMutableSet alloc] init];
        _bufferRadius = bufferRadius;
        _nodeClass = [nodeClass isSubclassOfClass:[GKGraphNode2D class]] ? nodeClass : [GKGraphNode2D class];
        [self addObstacles:obstacles];
    }
    return self;
}

- (void)dealloc
{
    [_obstacles release];
    [_obstacleNodes release];
    [_lockedConnections release];
    [super dealloc];
}

- (NSArray *)obstacles
{
    return [[_obstacles copy] autorelease];
}

- (float)bufferRadius
{
    return _bufferRadius;
}

- (Class)classForGenericArgumentAtIndex:(NSUInteger)index
{
    return _nodeClass;
}

static NSValue *GKConnectionKey(GKGraphNode *from, GKGraphNode *to)
{
    // Locks hold in both directions.
    void *a = from, *b = to;
    if (a > b)
    {
        void *swap = a;
        a = b;
        b = swap;
    }
    void *pair[2] = { a, b };
    return [NSValue valueWithBytes:pair objCType:@encode(void *[2])];
}

- (void)lockConnectionFromNode:(GKGraphNode2D *)startNode toNode:(GKGraphNode2D *)endNode
{
    [_lockedConnections addObject:GKConnectionKey(startNode, endNode)];
}

- (void)unlockConnectionFromNode:(GKGraphNode2D *)startNode toNode:(GKGraphNode2D *)endNode
{
    [_lockedConnections removeObject:GKConnectionKey(startNode, endNode)];
}

- (BOOL)isConnectionLockedFromNode:(GKGraphNode2D *)startNode toNode:(GKGraphNode2D *)endNode
{
    return [_lockedConnections containsObject:GKConnectionKey(startNode, endNode)];
}

// Connects every pair of nodes nothing blocks and disconnects blocked pairs,
// leaving locked connections alone.
- (void)_updateConnections
{
    NSArray *nodes = [self nodes];
    for (NSUInteger i = 0; i < [nodes count]; i++)
    {
        GKGraphNode2D *a = [nodes objectAtIndex:i];
        for (NSUInteger j = i + 1; j < [nodes count]; j++)
        {
            GKGraphNode2D *b = [nodes objectAtIndex:j];
            if ([self isConnectionLockedFromNode:a toNode:b])
                continue;
            NSArray *pair = [NSArray arrayWithObject:b];
            if (GKSegmentBlocked([a position], [b position], _obstacles))
                [a removeConnectionsToNodes:pair bidirectional:YES];
            else
                [a addConnectionsToNodes:pair bidirectional:YES];
        }
    }
}

// Nodes sit at the obstacle's vertices, pushed out from its centre by the
// buffer radius.
- (void)addObstacles:(NSArray *)obstacles
{
    for (GKPolygonObstacle *obstacle in obstacles)
    {
        if (![obstacle isKindOfClass:[GKPolygonObstacle class]] || [_obstacles indexOfObjectIdenticalTo:obstacle] != NSNotFound)
            continue;
        [_obstacles addObject:obstacle];

        NSUInteger count = [obstacle vertexCount];
        vector_float2 centre = { 0, 0 };
        for (NSUInteger i = 0; i < count; i++)
        {
            centre.x += [obstacle vertexAtIndex:i].x / count;
            centre.y += [obstacle vertexAtIndex:i].y / count;
        }
        NSMutableArray *nodes = [NSMutableArray array];
        for (NSUInteger i = 0; i < count; i++)
        {
            vector_float2 vertex = [obstacle vertexAtIndex:i];
            float dx = vertex.x - centre.x, dy = vertex.y - centre.y;
            float length = sqrtf(dx * dx + dy * dy);
            vector_float2 position = vertex;
            if (length > 0)
            {
                position.x += dx / length * _bufferRadius;
                position.y += dy / length * _bufferRadius;
            }
            GKGraphNode2D *node = [(GKGraphNode2D *)[_nodeClass alloc] initWithPoint:position];
            [nodes addObject:node];
            [node release];
        }
        [_obstacleNodes setObject:nodes forKey:GKObjectKey(obstacle)];
        [self addNodes:nodes];
    }
    [self _updateConnections];
}

- (void)removeObstacles:(NSArray *)obstacles
{
    for (GKPolygonObstacle *obstacle in [[obstacles copy] autorelease])
    {
        NSValue *key = GKObjectKey(obstacle);
        NSArray *nodes = [_obstacleNodes objectForKey:key];
        if (nodes != nil)
            [self removeNodes:nodes];
        [_obstacleNodes removeObjectForKey:key];
        [_obstacles removeObjectIdenticalTo:obstacle];
    }
    [self _updateConnections];
}

- (void)removeAllObstacles
{
    [self removeObstacles:[self obstacles]];
}

- (void)connectNodeUsingObstacles:(GKGraphNode2D *)node
{
    [self connectNodeUsingObstacles:node ignoringObstacles:[NSArray array]];
}

- (void)connectNodeUsingObstacles:(GKGraphNode2D *)node ignoringObstacles:(NSArray *)obstaclesToIgnore
{
    NSMutableArray *obstacles = [NSMutableArray arrayWithArray:_obstacles];
    [obstacles removeObjectsInArray:obstaclesToIgnore];
    for (GKGraphNode2D *other in [self nodes])
    {
        if (other != node && !GKSegmentBlocked([node position], [other position], obstacles))
            [node addConnectionsToNodes:[NSArray arrayWithObject:other] bidirectional:YES];
    }
    [self addNodes:[NSArray arrayWithObject:node]];
}

// Darling's obstacles block with their own outline; the buffer only places
// the obstacle nodes, so ignoring it changes nothing here.
- (void)connectNodeUsingObstacles:(GKGraphNode2D *)node ignoringBufferRadiusOfObstacles:(NSArray *)obstaclesBufferRadiusToIgnore
{
    [self connectNodeUsingObstacles:node];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithObstacles:_obstacles bufferRadius:_bufferRadius nodeClass:_nodeClass];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    NSArray *obstacles = GKArrayFromCollection(GKDecodeObject(coder, @"_sourceObstacles"));
    return [self initWithObstacles:obstacles bufferRadius:[coder decodeFloatForKey:@"bufferRadius"]];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_obstacles forKey:@"_sourceObstacles"];
    [coder encodeFloat:_bufferRadius forKey:@"bufferRadius"];
}

@end
