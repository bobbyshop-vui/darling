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

#import <CoreImage/CIContext.h>
#import <CoreImage/CIImage.h>
#import <objc/runtime.h>

NSString * const kCIContextOutputColorSpace = @"output_color_space";
NSString * const kCIContextUseSoftwareRenderer = @"software_renderer";
NSString * const kCIContextWorkingColorSpace = @"working_color_space";

@implementation CIContext

+ (CIContext *)context {
    return [[[self alloc] init] autorelease];
}

+ (CIContext *)contextWithOptions:(NSDictionary *)options {
    return [self context];
}

+ (CIContext *)contextWithCGContext:(CGContextRef)cgContext options:(NSDictionary *)options {
    CIContext *context = [self context];
    if (cgContext != NULL)
        context->_cgContext = CGContextRetain(cgContext);
    return context;
}

- (void)dealloc {
    if (_cgContext != NULL)
        CGContextRelease(_cgContext);
    [super dealloc];
}

// Images are already rendered: creating a CGImage only crops.
- (CGImageRef)createCGImage:(CIImage *)image fromRect:(CGRect)fromRect {
    CGImageRef cgImage = [[image imageByCroppingToRect: fromRect] CGImage];
    return cgImage != NULL ? CGImageRetain(cgImage) : NULL;
}

- (CGImageRef)createCGImage:(CIImage *)image fromRect:(CGRect)fromRect format:(int)format colorSpace:(CGColorSpaceRef)colorSpace {
    return [self createCGImage: image fromRect: fromRect];
}

- (void)drawImage:(CIImage *)image inRect:(CGRect)inRect fromRect:(CGRect)fromRect {
    if (_cgContext == NULL)
        return;
    CGImageRef cgImage = [[image imageByCroppingToRect: fromRect] CGImage];
    if (cgImage != NULL)
        CGContextDrawImage(_cgContext, inRect, cgImage);
}

- (void)drawImage:(CIImage *)image atPoint:(CGPoint)atPoint fromRect:(CGRect)fromRect {
    [self drawImage: image
             inRect: CGRectMake(atPoint.x, atPoint.y, fromRect.size.width, fromRect.size.height)
           fromRect: fromRect];
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
