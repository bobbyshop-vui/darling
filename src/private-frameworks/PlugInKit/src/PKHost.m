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
    void (^handler)(NSArray *, NSError *) = [foundHandler copy];
    if (handler == nil) return;
    NSArray *found = [self discoverPlugInsForAttributes: attributes flags: flags];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        handler(found, nil);
        [handler release];
    });
}

/*
 * Enumerate the host application's app extensions
 * (Contents/PlugIns/*.appex and Contents/Extensions/*.appex) and return
 * the ones whose NSExtension dictionary matches the attributes.
 */
- (NSArray *) discoverPlugInsForAttributes: (id) attributes flags: (NSUInteger) flags {
    NSMutableArray *result = [NSMutableArray array];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *base = [[NSBundle mainBundle] bundlePath];
    NSMutableArray *dirs = [NSMutableArray array];
    NSString *builtIn = [[NSBundle mainBundle] builtInPlugInsPath];
    if (builtIn) [dirs addObject: builtIn];
    [dirs addObject: [[base stringByAppendingPathComponent: @"Contents"] stringByAppendingPathComponent: @"Extensions"]];

    NSDictionary *wanted = [attributes isKindOfClass: [NSDictionary class]] ? attributes : nil;
    NSMutableSet *seen = [NSMutableSet set];

    for (NSString *dir in dirs) {
        for (NSString *entry in [[fm contentsOfDirectoryAtPath: dir error: NULL] sortedArrayUsingSelector: @selector(compare:)]) {
            if (![[entry pathExtension] isEqualToString: @"appex"]) continue;
            NSString *path = [dir stringByAppendingPathComponent: entry];
            NSString *plist = [path stringByAppendingPathComponent: @"Contents/Info.plist"];
            NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile: plist];
            if (info == nil) {
                plist = [path stringByAppendingPathComponent: @"Info.plist"];
                info = [NSDictionary dictionaryWithContentsOfFile: plist];
            }
            NSDictionary *ext = [info objectForKey: @"NSExtension"];
            if (![ext isKindOfClass: [NSDictionary class]]) continue;
            NSString *ident = [info objectForKey: @"CFBundleIdentifier"];
            if (ident == nil || [seen containsObject: ident]) continue;

            BOOL match = YES;
            NSDictionary *extAttrs = [ext objectForKey: @"NSExtensionAttributes"];
            for (id key in wanted) {
                id want = [wanted objectForKey: key];
                id have = [ext objectForKey: key];
                if (have == nil && [extAttrs isKindOfClass: [NSDictionary class]]) have = [extAttrs objectForKey: key];
                if ([key isEqual: @"NSExtensionPointIdentifier"] || have != nil) {
                    if (![want isEqual: have]) { match = NO; break; }
                }
            }
            if (!match) continue;
            [seen addObject: ident];
            PKHostPlugIn *plugin = [[PKHostPlugIn alloc] initWithBundleURL: [NSURL fileURLWithPath: path isDirectory: YES]
                                                            infoDictionary: info];
            [result addObject: plugin];
            [plugin release];
        }
    }
    return result;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [NSMethodSignature signatureWithObjCTypes: "v@:"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"Stub called: %@ in %@", NSStringFromSelector([anInvocation selector]), [self class]);
}

@end
