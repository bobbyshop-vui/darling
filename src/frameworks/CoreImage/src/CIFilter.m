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

#import <CoreImage/CIFilter.h>

#import <Foundation/NSString.h>
#import <CoreImage/CIImage.h>
#import <objc/runtime.h>
#include <stdarg.h>
#include <math.h>

NSString * const kCIInputAngleKey = @"inputAngle";
NSString * const kCIInputBackgroundImageKey = @"inputBackgroundImage";
NSString * const kCIInputBrightnessKey = @"inputBrightness";
NSString * const kCIInputColorKey = @"inputColor";
NSString * const kCIInputContrastKey = @"inputContrast";
NSString * const kCIInputExtentKey = @"inputExtent";
NSString * const kCIInputImageKey = @"inputImage";
NSString * const kCIInputSaturationKey = @"inputSaturation";
NSString *const kCIInputRadiusKey = @"inputRadius";
NSString * const kCIOutputImageKey = @"outputImage";
NSString * const kCIApplyOptionDefinition = @"definition";

NSString * const kCIAttributeClass = @"class";
NSString * const kCIAttributeDisplayName = @"displayName";
NSString * const kCIAttributeFilterDisplayName = @"filterDisplayName";
NSString * const kCIAttributeFilterName = @"filterName";
NSString * const kCIAttributeMax = @"max";
NSString * const kCIAttributeMin = @"min";
NSString * const kCIAttributeType = @"type";

NSString * const kCIAttributeTypeAngle = @"angle";
NSString * const kCIAttributeTypeBoolean = @"boolean";
NSString * const kCIAttributeTypeDistance = @"distance";
NSString * const kCIAttributeTypeOffset = @"offset";
NSString * const kCIAttributeTypePosition = @"position";
NSString * const kCIAttributeTypePosition3 = @"position3";
NSString * const kCIAttributeTypeRectangle = @"rectangle";
NSString * const kCIAttributeTypeScalar = @"scalar";
NSString * const kCIAttributeTypeTime = @"time";

NSString * const kCICategoryCompositeOperation = @"kCICategoryCompositeOperation";
NSString * const kCICategoryGenerator = @"kCICategoryGenerator";
NSString * const kCICategoryGradient = @"kCICategoryGradient";
NSString * const kCICategoryReduction = @"kCICategoryReduction";
NSString * const kCICategoryTransition = @"kCICategoryTransition";

typedef void (*CIPixelOperation)(CIFilter *filter, float *rgb);

// The input keys and default values of the filters Darling implements.
static NSDictionary *CIFilterDefaults(NSString *name) {
    static NSDictionary *defaults = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        defaults = [[NSDictionary alloc] initWithObjectsAndKeys:
                [NSDictionary dictionary], @"CIColorInvert",
                [NSDictionary dictionaryWithObject: [NSNumber numberWithDouble: 0] forKey: kCIInputAngleKey], @"CIHueAdjust",
                [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithDouble: 1], kCIInputSaturationKey,
                        [NSNumber numberWithDouble: 0], kCIInputBrightnessKey,
                        [NSNumber numberWithDouble: 1], kCIInputContrastKey, nil], @"CIColorControls",
                nil];
    });
    return [defaults objectForKey: name];
}

static float CIFilterNumber(CIFilter *filter, NSString *key) {
    return [[filter valueForKey: key] floatValue];
}

static void CIColorInvertPixel(CIFilter *filter, float *rgb) {
    for (int i = 0; i < 3; i++)
        rgb[i] = 1 - rgb[i];
}

// The luminance-preserving hue rotation (as SVG's hueRotate).
static void CIHueAdjustPixel(CIFilter *filter, float *rgb) {
    float angle = CIFilterNumber(filter, kCIInputAngleKey);
    float c = cosf(angle), s = sinf(angle);
    float r = rgb[0], g = rgb[1], b = rgb[2];
    rgb[0] = (0.213f + c * 0.787f - s * 0.213f) * r + (0.715f - c * 0.715f - s * 0.715f) * g + (0.072f - c * 0.072f + s * 0.928f) * b;
    rgb[1] = (0.213f - c * 0.213f + s * 0.143f) * r + (0.715f + c * 0.285f + s * 0.140f) * g + (0.072f - c * 0.072f - s * 0.283f) * b;
    rgb[2] = (0.213f - c * 0.213f - s * 0.787f) * r + (0.715f - c * 0.715f + s * 0.715f) * g + (0.072f + c * 0.928f + s * 0.072f) * b;
}

static void CIColorControlsPixel(CIFilter *filter, float *rgb) {
    float saturation = CIFilterNumber(filter, kCIInputSaturationKey);
    float brightness = CIFilterNumber(filter, kCIInputBrightnessKey);
    float contrast = CIFilterNumber(filter, kCIInputContrastKey);
    float luminance = 0.2125f * rgb[0] + 0.7154f * rgb[1] + 0.0721f * rgb[2];
    for (int i = 0; i < 3; i++) {
        float value = luminance + (rgb[i] - luminance) * saturation;
        value += brightness;
        rgb[i] = (value - 0.5f) * contrast + 0.5f;
    }
}

