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

#import <PlugInKit/PlugInKit.h>

@implementation PKHost

/*
 * Xcode's first launch messages the shared host
 * (DVTFirstLaunchPackageInstallationHelper -> +[PKHost defaultHost]).
 * Returning a live singleton lets the caller proceed; everything it then sends
 * lands in the stub forwarding below instead of raising
 * "+[PKHost defaultHost]: unrecognized selector".
 */
+ (instancetype)defaultHost {
    static PKHost *host = nil;

    if (host == nil) {
        host = [[self alloc] init];
    }
    return host;
}

/*
 * Xcode's plug-in machinery calls this.  The generic forwarding stub below
 * answers *every* selector with the "v@:" signature (self + _cmd), so a
 * 5-argument selector made NSInvocation raise
 *
 *     NSForwardSignatureError: invoked with 5 args, but 2 expected
 *
 * Give it an explicit implementation instead.
 */
- (void) continuouslyDiscoverPlugInsForAttributes: (id) attributes
                                            flags: (NSUInteger) flags
                                            found: (id) foundHandler {
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [NSMethodSignature signatureWithObjCTypes: "v@:"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"Stub called: %@ in %@", NSStringFromSelector([anInvocation selector]), [self class]);
}

@end
