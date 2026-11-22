/*
This file is part of Darling.

Copyright (C) 2020 Lubos Dolezel

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


#include <LaunchServices/LaunchServices.h>
#include <CarbonCore/MacErrors.h>
#include <CoreFoundation/CFBundle.h>
#include <stdio.h>
#include <string.h>
#include <limits.h>

OSStatus LSOpenApplication(const LSApplicationParameters *appParams, ProcessSerialNumber *outPSN);

static OSStatus openApplicationURL(CFURLRef url, const LSApplicationParameters *appParams)
{
	if (!url || CFGetTypeID(url) != CFURLGetTypeID())
		return paramErr;

	CFStringRef scheme = CFURLCopyScheme(url);
	Boolean isFileURL = scheme && CFStringCompare(scheme, CFSTR("file"), kCFCompareCaseInsensitive) == kCFCompareEqualTo;
	if (scheme)
		CFRelease(scheme);
	if (!isFileURL)
		return paramErr;

	CFBundleRef bundle = CFBundleCreate(kCFAllocatorDefault, url);
	if (!bundle)
		return kLSApplicationNotFoundErr;

	CFURLRef executableURL = CFBundleCopyExecutableURL(bundle);
	CFRelease(bundle);
	if (!executableURL)
		return kLSApplicationNotFoundErr;
	CFRelease(executableURL);

	char path[PATH_MAX];
	if (!CFURLGetFileSystemRepresentation(url, true, (UInt8*) path, sizeof(path)))
		return paramErr;

	FSRef appRef;
	OSStatus status = FSPathMakeRef((const UInt8*) path, &appRef, NULL);
	if (status != noErr)
		return status;

	LSApplicationParameters params;
	memset(&params, 0, sizeof(params));
	if (appParams)
		params = *appParams;
	params.application = &appRef;

	return LSOpenApplication(&params, NULL);
}

OSStatus
LSOpenURLsWithRole(
  CFArrayRef inURLs,
  LSRolesMask inRole,
  const AEKeyDesc * inAEParam,
  const LSApplicationParameters * inAppParams,
  ProcessSerialNumber * outPSNs,
  CFIndex inMaxPSNCount)
{
	if (inAppParams && inAppParams->application)
		return LSOpenApplication(inAppParams, outPSNs);

	if (!inURLs || CFGetTypeID(inURLs) != CFArrayGetTypeID())
		return paramErr;

	CFIndex count = CFArrayGetCount(inURLs);
	if (count == 0)
		return paramErr;

	OSStatus status = noErr;
	for (CFIndex i = 0; i < count; i++)
	{
		CFTypeRef value = (CFTypeRef) CFArrayGetValueAtIndex(inURLs, i);
		if (!value || CFGetTypeID(value) != CFURLGetTypeID())
			return paramErr;

		status = openApplicationURL((CFURLRef) value, inAppParams);
		if (status != noErr)
			return status;
	}

	return noErr;
}

OSStatus
LSOpenItemsWithRole(
  const FSRef * inItems,
  CFIndex inItemCount,
  LSRolesMask inRole,
  const AEKeyDesc * inAEParam,
  const LSApplicationParameters * inAppParams,
  ProcessSerialNumber * outPSNs,
  CFIndex inMaxPSNCount)
{

	CFURLRef* urls = (CFURLRef*) malloc(inItemCount * sizeof(CFURLRef));

	for (CFIndex i = 0; i < inItemCount; i++)
	{
		char path[4096];

		OSStatus status = FSRefMakePath(&inItems[i], (UInt8*) path, sizeof(path)-1);
		if (status != noErr)
		{
			for (CFIndex j; j < i; j++)
				CFRelease(urls[j]);
			free(urls);
			return status;
		}

		CFStringRef urlStr = CFStringCreateWithCString(NULL, path, kCFStringEncodingUTF8);
		urls[i] = CFURLCreateWithFileSystemPath(NULL, urlStr, kCFURLPOSIXPathStyle, FALSE);
		CFRelease(urlStr);
	}

	CFArrayRef urlArray = CFArrayCreate(NULL, (const void**) urls, inItemCount, &kCFTypeArrayCallBacks);
	for (CFIndex i; i < inItemCount; i++)
		CFRelease(urls[i]);
	free(urls);

	OSStatus status = LSOpenURLsWithRole(urlArray, inRole, inAEParam, inAppParams, outPSNs, inMaxPSNCount);

	CFRelease(urlArray);

	return status;
}

OSStatus LSOpenFSRef(const FSRef *inRef, FSRef *outLaunchedRef)
{
	char path[4096];

	OSStatus status = FSRefMakePath(inRef, (UInt8*) path, sizeof(path)-1);
	if (status != noErr)
		return status;

	CFStringRef urlStr = CFStringCreateWithCString(NULL, path, kCFStringEncodingUTF8);
	CFURLRef url = CFURLCreateWithFileSystemPath(NULL, urlStr, kCFURLPOSIXPathStyle, FALSE);
	CFRelease(urlStr);
	
	CFURLRef launchedUrl;
	status = LSOpenCFURLRef(url, &launchedUrl);

	CFRelease(url);

	if (status != noErr)
		return status;

	if (outLaunchedRef)
	{
		CFStringRef path = CFURLCopyFileSystemPath(launchedUrl, kCFURLPOSIXPathStyle);
		status = FSPathMakeRef((const UInt8*) CFStringGetCStringPtr(path, kCFStringEncodingUTF8), outLaunchedRef, NULL);
		CFRelease(path);
	}
	
	CFRelease(launchedUrl);
	return status;
}

OSStatus LSOpenCFURLRef(CFURLRef inURL, CFURLRef *outLaunchedURL)
{
	OSStatus ret;
	LSLaunchURLSpec spec;

	memset(&spec, 0, sizeof(spec));

	spec.itemURLs = CFArrayCreate(kCFAllocatorDefault, (const void**)&inURL, 1, NULL);
	ret = LSOpenFromURLSpec(&spec, outLaunchedURL);
	CFRelease(spec.itemURLs);
	
	return ret;
}

/*
OSStatus LSOpenApplication(const LSApplicationParameters *appParams, ProcessSerialNumber *outPSN)
{

}
*/

/*
OSStatus
LSOpenFromURLSpec(
  const LSLaunchURLSpec * inLaunchSpec,
  _Nullable CFURLRef *_Nullable outLaunchedURL)
{
}
*/
