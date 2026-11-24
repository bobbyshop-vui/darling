#import <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>
#include <limits.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct __CVPixelBufferPool *CVPixelBufferPoolRef;
typedef struct __CVMetalTextureCache *CVMetalTextureCacheRef;
typedef CVImageBufferRef CVMetalTextureRef;
typedef NSUInteger MTLPixelFormat;
@protocol MTLDevice;
@protocol MTLTexture;

@interface DarlingLazyCVPixelBuffer : NSObject {
@public
	void *baseAddress;
	size_t width;
	size_t height;
	size_t bytesPerRow;
	OSType pixelFormatType;
	BOOL ownsBaseAddress;
	CVPixelBufferReleaseBytesCallback releaseCallback;
	void *releaseRefCon;
}
@end

@implementation DarlingLazyCVPixelBuffer
- (void)dealloc
{
	if (releaseCallback)
		releaseCallback(releaseRefCon, baseAddress);
	if (ownsBaseAddress)
		free(baseAddress);
	[super dealloc];
}
@end

@interface DarlingLazyCVPixelBufferPool : NSObject {
@public
	NSDictionary *poolAttributes;
	NSDictionary *pixelBufferAttributes;
}
@end

@implementation DarlingLazyCVPixelBufferPool
- (void)dealloc
{
	[poolAttributes release];
	[pixelBufferAttributes release];
	[super dealloc];
}
@end

static const CFStringRef kLazyCVDisplayLinkDisplaysKey = CFSTR("DarlingCVDisplayLinkDisplays");
static const CFStringRef kLazyCVDisplayLinkPausedKey = CFSTR("DarlingCVDisplayLinkPaused");
static const CFStringRef kLazyCVDisplayLinkOutputHandlerKey = CFSTR("DarlingCVDisplayLinkOutputHandler");

static size_t cvBytesPerPixel(OSType pixelFormatType)
{
	switch (pixelFormatType) {
	case kCVPixelFormatType_1Monochrome:
	case kCVPixelFormatType_2Indexed:
	case kCVPixelFormatType_4Indexed:
	case kCVPixelFormatType_8Indexed:
	case kCVPixelFormatType_1IndexedGray_WhiteIsZero:
	case kCVPixelFormatType_2IndexedGray_WhiteIsZero:
	case kCVPixelFormatType_4IndexedGray_WhiteIsZero:
	case kCVPixelFormatType_8IndexedGray_WhiteIsZero:
	case kCVPixelFormatType_OneComponent8:
		return 1;
	case kCVPixelFormatType_16BE555:
	case kCVPixelFormatType_16LE555:
	case kCVPixelFormatType_16LE5551:
	case kCVPixelFormatType_16BE565:
	case kCVPixelFormatType_16LE565:
	case kCVPixelFormatType_16Gray:
	case kCVPixelFormatType_422YpCbCr8:
	case kCVPixelFormatType_422YpCbCr8_yuvs:
	case kCVPixelFormatType_422YpCbCr8FullRange:
	case kCVPixelFormatType_TwoComponent8:
		return 2;
	case kCVPixelFormatType_24RGB:
	case kCVPixelFormatType_24BGR:
	case kCVPixelFormatType_48RGB:
		return pixelFormatType == kCVPixelFormatType_48RGB ? 6 : 3;
	case kCVPixelFormatType_32ARGB:
	case kCVPixelFormatType_32BGRA:
	case kCVPixelFormatType_32ABGR:
	case kCVPixelFormatType_32RGBA:
	case kCVPixelFormatType_32AlphaGray:
	case kCVPixelFormatType_4444YpCbCrA8:
	case kCVPixelFormatType_4444YpCbCrA8R:
	case kCVPixelFormatType_4444AYpCbCr8:
	case kCVPixelFormatType_30RGB:
	case kCVPixelFormatType_30RGBLEPackedWideGamut:
	case kCVPixelFormatType_ARGB2101010LEPacked:
	case kCVPixelFormatType_TwoComponent16Half:
	case kCVPixelFormatType_OneComponent16Half:
		return 4;
	case kCVPixelFormatType_64ARGB:
	case kCVPixelFormatType_64RGBAHalf:
	case kCVPixelFormatType_OneComponent32Float:
	case kCVPixelFormatType_TwoComponent32Float:
		return pixelFormatType == kCVPixelFormatType_64ARGB || pixelFormatType == kCVPixelFormatType_64RGBAHalf ? 8 : 4;
	case kCVPixelFormatType_128RGBAFloat:
		return 16;
	default:
		return 0;
	}
}

