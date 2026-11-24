#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <math.h>

typedef unsigned long vImagePixelCount;
typedef intptr_t vImage_Error;
typedef uint32_t vImage_Flags;
typedef float Pixel_F;

typedef struct vImage_Buffer {
	void *data;
	vImagePixelCount height;
	vImagePixelCount width;
	size_t rowBytes;
} vImage_Buffer;

typedef struct vImage_YpCbCrToARGBMatrix {
	float Yp;
	float Cr_R;
	float Cr_G;
	float Cb_G;
	float Cb_B;
} vImage_YpCbCrToARGBMatrix;

typedef struct vImage_YpCbCrPixelRange {
	int32_t Yp_bias;
	int32_t CbCr_bias;
	int32_t YpRangeMax;
	int32_t CbCrRangeMax;
	int32_t YpMax;
	int32_t YpMin;
	int32_t CbCrMax;
	int32_t CbCrMin;
} vImage_YpCbCrPixelRange;

typedef struct vImage_YpCbCrToARGB {
	uint8_t opaque[128] __attribute__((aligned(16)));
} vImage_YpCbCrToARGB;

enum {
	kvImageNoError = 0,
	kvImageRoiLargerThanInputBuffer = -21766,
	kvImageInvalidKernelSize = -21767,
	kvImageNullPointerArgument = -21772,
	kvImageInvalidParameter = -21773,
	kvImageBufferSizeMismatch = -21774,
	kvImageHighQualityResampling = 32,
	kvImageEdgeExtend = 8,
	kvImageBackgroundColorFill = 4,
	kvImage422YpCbYpCr8 = 1,
	kvImageARGB8888 = 0
};

static int valid_rgba_buffer(const vImage_Buffer *buffer)
{
	return buffer && (!buffer->width || !buffer->height ||
		(buffer->data && buffer->width <= SIZE_MAX / 4 && buffer->rowBytes >= buffer->width * 4));
}

static uint8_t clamp_byte(float value)
{
	if (!(value > 0.0f)) return 0;
	if (value >= 255.0f) return 255;
	return (uint8_t)roundf(value);
}

vImage_Error vImageScale_ARGB8888(const vImage_Buffer *src, const vImage_Buffer *dest,
								  void *tempBuffer, vImage_Flags flags)
{
	(void)tempBuffer;
	if (!src || !dest) return kvImageNullPointerArgument;
	if (!valid_rgba_buffer(src) || !valid_rgba_buffer(dest)) return kvImageInvalidParameter;
	if (!src->width || !src->height || !dest->width || !dest->height) return kvImageNoError;
	const int smooth = (flags & kvImageHighQualityResampling) != 0;
	for (vImagePixelCount y = 0; y < dest->height; ++y) {
		uint8_t *out = (uint8_t *)dest->data + y * dest->rowBytes;
		double sy = ((double)y + 0.5) * (double)src->height / (double)dest->height - 0.5;
		if (sy < 0) sy = 0;
		if (sy > (double)(src->height - 1)) sy = (double)(src->height - 1);
		vImagePixelCount y0 = (vImagePixelCount)sy;
		vImagePixelCount y1 = y0 + (y0 + 1 < src->height ? 1 : 0);
		double fy = sy - (double)y0;
		const uint8_t *row0 = (const uint8_t *)src->data + y0 * src->rowBytes;
		const uint8_t *row1 = (const uint8_t *)src->data + y1 * src->rowBytes;
		for (vImagePixelCount x = 0; x < dest->width; ++x) {
			double sx = ((double)x + 0.5) * (double)src->width / (double)dest->width - 0.5;
			if (sx < 0) sx = 0;
			if (sx > (double)(src->width - 1)) sx = (double)(src->width - 1);
			vImagePixelCount x0 = (vImagePixelCount)sx;
			vImagePixelCount x1 = x0 + (x0 + 1 < src->width ? 1 : 0);
			double fx = sx - (double)x0;
			const uint8_t *p00 = row0 + x0 * 4;
			const uint8_t *p01 = row0 + x1 * 4;
			const uint8_t *p10 = row1 + x0 * 4;
			const uint8_t *p11 = row1 + x1 * 4;
			for (int c = 0; c < 4; ++c) {
				if (!smooth) {
					out[x * 4 + c] = row0[(vImagePixelCount)(sx + 0.5) * 4 + c];
				} else {
					double top = p00[c] * (1.0 - fx) + p01[c] * fx;
					double bottom = p10[c] * (1.0 - fx) + p11[c] * fx;
					out[x * 4 + c] = clamp_byte((float)(top * (1.0 - fy) + bottom * fy));
				}
			}
		}
	}
	return kvImageNoError;
}

