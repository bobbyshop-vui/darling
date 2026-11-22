#include <AppleSystemInfo/AppleSystemInfo.h>
#include <mach/host_info.h>
#include <CoreFoundation/CFUUID.h>
#include <gethostuuid_private.h>
#include <string.h>

CFStringRef ASI_CopyComputerModelName(int arg0) {
	return CFSTR("UNIMPLEMENTED");
}

CFStringRef ASI_CopyHostUUID(void) {
	uuid_t hostUUID;
	struct timespec timeout = { .tv_sec = 1, .tv_nsec = 0 };

	if (gethostuuid(hostUUID, &timeout) != 0)
		return NULL;

	CFUUIDBytes bytes;
	memcpy(&bytes, hostUUID, sizeof(bytes));
	CFUUIDRef uuid = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, bytes);
	if (uuid == NULL)
		return NULL;

	CFStringRef result = CFUUIDCreateString(kCFAllocatorDefault, uuid);
	CFRelease(uuid);
	return result;
}

int ASI_NumberOfCPUs(void) {
	// stub
	return 1;
};
