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

#import <CoreImage/CIImage.h>
#import <CoreImage/CIFilter.h>
#import <objc/runtime.h>
#import <objc/message.h>

// The pixel work shared with CIFilter: images are kept as rendered bitmaps.

@implementation CIImage

+ (CIImage *)emptyImage {
    return [[[self alloc] init] autorelease];
}

+ (CIImage *)imageWithCGImage:(CGImageRef)image {
    return [[[self alloc] initWithCGImage: image] autorelease];
}

+ (CIImage *)imageWithCGImage:(CGImageRef)image options:(NSDictionary *)options {
    return [self imageWithCGImage: image];
}

- (instancetype)initWithCGImage:(CGImageRef)image {
    self = [super init];
    if (self != nil && image != NULL)
        _cgImage = CGImageRetain(image);
    return self;
}

- (instancetype)initWithCGImage:(CGImageRef)image options:(NSDictionary *)options {
    return [self initWithCGImage: image];
}

- (void)dealloc {
    if (_cgImage != NULL)
        CGImageRelease(_cgImage);
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
    return [self retain];
}

- (CGRect)extent {
    if (_cgImage == NULL)
        return CGRectZero;
    return CGRectMake(0, 0, CGImageGetWidth(_cgImage), CGImageGetHeight(_cgImage));
}

- (CGImageRef)CGImage {
    return _cgImage;
}

- (CIImage *)imageByApplyingFilter:(NSString *)filterName withInputParameters:(NSDictionary *)params {
    CIFilter *filter = [CIFilter filterWithName: filterName withInputParameters: params];
    [filter setValue: self forKey: kCIInputImageKey];
    return [filter outputImage];
}

- (CIImage *)imageByCroppingToRect:(CGRect)rect {
    if (_cgImage == NULL)
        return self;
    CGRect bounds = CGRectIntersection(CGRectIntegral(rect), [self extent]);
    if (CGRectIsEmpty(bounds))
        return [CIImage emptyImage];
    // CGImage rows run top down; the extent's origin is the bottom left.
    CGRect imageRect = CGRectMake(bounds.origin.x, CGImageGetHeight(_cgImage) - CGRectGetMaxY(bounds),
                                  bounds.size.width, bounds.size.height);
    CGImageRef cropped = CGImageCreateWithImageInRect(_cgImage, imageRect);
    CIImage *result = [CIImage imageWithCGImage: cropped];
    CGImageRelease(cropped);
    return result;
}

static CGContextRef CIImageCurrentContext(BOOL *flipped) {
    id graphicsContext = [NSClassFromString(@"NSGraphicsContext") performSelector: @selector(currentContext)];
    *flipped = graphicsContext != nil && ((BOOL (*)(id, SEL))objc_msgSend)(graphicsContext, @selector(isFlipped));
    return graphicsContext != nil ? (CGContextRef)[graphicsContext performSelector: @selector(graphicsPort)] : NULL;
}

- (void)drawInRect:(NSRect)dstRect fromRect:(NSRect)srcRect operation:(NSUInteger)op fraction:(CGFloat)delta {
    BOOL flipped = NO;
    CGContextRef context = CIImageCurrentContext(&flipped);
    if (context == NULL || _cgImage == NULL)
        return;

    CIImage *source = self;
    if (srcRect.size.width > 0 && srcRect.size.height > 0)
        source = [self imageByCroppingToRect: NSRectToCGRect(srcRect)];
    CGImageRef image = [source CGImage];
    if (image == NULL)
        return;

    CGContextSaveGState(context);
    CGContextSetAlpha(context, delta);
    // NSCompositeClear, NSCompositeCopy; everything else draws over.
    if (op == 0)
        CGContextSetBlendMode(context, kCGBlendModeClear);
    else if (op == 1)
        CGContextSetBlendMode(context, kCGBlendModeCopy);
    if (flipped) {
        CGContextTranslateCTM(context, 0, NSMaxY(dstRect) + NSMinY(dstRect));
        CGContextScaleCTM(context, 1, -1);
    }
    CGContextDrawImage(context, NSRectToCGRect(dstRect), image);
    CGContextRestoreGState(context);
}

- (void)drawAtPoint:(NSPoint)point fromRect:(NSRect)srcRect operation:(NSUInteger)op fraction:(CGFloat)delta {
    NSSize size = (srcRect.size.width > 0 && srcRect.size.height > 0)
            ? srcRect.size : NSSizeFromCGSize([self extent].size);
    [self drawInRect: NSMakeRect(point.x, point.y, size.width, size.height)
            fromRect: srcRect operation: op fraction: delta];
}

// Unimplemented messages answer nil/0 instead of a garbage return value.
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector: aSelector];
    if (signature != nil)
        return signature;
    char types[64] = "@@:";
    size_t length = 3;
    for (const char *p = sel_getName(aSelector); *p && length < sizeof(types) - 1; p++)
        if (*p == ':')
            types[length++] = '@';
    types[length] = '\0';
    return [NSMethodSignature signatureWithObjCTypes: types];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"Stub called: %@ in %@", NSStringFromSelector([anInvocation selector]), [self class]);
    id result = nil;
    if ([[anInvocation methodSignature] methodReturnLength] <= sizeof(result))
        [anInvocation setReturnValue: &result];
}

@end