vImage_Error vImageOverwriteChannels_ARGB8888(const vImage_Buffer *newSrc,
											 const vImage_Buffer *origSrc,
											 const vImage_Buffer *dest,
											 uint8_t copyMask, vImage_Flags flags)
{
	(void)flags;
	if (!newSrc || !origSrc || !dest) return kvImageNullPointerArgument;
	if (!valid_rgba_buffer(origSrc) || !valid_rgba_buffer(dest) ||
		(!newSrc->data && dest->width && dest->height)) return kvImageInvalidParameter;
	if (dest->width > origSrc->width || dest->height > origSrc->height ||
		dest->width > newSrc->width || dest->height > newSrc->height)
		return kvImageRoiLargerThanInputBuffer;
	if (newSrc->rowBytes < dest->width) return kvImageInvalidParameter;
	static const uint8_t bits[4] = { 0x8, 0x4, 0x2, 0x1 };
	for (vImagePixelCount y = 0; y < dest->height; ++y) {
		const uint8_t *plane = (const uint8_t *)newSrc->data + y * newSrc->rowBytes;
		const uint8_t *original = (const uint8_t *)origSrc->data + y * origSrc->rowBytes;
		uint8_t *output = (uint8_t *)dest->data + y * dest->rowBytes;
		for (vImagePixelCount x = 0; x < dest->width; ++x) {
			uint8_t pixel[4];
			memcpy(pixel, original + x * 4, 4);
			for (int c = 0; c < 4; ++c)
				if (copyMask & bits[c]) pixel[c] = plane[x];
			memcpy(output + x * 4, pixel, 4);
		}
	}
	return kvImageNoError;
}

vImage_Error vImageConvolve_PlanarF(const vImage_Buffer *src, const vImage_Buffer *dest,
									void *tempBuffer, vImagePixelCount srcOffsetToROI_X,
									vImagePixelCount srcOffsetToROI_Y, const float *kernel,
									uint32_t kernel_height, uint32_t kernel_width,
									Pixel_F backgroundColor, vImage_Flags flags)
{
	(void)tempBuffer;
	if (!src || !dest || !kernel) return kvImageNullPointerArgument;
	if (!src->data || !dest->data || !src->width || !src->height || !dest->width || !dest->height ||
		src->rowBytes < src->width * sizeof(float) || dest->rowBytes < dest->width * sizeof(float))
		return kvImageInvalidParameter;
	if (!kernel_width || !kernel_height || !(kernel_width & 1) || !(kernel_height & 1))
		return kvImageInvalidKernelSize;
	if (srcOffsetToROI_X > src->width || srcOffsetToROI_Y > src->height)
		return kvImageInvalidParameter;
	const int edge = (flags & kvImageEdgeExtend) ? kvImageEdgeExtend :
		((flags & kvImageBackgroundColorFill) ? kvImageBackgroundColorFill : 0);
	for (vImagePixelCount y = 0; y < dest->height; ++y) {
		float *out = (float *)((uint8_t *)dest->data + y * dest->rowBytes);
		for (vImagePixelCount x = 0; x < dest->width; ++x) {
			double sum = 0.0;
			for (uint32_t ky = 0; ky < kernel_height; ++ky) {
				for (uint32_t kx = 0; kx < kernel_width; ++kx) {
					long long sx = (long long)x + (long long)srcOffsetToROI_X + (long long)kx - (long long)kernel_width / 2;
					long long sy = (long long)y + (long long)srcOffsetToROI_Y + (long long)ky - (long long)kernel_height / 2;
					float pixel = backgroundColor;
					if (edge == kvImageEdgeExtend) {
						if (sx < 0) sx = 0;
						if (sy < 0) sy = 0;
					if ((vImagePixelCount)sx >= src->width) sx = (long long)src->width - 1;
					if ((vImagePixelCount)sy >= src->height) sy = (long long)src->height - 1;
										pixel = *(const float *)((const uint8_t *)src->data + (vImagePixelCount)sy * src->rowBytes + (vImagePixelCount)sx * sizeof(float));
				} else if (sx >= 0 && sy >= 0 && (vImagePixelCount)sx < src->width && (vImagePixelCount)sy < src->height) {
					pixel = *(const float *)((const uint8_t *)src->data + (vImagePixelCount)sy * src->rowBytes + (vImagePixelCount)sx * sizeof(float));
				}
				sum += (double)pixel * kernel[(vImagePixelCount)ky * kernel_width + kx];
				}
			}
			out[x] = (float)sum;
		}
	}
	return kvImageNoError;
}

typedef struct {
	uint32_t magic;
	float coefficients[5];
	vImage_YpCbCrPixelRange range;
} LazyYpCbCrInfo;

