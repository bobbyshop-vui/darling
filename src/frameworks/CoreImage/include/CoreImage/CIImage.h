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

@interface CIImage : NSObject <NSCopying> {
    CGImageRef _cgImage;
}

+ (CIImage *)emptyImage;
+ (CIImage *)imageWithCGImage:(CGImageRef)image;
+ (CIImage *)imageWithCGImage:(CGImageRef)image options:(NSDictionary *)options;
- (instancetype)initWithCGImage:(CGImageRef)image;
- (instancetype)initWithCGImage:(CGImageRef)image options:(NSDictionary *)options;

// Darling's images are rendered bitmaps: the extent is the bitmap's bounds.
- (CGRect)extent;
- (CGImageRef)CGImage;

- (CIImage *)imageByApplyingFilter:(NSString *)filterName withInputParameters:(NSDictionary *)params;
- (CIImage *)imageByCroppingToRect:(CGRect)rect;

// AppKit's NSCIImageRep additions: draw into the current NSGraphicsContext.
- (void)drawAtPoint:(NSPoint)point fromRect:(NSRect)srcRect operation:(NSUInteger)op fraction:(CGFloat)delta;
- (void)drawInRect:(NSRect)dstRect fromRect:(NSRect)srcRect operation:(NSUInteger)op fraction:(CGFloat)delta;

@end
