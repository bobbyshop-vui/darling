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

#import <GameplayKit/GKGraphNode.h>

// A set of nodes and the paths between them.
@interface GKGraph : NSObject <NSCopying, NSSecureCoding> {
    NSMutableArray *_nodes;
}

@property (nonatomic, readonly) NSArray<GKGraphNode *> *nodes;

+ (instancetype)graphWithNodes:(NSArray<GKGraphNode *> *)nodes;
- (instancetype)initWithNodes:(NSArray<GKGraphNode *> *)nodes;
- (void)connectNodeToLowestCostNode:(GKGraphNode *)node bidirectional:(BOOL)bidirectional;
- (void)removeNodes:(NSArray<GKGraphNode *> *)nodes;
- (void)addNodes:(NSArray<GKGraphNode *> *)nodes;
- (NSArray *)findPathFromNode:(GKGraphNode *)startNode toNode:(GKGraphNode *)endNode;

@end
