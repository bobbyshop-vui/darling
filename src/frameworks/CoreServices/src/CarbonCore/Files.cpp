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

#include <CarbonCore/Files.h>
#include <CarbonCore/MacErrors.h>
#include "MacFileAttributes.h"
#include <algorithm>
#include <cstdio>
#include <cstring>
#include <fcntl.h>
#include <limits>
#include <limits.h>
#include <map>
#include <memory>
#include <mutex>
#include <new>
#include <sys/stat.h>
#include <sys/xattr.h>
#include <unistd.h>
#include <vector>

#define STUB() std::printf("STUB %s\n", __PRETTY_FUNCTION__)

namespace {

struct OpenFork {
	int fd;
	bool resource;
	int access;
	SInt64 mark = 0;

	~OpenFork() {
		if (fd >= 0)
			close(fd);
	}
};

std::mutex forkLock;
std::map<FSIORefNum, std::unique_ptr<OpenFork>> openForks;
FSIORefNum nextForkRefNum = 1;

OSErr transferResourceFork(OpenFork& fork, UInt16 mode, SInt64 offset,
		ByteCount count, void* buffer, ByteCount* actualCount, bool writing)
{
	ssize_t size = fgetxattr(fork.fd, Darling::resourceForkAttribute, nullptr, 0, 0, 0);
	if (size < 0) {
		if (!Darling::fileAttributeMissing(errno))
			return Darling::macFileError(errno);
		size = 0;
	}

	std::vector<char> data(size);
	if (size > 0) {
		ssize_t bytesRead = fgetxattr(fork.fd, Darling::resourceForkAttribute, data.data(), data.size(), 0, 0);
		if (bytesRead < 0)
			return Darling::macFileError(errno);
		data.resize(bytesRead);
	}

	SInt64 position = fork.mark;
	if (mode != fsAtMark) {
		SInt64 base = 0;
		if (mode == fsFromLEOF)
			base = data.size();
		else if (mode == fsFromMark)
			base = fork.mark;
		if (__builtin_add_overflow(base, offset, &position) || position < 0)
			return posErr;
	}

	if (!writing) {
		ByteCount available = static_cast<UInt64>(position) < data.size() ? data.size() - position : 0;
		ByteCount bytesRead = std::min(count, available);
		if (bytesRead)
			std::memcpy(buffer, data.data() + position, bytesRead);
		fork.mark = position + bytesRead;
		if (actualCount)
			*actualCount = bytesRead;
		return bytesRead == count ? noErr : eofErr;
	}

	if (count) {
		// Linux extended attributes can hold at most 64 KiB.
		constexpr size_t maxSize = 64 * 1024;
		if (static_cast<UInt64>(position) > maxSize || count > maxSize - position)
			return dskFulErr;
		data.resize(std::max(data.size(), static_cast<size_t>(position + count)));
		std::memcpy(data.data() + position, buffer, count);
		if (fsetxattr(fork.fd, Darling::resourceForkAttribute, data.data(), data.size(), 0, 0) != 0)
			return Darling::macFileError(errno);
	}

	fork.mark = position + count;
	if (actualCount)
		*actualCount = count;
	return noErr;
}

OSErr transferFork(FSIORefNum refNum, UInt16 mode, SInt64 offset,
		ByteCount count, void* buffer, ByteCount* actualCount, bool writing)
{
	if (actualCount)
		*actualCount = 0;
	if ((count && !buffer) || count > static_cast<ByteCount>(std::numeric_limits<ssize_t>::max()))
		return paramErr;

	constexpr UInt16 modeMask = 3;
	constexpr UInt16 hints = kFSAllowConcurrentAsyncIOMask | kFSPleaseCacheMask | kFSNoCacheMask | kFSRdVerifyMask;
	if (mode & ~(modeMask | hints))
		return errFSBadPosMode;
	mode &= modeMask;

	std::lock_guard<std::mutex> lock(forkLock);
	auto found = openForks.find(refNum);
	if (found == openForks.end())
		return rfNumErr;
	OpenFork& fork = *found->second;
	if (writing ? fork.access == O_RDONLY : fork.access == O_WRONLY)
		return permErr;

	if (fork.resource) {
		try {
			return transferResourceFork(fork, mode, offset, count, buffer, actualCount, writing);
		} catch (const std::bad_alloc&) {
			return memFullErr;
		}
	}

	if (mode != fsAtMark) {
		int whence = SEEK_SET;
		if (mode == fsFromLEOF)
			whence = SEEK_END;
		else if (mode == fsFromMark)
			whence = SEEK_CUR;
		if (lseek(fork.fd, offset, whence) == -1)
			return posErr;
	}
	if (!count)
		return noErr;

	ssize_t transferred;
	do {
		transferred = writing ? write(fork.fd, buffer, count) : read(fork.fd, buffer, count);
	} while (transferred < 0 && errno == EINTR);
	if (transferred < 0)
		return Darling::macFileError(errno);
	if (actualCount)
		*actualCount = transferred;
	if (static_cast<ByteCount>(transferred) == count)
		return noErr;
	return writing ? ioErr : eofErr;
}

}

