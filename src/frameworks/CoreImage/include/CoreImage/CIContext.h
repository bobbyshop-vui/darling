/*
 This file is part of Darling.

 Copyright (C) 2017 Lubos Dolezel

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

#include <Foundation/Foundation.h>
#include <CoreGraphics/CoreGraphics.h>

@class CIImage;

@interface CIContext : NSObject {
    CGContextRef _cgContext;
}

+ (CIContext *)context;
+ (CIContext *)contextWithOptions:(NSDictionary *)options;
+ (CIContext *)contextWithCGContext:(CGContextRef)cgContext options:(NSDictionary *)options;

- (CGImageRef)createCGImage:(CIImage *)image fromRect:(CGRect)fromRect;
- (CGImageRef)createCGImage:(CIImage *)image fromRect:(CGRect)fromRect format:(int)format colorSpace:(CGColorSpaceRef)colorSpace;
- (void)drawImage:(CIImage *)image inRect:(CGRect)inRect fromRect:(CGRect)fromRect;
- (void)drawImage:(CIImage *)image atPoint:(CGPoint)atPoint fromRect:(CGRect)fromRect;

@end
