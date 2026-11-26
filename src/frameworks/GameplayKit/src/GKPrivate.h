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

#import <GameplayKit/GameplayKit.h>

@interface GKComponent (GKPrivate)
- (void)_setEntity:(GKEntity *)entity;
@end

// Decodes an object for key, from secure coders too (subclasses of the
// GameplayKit classes come from Xcode's plug-ins and games).
id GKDecodeObject(NSCoder *coder, NSString *key);

// The values of an archived collection (array, set or dictionary).
NSArray *GKArrayFromCollection(id collection);
