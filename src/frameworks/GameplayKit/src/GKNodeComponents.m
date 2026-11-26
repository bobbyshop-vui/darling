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

@implementation GKSKNodeComponent

+ (instancetype)componentWithNode:(SKNode *)node
{
    return [[[self alloc] initWithNode:node] autorelease];
}

- (instancetype)initWithNode:(SKNode *)node
{
    self = [super init];
    if (self != nil)
        _node = [node retain];
    return self;
}

- (void)dealloc
{
    [_node release];
    [super dealloc];
}

- (SKNode *)node
{
    return _node;
}

- (void)setNode:(SKNode *)node
{
    [node retain];
    [_node release];
    _node = node;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithNode:_node];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self != nil)
        _node = [GKDecodeObject(coder, @"_node") retain];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeConditionalObject:_node forKey:@"_node"];
}

@end

@implementation GKSCNNodeComponent

+ (instancetype)componentWithNode:(SCNNode *)node
{
    return [[[self alloc] initWithNode:node] autorelease];
}

- (instancetype)initWithNode:(SCNNode *)node
{
    self = [super init];
    if (self != nil)
        _node = [node retain];
    return self;
}

- (void)dealloc
{
    [_node release];
    [super dealloc];
}

- (SCNNode *)node
{
    return _node;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithNode:_node];
}

@end
