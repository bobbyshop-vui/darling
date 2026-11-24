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

@implementation PKHostPlugIn

@synthesize url = _url;

- (instancetype) initWithBundleURL: (NSURL *) url infoDictionary: (NSDictionary *) info {
    if ((self = [super init])) {
        _url = [url copy];
        _info = [info copy];
    }
    return self;
}

- (void) dealloc {
    [_url release];
    [_info release];
    [super dealloc];
}

- (NSDictionary *) infoDictionary { return _info; }
- (NSString *) identifier { return [_info objectForKey: @"CFBundleIdentifier"]; }
- (NSString *) version { return [_info objectForKey: @"CFBundleVersion"]; }

- (NSString *) name {
    NSString *name = [_info objectForKey: @"CFBundleDisplayName"];
    if (name == nil) name = [_info objectForKey: @"CFBundleName"];
    return name;
}

- (NSDictionary *) attributes {
    return [_info objectForKey: @"NSExtension"];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [NSMethodSignature signatureWithObjCTypes: "v@:"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"Stub called: %@ in %@", NSStringFromSelector([anInvocation selector]), [self class]);
}

@end
