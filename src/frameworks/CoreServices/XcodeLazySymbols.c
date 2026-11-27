/*
 * Lazily bound CoreServices entry points used by Xcode 10.
 *
 * Functions that have a usable backend in Darling are implemented for real
 * (path based Trash move, FSIsAliasFile, ASN helpers, LS registration, ...).
 * Everything that would need Spotlight, AppleEvent transport or a real
 * LaunchServices database returns the "nothing available" result of the real
 * API: NULL / 0 / an error code, with out parameters always initialised.
 */

#include <CoreFoundation/CoreFoundation.h>
#include <AE/AE.h>
#include <CarbonCore/MacErrors.h>
#include <CarbonCore/Files.h>
#include <LaunchServices/LaunchServices.h>
#include <FSEvents/FSEvents.h>

#include <errno.h>
#include <mach/machine.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#ifndef typeNull
#define typeNull 0x6E756C6C /* 'null' */
#endif

#define XCODE_EXPORT __attribute__((visibility("default")))

/* ------------------------------------------------------------------------ */
/* AppleEvents                                                              */
/* ------------------------------------------------------------------------ */

static void xcodeNullDesc(AEDesc *desc)
{
	if (desc != NULL) {
		desc->descriptorType = typeNull;
		desc->dataHandle = NULL;
	}
}

/* Darling's AE implementation keeps no descriptor storage, so descriptors
 * never carry data or children. */

XCODE_EXPORT OSErr AEGetDescData(const AEDesc *theAEDesc, void *dataPtr, Size maximumSize)
{
	if (theAEDesc == NULL || (dataPtr == NULL && maximumSize > 0) || maximumSize < 0)
		return paramErr;
	if (maximumSize > 0)
		memset(dataPtr, 0, (size_t) maximumSize);
	return errAEWrongDataType;
}

XCODE_EXPORT OSErr AEGetParamDesc(const AppleEvent *theAppleEvent, AEKeyword theAEKeyword,
		DescType desiredType, AEDesc *result)
{
	(void) theAEKeyword;
	(void) desiredType;
	xcodeNullDesc(result);
	if (theAppleEvent == NULL || result == NULL)
		return paramErr;
	return errAEDescNotFound;
}

XCODE_EXPORT OSErr AEPutDesc(AEDescList *theAEDescList, long index, const AEDesc *theAEDesc)
{
	(void) index;
	if (theAEDescList == NULL || theAEDesc == NULL)
		return paramErr;
	return errAEWrongDataType;
}

XCODE_EXPORT OSErr AEPutParamDesc(AppleEvent *theAppleEvent, AEKeyword theAEKeyword,
		const AEDesc *theAEDesc)
{
	(void) theAEKeyword;
	if (theAppleEvent == NULL || theAEDesc == NULL)
		return paramErr;
	return errAEWrongDataType;
}

XCODE_EXPORT OSStatus AESendMessage(const AppleEvent *event, AppleEvent *reply,
		AESendMode sendMode, long timeOutInTicks)
{
	(void) sendMode;
	(void) timeOutInTicks;
	xcodeNullDesc(reply);
	if (event == NULL)
		return paramErr;
	/* There is no Apple event transport: the target cannot be reached. */
	return connectionInvalid;
}

XCODE_EXPORT OSErr CreateObjSpecifier(DescType desiredClass, AEDesc *theContainer,
		DescType keyForm, AEDesc *keyData, Boolean disposeInputs, AEDesc *objSpecifier)
{
	(void) desiredClass;
	(void) keyForm;
	xcodeNullDesc(objSpecifier);
	if (disposeInputs) {
		if (theContainer != NULL)
			AEDisposeDesc(theContainer);
		if (keyData != NULL)
			AEDisposeDesc(keyData);
	}
	if (objSpecifier == NULL)
		return paramErr;
	return errAEWrongDataType;
}

/* ------------------------------------------------------------------------ */
/* FSEvents                                                                 */
/* ------------------------------------------------------------------------ */

XCODE_EXPORT FSEventStreamEventId FSEventStreamFlushAsync(FSEventStreamRef streamRef)
{
	if (streamRef == NULL)
		return 0;
	return FSEventStreamGetLatestEventId((ConstFSEventStreamRef) streamRef);
}

XCODE_EXPORT void FSEventStreamFlushSync(FSEventStreamRef streamRef)
{
	/* Events are delivered as they arrive; there is no daemon queue to drain. */
	(void) streamRef;
}

XCODE_EXPORT FSEventStreamEventId FSEventsGetCurrentEventId(void)
{
	/* There is no persistent event database, so no event has been recorded. */
	return 0;
}

/* ------------------------------------------------------------------------ */
/* File manager                                                             */
/* ------------------------------------------------------------------------ */

