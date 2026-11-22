#pragma once

#include <cerrno>

namespace Darling {

inline constexpr char resourceForkAttribute[] = "user.com.apple.ResourceFork";
inline constexpr char finderInfoAttribute[] = "user.com.apple.FinderInfo";

inline bool fileAttributeMissing(int error)
{
	return error == ENOATTR || error == ENODATA;
}

}
