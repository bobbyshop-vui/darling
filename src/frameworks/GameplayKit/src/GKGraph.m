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

@implementation GKGraph

+ (BOOL)supportsSecureCoding
{
    return YES;
}

+ (instancetype)graphWithNodes:(NSArray *)nodes
{
    return [[[self alloc] initWithNodes:nodes] autorelease];
}

- (instancetype)init
{
    return [self initWithNodes:[NSArray array]];
}

- (instancetype)initWithNodes:(NSArray *)nodes
{
    self = [super init];
    if (self != nil)
    {
        _nodes = [[NSMutableArray alloc] init];
        [self addNodes:nodes];
    }
    return self;
}

- (void)dealloc
{
    [_nodes release];
    [super dealloc];
}

- (NSArray *)nodes
{
    return [[_nodes copy] autorelease];
}

- (void)addNodes:(NSArray *)nodes
{
    for (GKGraphNode *node in nodes)
    {
        if ([node isKindOfClass:[GKGraphNode class]] && [_nodes indexOfObjectIdenticalTo:node] == NSNotFound)
            [_nodes addObject:node];
    }
}

- (void)removeNodes:(NSArray *)nodes
{
    for (GKGraphNode *node in [[nodes copy] autorelease])
    {
        if ([_nodes indexOfObjectIdenticalTo:node] == NSNotFound)
            continue;
        [[node retain] autorelease];
        [_nodes removeObjectIdenticalTo:node];
        NSArray *removed = [NSArray arrayWithObject:node];
        for (GKGraphNode *other in _nodes)
            [other removeConnectionsToNodes:removed bidirectional:NO];
        [node removeConnectionsToNodes:[node connectedNodes] bidirectional:NO];
    }
}

- (void)connectNodeToLowestCostNode:(GKGraphNode *)node bidirectional:(BOOL)bidirectional
{
    GKGraphNode *lowest = nil;
    float lowestCost = 0;
    for (GKGraphNode *other in _nodes)
    {
        if (other == node)
            continue;
        float cost = [node costToNode:other];
        if (lowest == nil || cost < lowestCost)
        {
            lowest = other;
            lowestCost = cost;
        }
    }
    if (lowest != nil)
        [node addConnectionsToNodes:[NSArray arrayWithObject:lowest] bidirectional:bidirectional];
    [self addNodes:[NSArray arrayWithObject:node]];
}

- (NSArray *)findPathFromNode:(GKGraphNode *)startNode toNode:(GKGraphNode *)endNode
{
    return [startNode findPathToNode:endNode];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithNodes:_nodes];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    return [self initWithNodes:GKArrayFromCollection(GKDecodeObject(coder, @"_nodes"))];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_nodes forKey:@"_nodes"];
}

@end
