/*
 This file is part of Darling.

 Copyright (C) 2025 Darling Developers

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

#import <UIFoundation/NSFontAssetRequest.h>
#import <Foundation/NSMutableDictionary.h>
#import <Foundation/NSProgress.h>
#import <Foundation/NSValue.h>

static NSMutableDictionary *NSFontAssetRequestProgresses;

@implementation NSFontAssetRequest

- (NSProgress *)progress
{
    @synchronized ([NSFontAssetRequest class]) {
        if (NSFontAssetRequestProgresses == nil) {
            NSFontAssetRequestProgresses = [[NSMutableDictionary alloc] init];
        }

        NSValue *key = [NSValue valueWithPointer: self];
        NSProgress *progress = [NSFontAssetRequestProgresses objectForKey: key];
        if (progress == nil) {
            progress = [[NSProgress alloc] initWithParent: nil userInfo: nil];
            [progress setTotalUnitCount: -1];
            [NSFontAssetRequestProgresses setObject: progress forKey: key];
            [progress release];
            progress = [NSFontAssetRequestProgresses objectForKey: key];
        }
        return progress;
    }
}

- (void)dealloc
{
    @synchronized ([NSFontAssetRequest class]) {
        NSValue *key = [NSValue valueWithPointer: self];
        [NSFontAssetRequestProgresses removeObjectForKey: key];
    }
    [super dealloc];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [NSMethodSignature signatureWithObjCTypes: "v@:"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    NSLog(@"Stub called: %@ in %@", NSStringFromSelector([anInvocation selector]), [self class]);
}

@end
