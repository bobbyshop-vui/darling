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

#include <Foundation/Foundation.h>
#include <CoreGraphics/CoreGraphics.h>

extern NSString *const kCIInputRadiusKey;

@class CIImage;

extern NSString * const kCIInputImageKey;
extern NSString * const kCIOutputImageKey;
extern NSString * const kCIInputAngleKey;
extern NSString * const kCIInputSaturationKey;
extern NSString * const kCIInputBrightnessKey;
extern NSString * const kCIInputContrastKey;
extern NSString * const kCIAttributeFilterName;

// Filters run on the CPU over rendered bitmaps. Darling implements
// CIColorInvert, CIHueAdjust and CIColorControls; other names give nil, as
// unknown filter names do on macOS.
@interface CIFilter : NSObject <NSCopying> {
    NSString *_name;
    NSMutableDictionary *_values;
}

+ (CIFilter *)filterWithName:(NSString *)name;
+ (CIFilter *)filterWithName:(NSString *)name keysAndValues:(id)key0, ... NS_REQUIRES_NIL_TERMINATION;
+ (CIFilter *)filterWithName:(NSString *)name withInputParameters:(NSDictionary *)params;
+ (NSArray *)filterNamesInCategory:(NSString *)category;
+ (NSArray *)filterNamesInCategories:(NSArray *)categories;
+ (NSString *)localizedNameForFilterName:(NSString *)filterName;

- (NSString *)name;
- (NSArray *)inputKeys;
- (NSArray *)outputKeys;
- (NSDictionary *)attributes;
- (CIImage *)outputImage;
- (void)setDefaults;

@end