static CIPixelOperation CIFilterOperation(NSString *name) {
    if ([name isEqualToString: @"CIColorInvert"])
        return CIColorInvertPixel;
    if ([name isEqualToString: @"CIHueAdjust"])
        return CIHueAdjustPixel;
    if ([name isEqualToString: @"CIColorControls"])
        return CIColorControlsPixel;
    return NULL;
}

// Renders the image into premultiplied RGBA, runs the operation on every
// pixel's unpremultiplied colour and returns the result.
static CIImage *CIApplyPixelOperation(CIFilter *filter, CIImage *input, CIPixelOperation operation) {
    CGImageRef image = [input CGImage];
    if (image == NULL)
        return input;
    size_t width = CGImageGetWidth(image), height = CGImageGetHeight(image);
    if (width == 0 || height == 0)
        return input;

    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap = CGBitmapContextCreate(NULL, width, height, 8, width * 4, space,
                                                kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(space);
    if (bitmap == NULL)
        return input;
    CGContextDrawImage(bitmap, CGRectMake(0, 0, width, height), image);

    uint8_t *pixels = CGBitmapContextGetData(bitmap);
    size_t rowBytes = CGBitmapContextGetBytesPerRow(bitmap);
    for (size_t y = 0; y < height; y++) {
        uint8_t *pixel = pixels + y * rowBytes;
        for (size_t x = 0; x < width; x++, pixel += 4) {
            float alpha = pixel[3] / 255.0f;
            if (alpha <= 0)
                continue;
            float rgb[3] = { pixel[0] / 255.0f / alpha, pixel[1] / 255.0f / alpha, pixel[2] / 255.0f / alpha };
            operation(filter, rgb);
            for (int i = 0; i < 3; i++) {
                float value = rgb[i] < 0 ? 0 : (rgb[i] > 1 ? 1 : rgb[i]);
                pixel[i] = (uint8_t)(value * alpha * 255.0f + 0.5f);
            }
        }
    }

    CGImageRef output = CGBitmapContextCreateImage(bitmap);
    CGContextRelease(bitmap);
    CIImage *result = [CIImage imageWithCGImage: output];
    CGImageRelease(output);
    return result;
}

@implementation CIFilter

+ (CIFilter *)filterWithName:(NSString *)name {
    if (CIFilterOperation(name) == NULL)
        return nil;
    CIFilter *filter = [[[self alloc] init] autorelease];
    filter->_name = [name copy];
    filter->_values = [[NSMutableDictionary alloc] init];
    return filter;
}

+ (CIFilter *)filterWithName:(NSString *)name keysAndValues:(id)key0, ... {
    CIFilter *filter = [self filterWithName: name];
    va_list arguments;
    va_start(arguments, key0);
    for (id key = key0; key != nil; key = va_arg(arguments, id)) {
        id value = va_arg(arguments, id);
        [filter setValue: value forKey: key];
    }
    va_end(arguments);
    return filter;
}

+ (CIFilter *)filterWithName:(NSString *)name withInputParameters:(NSDictionary *)params {
    CIFilter *filter = [self filterWithName: name];
    for (NSString *key in params)
        [filter setValue: [params objectForKey: key] forKey: key];
    return filter;
}

+ (NSArray *)filterNamesInCategory:(NSString *)category {
    return [NSArray arrayWithObjects: @"CIColorControls", @"CIColorInvert", @"CIHueAdjust", nil];
}

+ (NSArray *)filterNamesInCategories:(NSArray *)categories {
    return [self filterNamesInCategory: nil];
}

+ (NSString *)localizedNameForFilterName:(NSString *)filterName {
    return filterName;
}

- (void)dealloc {
    [_name release];
    [_values release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
    CIFilter *copy = [[[self class] allocWithZone: zone] init];
    copy->_name = [_name copy];
    copy->_values = [_values mutableCopy];
    return copy;
}

- (NSString *)name {
    return _name;
}

- (NSArray *)inputKeys {
    return [[NSArray arrayWithObject: kCIInputImageKey]
            arrayByAddingObjectsFromArray: [CIFilterDefaults(_name) allKeys]];
}

- (NSArray *)outputKeys {
    return [NSArray arrayWithObject: kCIOutputImageKey];
}

- (NSDictionary *)attributes {
    return [NSDictionary dictionaryWithObject: _name forKey: kCIAttributeFilterName];
}

- (void)setDefaults {
    [_values addEntriesFromDictionary: CIFilterDefaults(_name)];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if (value != nil)
        [_values setObject: value forKey: key];
    else
        [_values removeObjectForKey: key];
}

- (id)valueForKey:(NSString *)key {
    if ([key isEqualToString: kCIOutputImageKey])
        return [self outputImage];
    id value = [_values objectForKey: key];
    return value != nil ? value : [CIFilterDefaults(_name) objectForKey: key];
}

- (CIImage *)outputImage {
    CIImage *input = [_values objectForKey: kCIInputImageKey];
    CIPixelOperation operation = CIFilterOperation(_name);
    if (input == nil || operation == NULL)
        return nil;
    return CIApplyPixelOperation(self, input, operation);
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
