#import <ImageIO/ImageIO.h>
#import <CoreGraphics/CGBitmapContext.h>
#import <CoreGraphics/CGColorSpace.h>
#include <math.h>
#include <stdint.h>

CFArrayRef CGImageSourceCopyTypeIdentifiers(void)
{
	const CFStringRef identifiers[] = {
		CFSTR("public.png"),
		CFSTR("public.jpeg"),
		CFSTR("public.tiff"),
		CFSTR("com.microsoft.bmp"),
		CFSTR("com.compuserve.gif"),
		CFSTR("com.apple.icns")
	};
	return CFArrayCreate(kCFAllocatorDefault, (const void **) identifiers,
						 sizeof(identifiers) / sizeof(identifiers[0]),
						 &kCFTypeArrayCallBacks);
}

CGImageRef CGImageSourceCreateThumbnailAtIndex(CGImageSourceRef source, size_t index,
														 CFDictionaryRef options)
{
	if (source == NULL || index >= CGImageSourceGetCount(source))
		return NULL;

	CGImageRef image = CGImageSourceCreateImageAtIndex(source, index, options);
	if (image == NULL)
		return NULL;

	CFNumberRef maxPixelValue = options == NULL ? NULL :
		(CFNumberRef) CFDictionaryGetValue(options, kCGImageSourceThumbnailMaxPixelSize);
	long maxPixel = 0;
	if (maxPixelValue == NULL || CFGetTypeID(maxPixelValue) != CFNumberGetTypeID() ||
		!CFNumberGetValue(maxPixelValue, kCFNumberLongType, &maxPixel) || maxPixel <= 0)
		return image;

	size_t width = CGImageGetWidth(image);
	size_t height = CGImageGetHeight(image);
	size_t largestSide = width > height ? width : height;
	if (largestSide == 0 || largestSide <= (size_t) maxPixel)
		return image;

	double scale = (double) maxPixel / (double) largestSide;
	size_t thumbWidth = (size_t) floor((double) width * scale + 0.5);
	size_t thumbHeight = (size_t) floor((double) height * scale + 0.5);
	if (thumbWidth == 0)
		thumbWidth = 1;
	if (thumbHeight == 0)
		thumbHeight = 1;
	if (thumbWidth > SIZE_MAX / 4)
		return image;

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	if (colorSpace == NULL)
		return image;
	CGContextRef context = CGBitmapContextCreate(NULL, thumbWidth, thumbHeight, 8,
												 thumbWidth * 4, colorSpace,
												 kCGImageAlphaPremultipliedLast |
												 kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(colorSpace);
	if (context == NULL)
		return image;

	CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
	CGContextDrawImage(context, CGRectMake(0, 0, thumbWidth, thumbHeight), image);
	CGImageRef thumbnail = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	CGImageRelease(image);
	return thumbnail;
}