XCODE_EXPORT OSErr FSIsAliasFile(const FSRef *fileRef, Boolean *aliasFileFlag, Boolean *folderFlag)
{
	char path[PATH_MAX];
	struct stat st;

	if (aliasFileFlag != NULL)
		*aliasFileFlag = false;
	if (folderFlag != NULL)
		*folderFlag = false;
	if (fileRef == NULL)
		return paramErr;

	memset(path, 0, sizeof(path));
	if (FSRefMakePath(fileRef, (UInt8 *) path, sizeof(path) - 1) != noErr)
		return fnfErr;

	if (stat(path, &st) != 0) {
		/* A dangling symbolic link still exists as a file. */
		if (lstat(path, &st) != 0)
			return fnfErr;
	}
	if (folderFlag != NULL)
		*folderFlag = S_ISDIR(st.st_mode) ? true : false;
	/* Classic Mac OS alias files do not exist here; symbolic links are not
	 * alias files. */
	return noErr;
}

static OSStatus xcodeMakeDirs(const char *dir, mode_t mode)
{
	char buf[PATH_MAX];
	size_t len = strlen(dir);

	if (len == 0 || len >= sizeof(buf))
		return -1;
	memcpy(buf, dir, len + 1);
	for (char *p = buf + 1; *p; p++) {
		if (*p == '/') {
			*p = '\0';
			if (mkdir(buf, mode) != 0 && errno != EEXIST)
				return -1;
			*p = '/';
		}
	}
	if (mkdir(buf, mode) != 0 && errno != EEXIST)
		return -1;
	return 0;
}

XCODE_EXPORT OSStatus FSPathMoveObjectToTrashSync(const char *sourcePath, char **targetPath,
		OptionBits options)
{
	char trash[PATH_MAX];
	char target[PATH_MAX];
	char base[PATH_MAX];
	struct stat st;
	const char *home;
	const char *slash;
	size_t baseLen;

	(void) options;
	if (targetPath != NULL)
		*targetPath = NULL;
	if (sourcePath == NULL || sourcePath[0] == '\0')
		return paramErr;
	if (lstat(sourcePath, &st) != 0)
		return fnfErr;

	home = getenv("HOME");
	if (home == NULL || home[0] != '/')
		return fnfErr;
	if (snprintf(trash, sizeof(trash), "%s/.Trash", home) >= (int) sizeof(trash))
		return paramErr;
	if (xcodeMakeDirs(trash, 0700) != 0)
		return (errno == EACCES || errno == EPERM) ? permErr : ioErr;

	/* Name of the last path component, ignoring trailing slashes. */
	baseLen = strlen(sourcePath);
	while (baseLen > 1 && sourcePath[baseLen - 1] == '/')
		baseLen--;
	slash = sourcePath + baseLen;
	while (slash > sourcePath && slash[-1] != '/')
		slash--;
	baseLen = (size_t) (sourcePath + baseLen - slash);
	if (baseLen == 0 || baseLen >= sizeof(base))
		return paramErr;
	memcpy(base, slash, baseLen);
	base[baseLen] = '\0';

	for (int attempt = 0; attempt < 1000; attempt++) {
		int n;

		if (attempt == 0)
			n = snprintf(target, sizeof(target), "%s/%s", trash, base);
		else
			n = snprintf(target, sizeof(target), "%s/%s %d", trash, base, attempt + 1);
		if (n >= (int) sizeof(target))
			return paramErr;
		if (lstat(target, &st) == 0)
			continue;
		if (rename(sourcePath, target) == 0) {
			if (targetPath != NULL)
				*targetPath = strdup(target);
			return noErr;
		}
		switch (errno) {
			case EACCES:
			case EPERM:
			case EROFS:
				return permErr;
			case ENOENT:
				return fnfErr;
			case EXDEV:
				return diffVolErr;
			default:
				return ioErr;
		}
	}
	return dupFNErr;
}

/* ------------------------------------------------------------------------ */
/* LaunchServices                                                           */
/* ------------------------------------------------------------------------ */

XCODE_EXPORT CFArrayRef LSCopyApplicationURLsForURL(CFURLRef inURL, LSRolesMask inRoleMask)
{
	CFURLRef app;
	CFArrayRef result;

	if (inURL == NULL)
		return NULL;
	app = LSCopyDefaultApplicationURLForURL(inURL, inRoleMask, NULL);
	if (app == NULL)
		return NULL;
	result = CFArrayCreate(kCFAllocatorDefault, (const void **) &app, 1, &kCFTypeArrayCallBacks);
	CFRelease(app);
	return result;
}

XCODE_EXPORT void _LSCopyAllApplicationURLs(CFArrayRef *outApplicationURLs)
{
	/* No application database to enumerate. */
	if (outApplicationURLs != NULL)
		*outApplicationURLs = CFArrayCreate(kCFAllocatorDefault, NULL, 0, &kCFTypeArrayCallBacks);
}

XCODE_EXPORT CFArrayRef _LSCopyMatchingApplicationsWithItems(CFArrayRef items, CFTypeRef options,
		CFErrorRef *outError)
{
	(void) items;
	(void) options;
	if (outError != NULL)
		*outError = NULL;
	return NULL;
}

XCODE_EXPORT CFStringRef _LSCreateDeviceTypeIdentifierWithModelCode(CFStringRef modelCode)
{
	(void) modelCode;
	return NULL;
}