static BOOL cvReadUnsignedAttribute(CFDictionaryRef attributes, CFStringRef key, uint64_t *valueOut)
{
	if (!attributes || !key || !valueOut)
		return NO;
	CFTypeRef value = CFDictionaryGetValue(attributes, key);
	if (!value || CFGetTypeID(value) != CFNumberGetTypeID())
		return NO;
	int64_t number = 0;
	if (!CFNumberGetValue((CFNumberRef)value, kCFNumberSInt64Type, &number) || number < 0)
		return NO;
	*valueOut = (uint64_t)number;
	return YES;
}

static CVReturn cvCreatePixelBuffer(size_t width, size_t height, OSType pixelFormatType,
									void *baseAddress, size_t bytesPerRow, BOOL ownsBaseAddress,
									CVPixelBufferReleaseBytesCallback releaseCallback, void *releaseRefCon,
									CVPixelBufferRef *pixelBufferOut)
{
	if (pixelBufferOut)
		*pixelBufferOut = NULL;
	if (!pixelBufferOut || width == 0 || height == 0)
		return kCVReturnInvalidSize;

	size_t bytesPerPixel = cvBytesPerPixel(pixelFormatType);
	if (bytesPerPixel == 0)
		return kCVReturnInvalidPixelFormat;
	if (width > SIZE_MAX / bytesPerPixel)
		return kCVReturnInvalidSize;
	size_t minimumBytesPerRow = width * bytesPerPixel;
	if (!baseAddress && !ownsBaseAddress)
		return kCVReturnInvalidArgument;
	if (bytesPerRow < minimumBytesPerRow || height > SIZE_MAX / bytesPerRow)
		return kCVReturnInvalidSize;

	DarlingLazyCVPixelBuffer *buffer = [[DarlingLazyCVPixelBuffer alloc] init];
	if (!buffer)
		return kCVReturnAllocationFailed;
	buffer->baseAddress = baseAddress;
	buffer->width = width;
	buffer->height = height;
	buffer->bytesPerRow = bytesPerRow;
	buffer->pixelFormatType = pixelFormatType;
	buffer->ownsBaseAddress = ownsBaseAddress;
	buffer->releaseCallback = releaseCallback;
	buffer->releaseRefCon = releaseRefCon;
	*pixelBufferOut = (CVPixelBufferRef)buffer;
	return kCVReturnSuccess;
}

CV_EXPORT CVReturn CVDisplayLinkCreateWithCGDisplays(CGDirectDisplayID *displayArray, CFIndex count, CVDisplayLinkRef *displayLinkOut)
{
	if (displayLinkOut)
		*displayLinkOut = NULL;
	if (!displayLinkOut || !displayArray || count <= 0)
		return kCVReturnInvalidArgument;

	NSMutableArray *displays = [NSMutableArray arrayWithCapacity:(NSUInteger)count];
	for (CFIndex i = 0; i < count; ++i)
		[displays addObject:[NSNumber numberWithUnsignedInt:displayArray[i]]];
	NSMutableDictionary *displayLink = [[NSMutableDictionary alloc] init];
	if (!displayLink)
		return kCVReturnAllocationFailed;
	[displayLink setObject:displays forKey:(NSString *)kLazyCVDisplayLinkDisplaysKey];
	[displayLink setObject:[NSNumber numberWithBool:NO] forKey:(NSString *)kLazyCVDisplayLinkPausedKey];
	*displayLinkOut = (CVDisplayLinkRef)displayLink;
	return kCVReturnSuccess;
}

CV_EXPORT CVReturn CVDisplayLinkSetCurrentCGDisplay(CVDisplayLinkRef displayLink, CGDirectDisplayID displayID)
{
	if (!displayLink)
		return kCVReturnInvalidArgument;
	if (displayID == kCGNullDirectDisplay)
		return kCVReturnInvalidDisplay;
	NSMutableDictionary *state = (NSMutableDictionary *)displayLink;
	[state setObject:@[[NSNumber numberWithUnsignedInt:displayID]] forKey:(NSString *)kLazyCVDisplayLinkDisplaysKey];
	return kCVReturnSuccess;
}

CV_EXPORT CVReturn CVDisplayLinkSetOutputHandler(CVDisplayLinkRef displayLink, CVDisplayLinkOutputHandler handler)
{
	if (!displayLink || !handler)
		return kCVReturnInvalidArgument;
	NSMutableDictionary *state = (NSMutableDictionary *)displayLink;
	id copiedHandler = [handler copy];
	if (!copiedHandler)
		return kCVReturnAllocationFailed;
	[state setObject:[copiedHandler autorelease] forKey:(NSString *)kLazyCVDisplayLinkOutputHandlerKey];
	return kCVReturnSuccess;
}

