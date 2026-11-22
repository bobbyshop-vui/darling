#pragma once

#include <CarbonCore/MacErrors.h>
#include <cerrno>

namespace Darling {

inline constexpr char resourceForkAttribute[] = "user.com.apple.ResourceFork";
inline constexpr char finderInfoAttribute[] = "user.com.apple.FinderInfo";

inline bool fileAttributeMissing(int error)
{
	return error == ENOATTR || error == ENODATA;
}

inline OSErr macFileError(int error)
{
	switch (error) {
		case 0: return noErr;
		case ENOENT: return fnfErr;
		case ENOTDIR: return dirNFErr;
		case EACCES:
		case EPERM: return permErr;
		case EROFS: return wPrErr;
		case EMFILE:
		case ENFILE: return tmfoErr;
		case ENOSPC:
		case EFBIG: return dskFulErr;
		case ENOTSUP: return unimpErr;
		default: return ioErr;
	}
}

}