OSErr FSGetDataForkName(HFSUniStr255* dataForkName)
{
	dataForkName->length = 0;
	return noErr;
}

OSErr FSGetResourceForkName(HFSUniStr255* rsrcForkName)
{
	const char name[] = "RESOURCE_FORK";
	rsrcForkName->length = sizeof(name) - 1;

	for (int i = 0; i < sizeof(name) - 1; i++)
		rsrcForkName->unicode[i] = name[i];

	return noErr;
}

OSErr FSOpenFork(const FSRef* ref, UniCharCount forkNameLength, const UniChar* forkName, SInt8 permissions, FSIORefNum* forkRefNum)
{
	if (!ref || !forkRefNum || (forkNameLength && !forkName))
		return paramErr;
	*forkRefNum = 0;

	bool resource = forkNameLength != 0;
	if (resource) {
		HFSUniStr255 name;
		FSGetResourceForkName(&name);
		if (forkNameLength != name.length || std::memcmp(forkName, name.unicode, name.length * sizeof(UniChar)) != 0)
			return errFSForkNotFound;
	}

	int flags;
	switch (permissions) {
		case fsRdPerm: flags = O_RDONLY; break;
		case fsWrPerm: flags = O_WRONLY; break;
		case fsCurPerm:
		case fsRdWrPerm:
		case fsRdWrShPerm: flags = O_RDWR; break;
		default: return paramErr;
	}

	char path[PATH_MAX];
	OSStatus status = FSRefMakePath(ref, reinterpret_cast<UInt8*>(path), sizeof(path));
	if (status != noErr)
		return status;

	int fd = open(path, flags | O_CLOEXEC | O_NONBLOCK);
	if (fd < 0 && permissions == fsCurPerm && (errno == EACCES || errno == EPERM || errno == EROFS)) {
		flags = O_RDONLY;
		fd = open(path, flags | O_CLOEXEC | O_NONBLOCK);
	}
	if (fd < 0)
		return Darling::macFileError(errno);

	std::unique_ptr<OpenFork> fork(new (std::nothrow) OpenFork{fd, resource, flags});
	if (!fork) {
		close(fd);
		return memFullErr;
	}
	struct stat st;
	if (fstat(fd, &st) != 0)
		return Darling::macFileError(errno);
	if (!S_ISREG(st.st_mode))
		return notAFileErr;

	if (resource && fgetxattr(fd, Darling::resourceForkAttribute, nullptr, 0, 0, 0) < 0) {
		if (!Darling::fileAttributeMissing(errno))
			return Darling::macFileError(errno);
		if (flags == O_RDONLY)
			return errFSForkNotFound;
	}

	std::lock_guard<std::mutex> lock(forkLock);
	if (openForks.size() == static_cast<size_t>(std::numeric_limits<FSIORefNum>::max()))
		return tmfoErr;

	FSIORefNum refNum;
	do {
		refNum = nextForkRefNum;
		nextForkRefNum = refNum == std::numeric_limits<FSIORefNum>::max() ? 1 : refNum + 1;
	} while (openForks.count(refNum));
	try {
		openForks.emplace(refNum, std::move(fork));
	} catch (const std::bad_alloc&) {
		return memFullErr;
	}
	*forkRefNum = refNum;
	return noErr;
}

OSErr FSReadFork(FSIORefNum refNum, UInt16 mode, SInt64 offset, ByteCount count, void* buffer, ByteCount* actualCount)
{
	return transferFork(refNum, mode, offset, count, buffer, actualCount, false);
}

OSErr FSWriteFork(FSIORefNum refNum, UInt16 mode, SInt64 offset, ByteCount count, const void* buffer, ByteCount* actualCount)
{
	return transferFork(refNum, mode, offset, count, const_cast<void*>(buffer), actualCount, true);
}

OSErr FSCloseFork(FSIORefNum refNum)
{
	std::lock_guard<std::mutex> lock(forkLock);
	auto found = openForks.find(refNum);
	if (found == openForks.end())
		return rfNumErr;
	int fd = found->second->fd;
	found->second->fd = -1;
	openForks.erase(found);
	return close(fd) == 0 ? noErr : Darling::macFileError(errno);
}

OSErr FSGetVolumeInfo(FSVolumeRefNum volume, ItemCount volumeIndex, FSVolumeRefNum *actualVolume, FSVolumeInfoBitmap whichInfo, FSVolumeInfo *info, HFSUniStr255 *volumeName, FSRef *rootDirectory)
{
	STUB();

	return unimpErr;
}
