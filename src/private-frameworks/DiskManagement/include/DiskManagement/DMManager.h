/*
This file is part of Darling.

Copyright (C) 2017 Lubos Dolezel

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

@class NSError, NSString;

// DADiskRef / DASessionRef, kept opaque to avoid a DiskArbitration dependency.
@interface DMManager : NSObject {
    void *_defaultDASession;
}

- (void)setDefaultDASession:(void *)session;
- (void *)defaultDASession;

// Darling has no DiskArbitration disks: these return NULL.
- (void *)copyRootDisk:(NSError **)error;
- (void *)copyDiskForPath:(NSString *)path error:(NSError **)error;

- (BOOL)isOnSameWholeDiskAsRoot:(void *)disk error:(NSError **)error;
- (BOOL)isAppleDiskImage:(void *)disk error:(NSError **)error;
- (BOOL)isNetworkDisk:(void *)disk error:(NSError **)error;
- (BOOL)isSolidStateDisk:(void *)disk error:(NSError **)error;
- (BOOL)isInternalDisk:(void *)disk error:(NSError **)error;

@end
