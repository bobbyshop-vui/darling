/*
 This file is part of Darling.

 Copyright (C) 2026 Darling developers

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

#import <GameplayKit/GameplayKitBase.h>

// Noise sources describe noise for GKNoise; Darling keeps their parameters.
@interface GKNoiseSource : NSObject
@end

@interface GKCoherentNoiseSource : GKNoiseSource {
    double _frequency;
    NSInteger _octaveCount;
    double _lacunarity;
    int32_t _seed;
}
@property (nonatomic) double frequency;
@property (nonatomic) NSInteger octaveCount;
@property (nonatomic) double lacunarity;
@property (nonatomic) int32_t seed;
@end

@interface GKPerlinNoiseSource : GKCoherentNoiseSource {
    double _persistence;
}
@property (nonatomic) double persistence;
+ (instancetype)perlinNoiseSourceWithFrequency:(double)frequency octaveCount:(NSInteger)octaveCount persistence:(double)persistence lacunarity:(double)lacunarity seed:(int32_t)seed;
- (instancetype)initWithFrequency:(double)frequency octaveCount:(NSInteger)octaveCount persistence:(double)persistence lacunarity:(double)lacunarity seed:(int32_t)seed;
@end

@interface GKBillowNoiseSource : GKCoherentNoiseSource {
    double _persistence;
}
@property (nonatomic) double persistence;
+ (instancetype)billowNoiseSourceWithFrequency:(double)frequency octaveCount:(NSInteger)octaveCount persistence:(double)persistence lacunarity:(double)lacunarity seed:(int32_t)seed;
- (instancetype)initWithFrequency:(double)frequency octaveCount:(NSInteger)octaveCount persistence:(double)persistence lacunarity:(double)lacunarity seed:(int32_t)seed;
@end

@interface GKRidgedNoiseSource : GKCoherentNoiseSource
+ (instancetype)ridgedNoiseSourceWithFrequency:(double)frequency octaveCount:(NSInteger)octaveCount lacunarity:(double)lacunarity seed:(int32_t)seed;
- (instancetype)initWithFrequency:(double)frequency octaveCount:(NSInteger)octaveCount lacunarity:(double)lacunarity seed:(int32_t)seed;
@end

@interface GKVoronoiNoiseSource : GKNoiseSource {
    double _frequency;
    double _displacement;
    BOOL _distanceEnabled;
    int32_t _seed;
}
@property (nonatomic) double frequency;
@property (nonatomic) double displacement;
@property (nonatomic, getter=isDistanceEnabled) BOOL distanceEnabled;
@property (nonatomic) int32_t seed;
+ (instancetype)voronoiNoiseWithFrequency:(double)frequency displacement:(double)displacement distanceEnabled:(BOOL)distanceEnabled seed:(int32_t)seed;
- (instancetype)initWithFrequency:(double)frequency displacement:(double)displacement distanceEnabled:(BOOL)distanceEnabled seed:(int32_t)seed;
@end

@interface GKConstantNoiseSource : GKNoiseSource {
    double _value;
}
@property (nonatomic) double value;
+ (instancetype)constantNoiseWithValue:(double)value;
- (instancetype)initWithValue:(double)value;
@end

@interface GKCylindersNoiseSource : GKNoiseSource {
    double _frequency;
}
@property (nonatomic) double frequency;
+ (instancetype)cylindersNoiseWithFrequency:(double)frequency;
- (instancetype)initWithFrequency:(double)frequency;
@end

@interface GKSpheresNoiseSource : GKNoiseSource {
    double _frequency;
}
@property (nonatomic) double frequency;
+ (instancetype)spheresNoiseWithFrequency:(double)frequency;
- (instancetype)initWithFrequency:(double)frequency;
@end

@interface GKCheckerboardNoiseSource : GKNoiseSource {
    double _squareSize;
}
@property (nonatomic) double squareSize;
+ (instancetype)checkerboardNoiseWithSquareSize:(double)squareSize;
- (instancetype)initWithSquareSize:(double)squareSize;
@end