CV_EXPORT void CVDisplayLinkSetPaused(CVDisplayLinkRef displayLink, Boolean paused)
{
	if (!displayLink)
		return;
	NSMutableDictionary *state = (NSMutableDictionary *)displayLink;
	[state setObject:[NSNumber numberWithBool:paused] forKey:(NSString *)kLazyCVDisplayLinkPausedKey];
}

CV_EXPORT CVReturn CVMetalTextureCacheCreate(CFAllocatorRef allocator, CFDictionaryRef cacheAttributes,
											 id<MTLDevice> metalDevice, CFDictionaryRef textureAttributes,
											 CVMetalTextureCacheRef *cacheOut)
{
	(void)allocator;
	(void)cacheAttributes;
	(void)metalDevice;
	(void)textureAttributes;
	if (cacheOut)
		*cacheOut = NULL;
	return cacheOut ? kCVReturnError : kCVReturnInvalidArgument;
}

CV_EXPORT CVReturn CVMetalTextureCacheCreateTextureFromImage(CFAllocatorRef allocator, CVMetalTextureCacheRef textureCache,
														 CVImageBufferRef sourceImage, CFDictionaryRef textureAttributes,
														 MTLPixelFormat pixelFormat, size_t width, size_t height,
														 size_t planeIndex, CVMetalTextureRef *textureOut)
{
	(void)allocator;
	(void)textureCache;
	(void)sourceImage;
	(void)textureAttributes;
	(void)pixelFormat;
	(void)width;
	(void)height;
	(void)planeIndex;
	if (textureOut)
		*textureOut = NULL;
	return textureOut ? kCVReturnError : kCVReturnInvalidArgument;
}

CV_EXPORT void CVMetalTextureCacheFlush(void *textureCache, CVOptionFlags options)
{
	(void)textureCache;
	(void)options;
}

CV_EXPORT id<MTLTexture> CVMetalTextureGetTexture(CVMetalTextureRef image)
{
	(void)image;
	return nil;
}

CV_EXPORT CVReturn CVPixelBufferCreate(CFAllocatorRef allocator, size_t width, size_t height,
									   OSType pixelFormatType, CFDictionaryRef pixelBufferAttributes,
									   CVPixelBufferRef *pixelBufferOut)
{
	(void)allocator;
	(void)pixelBufferAttributes;
	if (pixelFormatType == 0)
		return pixelBufferOut ? (*pixelBufferOut = NULL, kCVReturnInvalidPixelFormat) : kCVReturnInvalidArgument;

	size_t bytesPerPixel = cvBytesPerPixel(pixelFormatType);
	if (bytesPerPixel == 0)
		return pixelBufferOut ? (*pixelBufferOut = NULL, kCVReturnInvalidPixelFormat) : kCVReturnInvalidArgument;
	if (width > SIZE_MAX / bytesPerPixel)
		return pixelBufferOut ? (*pixelBufferOut = NULL, kCVReturnInvalidSize) : kCVReturnInvalidArgument;
	size_t bytesPerRow = width * bytesPerPixel;
	uint64_t alignment = 0;
	if (cvReadUnsignedAttribute(pixelBufferAttributes, kCVPixelBufferBytesPerRowAlignmentKey, &alignment) && alignment > 1) {
		if (bytesPerRow > SIZE_MAX - (size_t)alignment + 1)
			return pixelBufferOut ? (*pixelBufferOut = NULL, kCVReturnInvalidSize) : kCVReturnInvalidArgument;
		bytesPerRow = ((bytesPerRow + (size_t)alignment - 1) / (size_t)alignment) * (size_t)alignment;
	}
	if (height == 0 || bytesPerRow == 0 || height > SIZE_MAX / bytesPerRow)
		return pixelBufferOut ? (*pixelBufferOut = NULL, kCVReturnInvalidSize) : kCVReturnInvalidArgument;
	void *bytes = calloc(height, bytesPerRow);
	if (!bytes)
		return pixelBufferOut ? (*pixelBufferOut = NULL, kCVReturnAllocationFailed) : kCVReturnInvalidArgument;
	CVReturn result = cvCreatePixelBuffer(width, height, pixelFormatType, bytes, bytesPerRow, YES, NULL, NULL, pixelBufferOut);
	if (result != kCVReturnSuccess)
		free(bytes);
	return result;
}

CV_EXPORT CVReturn CVPixelBufferCreateWithBytes(CFAllocatorRef allocator, size_t width, size_t height,
												OSType pixelFormatType, void *baseAddress, size_t bytesPerRow,
												CVPixelBufferReleaseBytesCallback releaseCallback, void *releaseRefCon,
												CFDictionaryRef pixelBufferAttributes, CVPixelBufferRef *pixelBufferOut)
{
	(void)allocator;
	(void)pixelBufferAttributes;
	return cvCreatePixelBuffer(width, height, pixelFormatType, baseAddress, bytesPerRow, NO,
							   releaseCallback, releaseRefCon, pixelBufferOut);
}

