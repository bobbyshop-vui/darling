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

static NSValue *GKNodeKey(GKGraphNode *node)
{
    return [NSValue valueWithNonretainedObject:node];
}

@implementation GKGraphNode

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)init
{
    self = [super init];
    if (self != nil)
        _connectedNodes = [[NSMutableArray alloc] init];
    return self;
}

- (void)dealloc
{
    [_connectedNodes release];
    [super dealloc];
}

- (NSArray *)connectedNodes
{
    return [[_connectedNodes copy] autorelease];
}

- (void)addConnectionsToNodes:(NSArray *)nodes bidirectional:(BOOL)bidirectional
{
    for (GKGraphNode *node in nodes)
    {
        if (node == self)
            continue;
        if ([_connectedNodes indexOfObjectIdenticalTo:node] == NSNotFound)
            [_connectedNodes addObject:node];
        if (bidirectional)
            [node addConnectionsToNodes:[NSArray arrayWithObject:self] bidirectional:NO];
    }
}

- (void)removeConnectionsToNodes:(NSArray *)nodes bidirectional:(BOOL)bidirectional
{
    for (GKGraphNode *node in [[nodes copy] autorelease])
    {
        [_connectedNodes removeObjectIdenticalTo:node];
        if (bidirectional)
            [node removeConnectionsToNodes:[NSArray arrayWithObject:self] bidirectional:NO];
    }
}

// The base class has no geometry: every hop costs the same and the search
// is not guided.
- (float)estimatedCostToNode:(GKGraphNode *)node
{
    return 0;
}

- (float)costToNode:(GKGraphNode *)node
{
    return 1;
}

// A* over the connections, using -costToNode: and -estimatedCostToNode:.
// The path starts with the receiver and ends with goalNode; it is empty if
// goalNode cannot be reached.
- (NSArray *)findPathToNode:(GKGraphNode *)goalNode
{
    if (goalNode == nil)
        return [NSArray array];
    if (goalNode == self)
        return [NSArray arrayWithObject:self];

    NSMutableArray *open = [NSMutableArray arrayWithObject:self];
    NSMutableSet *closed = [NSMutableSet set];
    NSMutableDictionary *costSoFar = [NSMutableDictionary dictionary];
    NSMutableDictionary *estimate = [NSMutableDictionary dictionary];
    NSMutableDictionary *cameFrom = [NSMutableDictionary dictionary];

    [costSoFar setObject:[NSNumber numberWithFloat:0] forKey:GKNodeKey(self)];
    [estimate setObject:[NSNumber numberWithFloat:[self estimatedCostToNode:goalNode]] forKey:GKNodeKey(self)];

    while ([open count] > 0)
    {
        GKGraphNode *current = nil;
        float best = INFINITY;
        for (GKGraphNode *node in open)
        {
            float value = [[estimate objectForKey:GKNodeKey(node)] floatValue];
            if (current == nil || value < best)
            {
                current = node;
                best = value;
            }
        }

        if (current == goalNode)
        {
            NSMutableArray *path = [NSMutableArray array];
            for (GKGraphNode *node = goalNode; node != nil; node = [[cameFrom objectForKey:GKNodeKey(node)] nonretainedObjectValue])
                [path insertObject:node atIndex:0];
            return path;
        }

        [[current retain] autorelease];
        [open removeObjectIdenticalTo:current];
        [closed addObject:GKNodeKey(current)];

        float currentCost = [[costSoFar objectForKey:GKNodeKey(current)] floatValue];
        for (GKGraphNode *neighbour in current->_connectedNodes)
        {
            NSValue *key = GKNodeKey(neighbour);
            if ([closed containsObject:key])
                continue;
            float cost = currentCost + [current costToNode:neighbour];
            NSNumber *known = [costSoFar objectForKey:key];
            BOOL isOpen = [open indexOfObjectIdenticalTo:neighbour] != NSNotFound;
            if (isOpen && known != nil && cost >= [known floatValue])
                continue;
            [cameFrom setObject:GKNodeKey(current) forKey:key];
            [costSoFar setObject:[NSNumber numberWithFloat:cost] forKey:key];
            [estimate setObject:[NSNumber numberWithFloat:cost + [neighbour estimatedCostToNode:goalNode]] forKey:key];
            if (!isOpen)
                [open addObject:neighbour];
        }
    }
    return [NSArray array];
}

