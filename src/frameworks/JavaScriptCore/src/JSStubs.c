// Stub implementation of the JavaScriptCore C API entry points that Xcode's
// GPUTools, MTLTools and SpriteKit bind. There is no JavaScript engine behind
// them: strings work, everything that would need an engine reports "no value".
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

typedef const void *JSValueRef;
typedef void *JSObjectRef;
typedef const void *JSContextRef;
typedef const void *JSContextRefConst;

struct OpaqueJSString {
	char *utf8;
	size_t length16;
	int refcount;
};
typedef struct OpaqueJSString *JSStringRef;

static size_t utf16_length(const char *s)
{
	size_t n = 0;
	const unsigned char *p = (const unsigned char *) s;
	while (*p) {
		unsigned char c = *p;
		if (c < 0x80) { n += 1; p += 1; }
		else if ((c >> 5) == 0x6) { n += 1; p += 2; }
		else if ((c >> 4) == 0xE) { n += 1; p += 3; }
		else if ((c >> 3) == 0x1E) { n += 2; p += 4; }
		else { n += 1; p += 1; }
		// stop on a truncated sequence rather than run off the terminator
		if (p > (const unsigned char *) s + strlen(s)) break;
	}
	return n;
}

JSStringRef JSStringCreateWithUTF8CString(const char *string)
{
	JSStringRef r = (JSStringRef) calloc(1, sizeof(*r));
	if (r == NULL)
		return NULL;
	r->utf8 = strdup(string ? string : "");
	r->length16 = utf16_length(r->utf8);
	r->refcount = 1;
	return r;
}

JSStringRef JSStringRetain(JSStringRef string)
{
	if (string)
		__sync_fetch_and_add(&string->refcount, 1);
	return string;
}

void JSStringRelease(JSStringRef string)
{
	if (string && __sync_sub_and_fetch(&string->refcount, 1) == 0) {
		free(string->utf8);
		free(string);
	}
}

size_t JSStringGetLength(JSStringRef string)
{
	return string ? string->length16 : 0;
}

size_t JSStringGetUTF8CString(JSStringRef string, char *buffer, size_t bufferSize)
{
	if (string == NULL || buffer == NULL || bufferSize == 0)
		return 0;
	size_t n = strlen(string->utf8);
	if (n > bufferSize - 1)
		n = bufferSize - 1;
	memcpy(buffer, string->utf8, n);
	buffer[n] = '\0';
	return n + 1;
}

static void clear_exception(JSValueRef *exception)
{
	if (exception)
		*exception = NULL;
}

JSObjectRef JSContextGetGlobalObject(JSContextRef ctx)
{
	return NULL;
}

JSValueRef JSObjectCallAsFunction(JSContextRef ctx, JSObjectRef object, JSObjectRef thisObject,
		size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception)
{
	clear_exception(exception);
	return NULL;
}

JSValueRef JSObjectGetProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName,
		JSValueRef *exception)
{
	clear_exception(exception);
	return NULL;
}

void JSObjectSetProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName,
		JSValueRef value, unsigned attributes, JSValueRef *exception)
{
	clear_exception(exception);
}

JSStringRef JSValueCreateJSONString(JSContextRef ctx, JSValueRef value, unsigned indent,
		JSValueRef *exception)
{
	clear_exception(exception);
	return NULL;
}

JSValueRef JSValueMakeFromJSONString(JSContextRef ctx, JSStringRef string)
{
	return NULL;
}

JSValueRef JSValueMakeNumber(JSContextRef ctx, double number)
{
	return NULL;
}

double JSValueToNumber(JSContextRef ctx, JSValueRef value, JSValueRef *exception)
{
	clear_exception(exception);
	return NAN;
}

JSObjectRef JSValueToObject(JSContextRef ctx, JSValueRef value, JSValueRef *exception)
{
	clear_exception(exception);
	return NULL;
}

JSStringRef JSValueToStringCopy(JSContextRef ctx, JSValueRef value, JSValueRef *exception)
{
	clear_exception(exception);
	return NULL;
}
