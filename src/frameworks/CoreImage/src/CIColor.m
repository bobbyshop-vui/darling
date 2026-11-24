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

#import <CoreImage/CIColor.h>

@protocol CIColorNSColorAccess
- (void)getRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha;
- (void)getWhite:(CGFloat *)white alpha:(CGFloat *)alpha;
@end

@implementation CIColor

// color is an NSColor (AppKit); convert through its RGB accessors if it has them.
- (instancetype)initWithColor:(id)color {
    id<CIColorNSColorAccess> c = color;
    self = [super init];
    if (self == nil)
        return nil;
    _components[0] = _components[1] = _components[2] = 0;
    _components[3] = 1;
    if ([color respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
        [c getRed:&_components[0] green:&_components[1] blue:&_components[2] alpha:&_components[3]];
    } else if ([color respondsToSelector:@selector(getWhite:alpha:)]) {
        CGFloat w = 0, a = 1;
        [c getWhite:&w alpha:&a];
        _components[0] = _components[1] = _components[2] = w;
        _components[3] = a;
    }
    return self;
}

- (CGFloat)red { return _components[0]; }
- (CGFloat)green { return _components[1]; }
- (CGFloat)blue { return _components[2]; }
- (CGFloat)alpha { return _components[3]; }

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [NSMethodSignature signatureWithObjCTypes: "v@:"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"Stub called: %@ in %@", NSStringFromSelector([anInvocation selector]), [self class]);
}

@end
