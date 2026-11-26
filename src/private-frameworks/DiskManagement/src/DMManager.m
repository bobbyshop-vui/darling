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

#import <DiskManagement/DiskManagement.h>
#import <objc/runtime.h>

// Xcode (+[IDEAppStatistics _diskTypes]) asks DMManager about the root disk.
// The old catch-all stub forwarded every message with a "v@:" signature, so
// copyRootDisk: handed back garbage that Xcode then CFReleased and crashed on.
// Darling has no DiskArbitration disks, so report none.

@implementation DMManager

- (void)setDefaultDASession:(void *)session {
    _defaultDASession = session;
}

- (void *)defaultDASession {
    return _defaultDASession;
}

- (void *)copyRootDisk:(NSError **)error {
    if (error)
        *error = nil;
    return NULL;
}

- (void *)copyDiskForPath:(NSString *)path error:(NSError **)error {
    if (error)
        *error = nil;
    return NULL;
}

- (BOOL)isOnSameWholeDiskAsRoot:(void *)disk error:(NSError **)error {
    if (error)
        *error = nil;
    return YES;
}

- (BOOL)isAppleDiskImage:(void *)disk error:(NSError **)error {
    if (error)
        *error = nil;
    return NO;
}

- (BOOL)isNetworkDisk:(void *)disk error:(NSError **)error {
    if (error)
        *error = nil;
    return NO;
}

- (BOOL)isSolidStateDisk:(void *)disk error:(NSError **)error {
    if (error)
        *error = nil;
    return YES;
}

- (BOOL)isInternalDisk:(void *)disk error:(NSError **)error {
    if (error)
        *error = nil;
    return YES;
}

// Anything else: answer with nil/0 instead of garbage, with a signature that
// matches the selector's argument count.
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector: aSelector];
    if (signature != nil)
        return signature;

    const char *name = sel_getName(aSelector);
    char types[64] = "@@:";
    size_t length = 3;
    for (const char *p = name; *p && length < sizeof(types) - 1; p++)
        if (*p == ':')
            types[length++] = '@';
    types[length] = '\0';
    return [NSMethodSignature signatureWithObjCTypes: types];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"Stub called: %@ in %@", NSStringFromSelector([anInvocation selector]), [self class]);
    id result = nil;
    if ([[anInvocation methodSignature] methodReturnLength] <= sizeof(result))
        [anInvocation setReturnValue: &result];
}

@end
