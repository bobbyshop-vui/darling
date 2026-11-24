// Stub of libate: no texture encoder is available, so creation fails and the
// remaining entry points do nothing.
#include <stddef.h>

void *at_encoder_create(void)
{
	return NULL;
}

float at_encoder_compress_texels(void)
{
	return 0.0f;
}

float at_encoder_decompress_texels(void)
{
	return 0.0f;
}

unsigned long long at_encoder_get_block_counts(void)
{
	return 0;
}

unsigned long long at_encoder_get_block_size(void)
{
	return 0;
}