XCODE_EXPORT OSStatus _LSOpenApplicationURL(CFURLRef applicationURL, CFTypeRef options, CFTypeRef reserved)
{
	(void) applicationURL;
	(void) options;
	(void) reserved;
	return unimpErr;
}

XCODE_EXPORT OSStatus _LSRegisterURLWithOptions(CFURLRef url, CFTypeRef options)
{
	(void) options;
	if (url == NULL)
		return paramErr;
	return LSRegisterURL(url, true);
}

XCODE_EXPORT OSStatus _LSUnregisterURL(CFURLRef url)
{
	/* Nothing is ever kept registered for an URL, so there is nothing to remove. */
	if (url == NULL)
		return paramErr;
	return noErr;
}

/* An application serial number is the 64-bit value (high << 32 | low), held in
 * a CFNumber exactly like _LSASNCreateWithPid() does. */

XCODE_EXPORT CFTypeRef _LSASNCreate(CFAllocatorRef allocator, uint64_t asn)
{
	SInt64 value = (SInt64) asn;
	return CFNumberCreate(allocator, kCFNumberSInt64Type, &value);
}

XCODE_EXPORT void _LSASNExtractHighAndLowParts(CFTypeRef asn, UInt32 *outHigh, UInt32 *outLow)
{
	SInt64 value = 0;

	if (asn != NULL && CFGetTypeID(asn) == CFNumberGetTypeID())
		CFNumberGetValue((CFNumberRef) asn, kCFNumberSInt64Type, &value);
	if (outHigh != NULL)
		*outHigh = (UInt32) (((uint64_t) value) >> 32);
	if (outLow != NULL)
		*outLow = (UInt32) (((uint64_t) value) & 0xFFFFFFFFu);
}

/* ------------------------------------------------------------------------ */
/* UTType                                                                   */
/* ------------------------------------------------------------------------ */

XCODE_EXPORT UInt32 _UTTypeGetStatus(CFStringRef uti)
{
	/* Status 0: unknown/unclassified. */
	(void) uti;
	return 0;
}

XCODE_EXPORT CFStringRef _UTTypeCreateSuggestedFilename(CFStringRef uti, CFStringRef baseName)
{
	CFStringRef ext = NULL;
	CFStringRef result;

	/* Work out which argument is the type identifier. */
	if (uti != NULL && baseName != NULL && !UTTypeIsDeclared(uti) && UTTypeIsDeclared(baseName)) {
		CFStringRef tmp = uti;
		uti = baseName;
		baseName = tmp;
	}
	if (baseName == NULL)
		baseName = CFSTR("Untitled");
	if (uti != NULL)
		ext = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension);
	if (ext == NULL || CFStringGetLength(ext) == 0) {
		if (ext != NULL)
			CFRelease(ext);
		return CFStringCreateCopy(kCFAllocatorDefault, baseName);
	}
	result = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%@.%@"), baseName, ext);
	CFRelease(ext);
	return result;
}

/* ------------------------------------------------------------------------ */
/* Metadata (no Spotlight backend)                                          */
/* ------------------------------------------------------------------------ */

XCODE_EXPORT CFArrayRef MDItemCopyAttributesBulk(CFArrayRef items, CFArrayRef attributeNames)
{
	(void) items;
	(void) attributeNames;
	return NULL;
}

XCODE_EXPORT CFTypeRef MDPlistBytesCopyPlistAtIndex(const void *bytes, CFIndex index)
{
	(void) bytes;
	(void) index;
	return NULL;
}

XCODE_EXPORT void MDStoreOIDArrayApplyBlock(const void *oidArray, void *block)
{
	/* An OID array from the (absent) metadata store is always empty. */
	(void) oidArray;
	(void) block;
}

XCODE_EXPORT CFIndex MDStoreOIDArrayGetVectorCount(const void *oidArray)
{
	(void) oidArray;
	return 0;
}

XCODE_EXPORT void _MDSuspendIndexing(Boolean suspend)
{
	/* There is no indexer to suspend. */
	(void) suspend;
}

/* ------------------------------------------------------------------------ */
/* Unicode utilities / CarbonCore                                           */
/* ------------------------------------------------------------------------ */

XCODE_EXPORT ItemCount UCKeyboardLayoutStringMax(const void *keyboardLayout)
{
	/* No key layout carries any string data to measure. */
	(void) keyboardLayout;
	return 0;
}

XCODE_EXPORT UInt32 _CSGetProcessorArchitecture(void)
{
	/*
	 * The Mach CPU type of the processor (not a Gestalt code): Xcode's
	 * DevToolsSupport looks it up with NXGetArchInfoFromCpuType() and uses
	 * the name, so an unknown type crashes it.
	 */
#if defined(__x86_64__) || defined(__i386__)
	return CPU_TYPE_X86_64;
#elif defined(__aarch64__) || defined(__arm__)
	return CPU_TYPE_ARM64;
#elif defined(__powerpc64__)
	return CPU_TYPE_POWERPC64;
#else
	return CPU_TYPE_ANY;
#endif
}