CV_EXPORT size_t CVPixelBufferGetBytesPerRow(CVPixelBufferRef pixelBuffer)
{
	return pixelBuffer ? ((DarlingLazyCVPixelBuffer *)pixelBuffer)->bytesPerRow : 0;
}

CV_EXPORT size_t CVPixelBufferGetHeightOfPlane(CVPixelBufferRef pixelBuffer, size_t planeIndex)
{
	(void)planeIndex;
	(void)pixelBuffer;
	return 0;
}

CV_EXPORT OSType CVPixelBufferGetPixelFormatType(CVPixelBufferRef pixelBuffer)
{
	return pixelBuffer ? ((DarlingLazyCVPixelBuffer *)pixelBuffer)->pixelFormatType : 0;
}

CV_EXPORT size_t CVPixelBufferGetWidthOfPlane(CVPixelBufferRef pixelBuffer, size_t planeIndex)
{
	(void)planeIndex;
	(void)pixelBuffer;
	return 0;
}

CV_EXPORT CVPixelBufferRef CVPixelBufferRetain(CVPixelBufferRef pixelBuffer)
{
	return pixelBuffer ? (CVPixelBufferRef)[(DarlingLazyCVPixelBuffer *)pixelBuffer retain] : NULL;
}

CV_EXPORT void CVPixelBufferRelease(CVPixelBufferRef pixelBuffer)
{
	[(DarlingLazyCVPixelBuffer *)pixelBuffer release];
}

CV_EXPORT CVReturn CVPixelBufferPoolCreate(CFAllocatorRef allocator, CFDictionaryRef poolAttributesIn,
										   CFDictionaryRef pixelBufferAttributesIn,
										   CVPixelBufferPoolRef *poolOut)
{
	(void)allocator;
	if (poolOut)
		*poolOut = NULL;
	uint64_t width = 0, height = 0, pixelFormat = 0;
	if (!poolOut || !pixelBufferAttributesIn ||
		!cvReadUnsignedAttribute(pixelBufferAttributesIn, kCVPixelBufferWidthKey, &width) ||
		!cvReadUnsignedAttribute(pixelBufferAttributesIn, kCVPixelBufferHeightKey, &height) ||
		!cvReadUnsignedAttribute(pixelBufferAttributesIn, kCVPixelBufferPixelFormatTypeKey, &pixelFormat) ||
		width == 0 || height == 0 || cvBytesPerPixel((OSType)pixelFormat) == 0)
		return poolOut ? kCVReturnInvalidPixelBufferAttributes : kCVReturnInvalidArgument;

	DarlingLazyCVPixelBufferPool *pool = [[DarlingLazyCVPixelBufferPool alloc] init];
	if (!pool)
		return kCVReturnAllocationFailed;
	pool->poolAttributes = [(NSDictionary *)poolAttributesIn copy];
	pool->pixelBufferAttributes = [(NSDictionary *)pixelBufferAttributesIn copy];
	*poolOut = (CVPixelBufferPoolRef)pool;
	return kCVReturnSuccess;
}

CV_EXPORT CVReturn CVPixelBufferPoolCreatePixelBuffer(CFAllocatorRef allocator, CVPixelBufferPoolRef pixelBufferPool,
											  CVPixelBufferRef *pixelBufferOut)
{
	(void)allocator;
	if (pixelBufferOut)
		*pixelBufferOut = NULL;
	if (!pixelBufferPool || !pixelBufferOut)
		return kCVReturnInvalidArgument;
	DarlingLazyCVPixelBufferPool *pool = (DarlingLazyCVPixelBufferPool *)pixelBufferPool;
	uint64_t width = 0, height = 0, pixelFormat = 0;
	if (!cvReadUnsignedAttribute((CFDictionaryRef)pool->pixelBufferAttributes, kCVPixelBufferWidthKey, &width) ||
		!cvReadUnsignedAttribute((CFDictionaryRef)pool->pixelBufferAttributes, kCVPixelBufferHeightKey, &height) ||
		!cvReadUnsignedAttribute((CFDictionaryRef)pool->pixelBufferAttributes, kCVPixelBufferPixelFormatTypeKey, &pixelFormat))
		return kCVReturnInvalidPixelBufferAttributes;
	return CVPixelBufferCreate(NULL, (size_t)width, (size_t)height, (OSType)pixelFormat,
							  (CFDictionaryRef)pool->pixelBufferAttributes, pixelBufferOut);
}

CV_EXPORT void CVPixelBufferPoolRelease(CVPixelBufferPoolRef pixelBufferPool)
{
	[(DarlingLazyCVPixelBufferPool *)pixelBufferPool release];
}