- (NSArray *)findPathFromNode:(GKGraphNode *)startNode
{
    return [startNode findPathToNode:self];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [self init];
    if (self != nil)
    {
        for (id node in GKArrayFromCollection(GKDecodeObject(coder, @"_connectedNodes")))
        {
            if ([node isKindOfClass:[GKGraphNode class]] && node != self)
                [_connectedNodes addObject:node];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_connectedNodes forKey:@"_connectedNodes"];
}

@end

@implementation GKGraphNode2D

+ (instancetype)nodeWithPoint:(vector_float2)point
{
    return [[[self alloc] initWithPoint:point] autorelease];
}

- (instancetype)initWithPoint:(vector_float2)point
{
    self = [super init];
    if (self != nil)
        _position = point;
    return self;
}

- (vector_float2)position
{
    return _position;
}

- (void)setPosition:(vector_float2)position
{
    _position = position;
}

static float GKDistance2D(vector_float2 a, vector_float2 b)
{
    float dx = a.x - b.x, dy = a.y - b.y;
    return sqrtf(dx * dx + dy * dy);
}

- (float)costToNode:(GKGraphNode *)node
{
    if ([node isKindOfClass:[GKGraphNode2D class]])
        return GKDistance2D(_position, [(GKGraphNode2D *)node position]);
    return [super costToNode:node];
}

- (float)estimatedCostToNode:(GKGraphNode *)node
{
    if ([node isKindOfClass:[GKGraphNode2D class]])
        return GKDistance2D(_position, [(GKGraphNode2D *)node position]);
    return [super estimatedCostToNode:node];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self != nil)
    {
        _position.x = [coder decodeFloatForKey:@"positionX"];
        _position.y = [coder decodeFloatForKey:@"positionY"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeFloat:_position.x forKey:@"positionX"];
    [coder encodeFloat:_position.y forKey:@"positionY"];
}

@end

@implementation GKGraphNode3D

+ (instancetype)nodeWithPoint:(vector_float3)point
{
    return [[[self alloc] initWithPoint:point] autorelease];
}

- (instancetype)initWithPoint:(vector_float3)point
{
    self = [super init];
    if (self != nil)
        _position = point;
    return self;
}

- (vector_float3)position
{
    return _position;
}

- (void)setPosition:(vector_float3)position
{
    _position = position;
}

static float GKDistance3D(vector_float3 a, vector_float3 b)
{
    float dx = a.x - b.x, dy = a.y - b.y, dz = a.z - b.z;
    return sqrtf(dx * dx + dy * dy + dz * dz);
}

- (float)costToNode:(GKGraphNode *)node
{
    if ([node isKindOfClass:[GKGraphNode3D class]])
        return GKDistance3D(_position, [(GKGraphNode3D *)node position]);
    return [super costToNode:node];
}

- (float)estimatedCostToNode:(GKGraphNode *)node
{
    if ([node isKindOfClass:[GKGraphNode3D class]])
        return GKDistance3D(_position, [(GKGraphNode3D *)node position]);
    return [super estimatedCostToNode:node];
}

@end

@implementation GKGridGraphNode

+ (instancetype)nodeWithGridPosition:(vector_int2)gridPosition
{
    return [[[self alloc] initWithGridPosition:gridPosition] autorelease];
}

- (instancetype)initWithGridPosition:(vector_int2)gridPosition
{
    self = [super init];
    if (self != nil)
        _gridPosition = gridPosition;
    return self;
}

- (vector_int2)gridPosition
{
    return _gridPosition;
}

- (float)estimatedCostToNode:(GKGraphNode *)node
{
    if (![node isKindOfClass:[GKGridGraphNode class]])
        return [super estimatedCostToNode:node];
    vector_int2 other = [(GKGridGraphNode *)node gridPosition];
    float dx = _gridPosition.x - other.x, dy = _gridPosition.y - other.y;
    return sqrtf(dx * dx + dy * dy);
}

@end