#define LAZY_YCBCR_MAGIC 0x58435943u

vImage_Error vImageConvert_YpCbCrToARGB_GenerateConversion(
	const vImage_YpCbCrToARGBMatrix *matrix, const vImage_YpCbCrPixelRange *range,
	vImage_YpCbCrToARGB *outInfo, int inYpCbCrType, int outARGBType, vImage_Flags flags)
{
	(void)flags;
	if (!matrix || !range || !outInfo) return kvImageNullPointerArgument;
	if (inYpCbCrType != kvImage422YpCbYpCr8 || outARGBType != kvImageARGB8888 ||
		range->YpRangeMax == range->Yp_bias || range->CbCrRangeMax == range->CbCr_bias)
		return kvImageInvalidParameter;
	LazyYpCbCrInfo info = { LAZY_YCBCR_MAGIC,
		{ matrix->Yp, matrix->Cr_R, matrix->Cr_G, matrix->Cb_G, matrix->Cb_B }, *range };
	memset(outInfo, 0, sizeof(*outInfo));
	memcpy(outInfo->opaque, &info, sizeof(info));
	return kvImageNoError;
}

vImage_Error vImageConvert_422YpCbYpCr8ToARGB8888(const vImage_Buffer *src,
												 const vImage_Buffer *dest,
												 const vImage_YpCbCrToARGB *info,
												 const uint8_t permuteMap[4], uint8_t alpha,
												 vImage_Flags flags)
{
	(void)flags;
	if (!src || !dest || !info) return kvImageNullPointerArgument;
	if (!valid_rgba_buffer(dest) || !src->data) return kvImageInvalidParameter;
	if (dest->width > src->width || dest->height > src->height ||
		src->width > SIZE_MAX / 2 || src->rowBytes < ((src->width + 1) / 2) * 4)
		return kvImageRoiLargerThanInputBuffer;
	LazyYpCbCrInfo conversion;
	memcpy(&conversion, info->opaque, sizeof(conversion));
	if (conversion.magic != LAZY_YCBCR_MAGIC) return kvImageInvalidParameter;
	for (int i = 0; i < 4; ++i)
		if (permuteMap && permuteMap[i] > 3) return kvImageInvalidParameter;
	const vImage_YpCbCrPixelRange *range = &conversion.range;
	for (vImagePixelCount y = 0; y < dest->height; ++y) {
		const uint8_t *in = (const uint8_t *)src->data + y * src->rowBytes;
		uint8_t *out = (uint8_t *)dest->data + y * dest->rowBytes;
		for (vImagePixelCount x = 0; x < dest->width; x += 2) {
			uint8_t y0 = in[0], cb = in[1], y1 = in[2], cr = in[3];
			in += 4;
			for (int pixel = 0; pixel < 2 && x + (vImagePixelCount)pixel < dest->width; ++pixel) {
				float encodedY = pixel ? y1 : y0;
				if (encodedY < range->YpMin) encodedY = (float)range->YpMin;
				if (encodedY > range->YpMax) encodedY = (float)range->YpMax;
				float encodedCb = cb, encodedCr = cr;
				if (encodedCb < range->CbCrMin) encodedCb = (float)range->CbCrMin;
				if (encodedCb > range->CbCrMax) encodedCb = (float)range->CbCrMax;
				if (encodedCr < range->CbCrMin) encodedCr = (float)range->CbCrMin;
				if (encodedCr > range->CbCrMax) encodedCr = (float)range->CbCrMax;
				float yp = (encodedY - range->Yp_bias) / (float)(range->YpRangeMax - range->Yp_bias);
				float cbValue = 0.5f * (encodedCb - range->CbCr_bias) / (float)(range->CbCrRangeMax - range->CbCr_bias);
				float crValue = 0.5f * (encodedCr - range->CbCr_bias) / (float)(range->CbCrRangeMax - range->CbCr_bias);
				uint8_t argb[4] = {
					alpha,
					clamp_byte((yp * conversion.coefficients[0] + crValue * conversion.coefficients[1]) * 255.0f),
					clamp_byte((yp * conversion.coefficients[0] + cbValue * conversion.coefficients[3] + crValue * conversion.coefficients[2]) * 255.0f),
					clamp_byte((yp * conversion.coefficients[0] + cbValue * conversion.coefficients[4]) * 255.0f)
				};
				uint8_t *outPixel = out + (x + (vImagePixelCount)pixel) * 4;
				for (int c = 0; c < 4; ++c)
					outPixel[c] = argb[permuteMap ? permuteMap[c] : c];
			}
		}
	}
	return kvImageNoError;
}
