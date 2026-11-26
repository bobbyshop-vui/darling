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

#import <GameplayKit/GKNoiseSource.h>

@implementation GKNoiseSource
@end

@implementation GKCoherentNoiseSource

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _frequency = 1.0;
        _octaveCount = 6;
        _lacunarity = 2.0;
        _seed = 0;
    }
    return self;
}

- (double)frequency { return _frequency; }
- (void)setFrequency:(double)frequency { _frequency = frequency; }
- (NSInteger)octaveCount { return _octaveCount; }
- (void)setOctaveCount:(NSInteger)octaveCount { _octaveCount = octaveCount; }
- (double)lacunarity { return _lacunarity; }
- (void)setLacunarity:(double)lacunarity { _lacunarity = lacunarity; }
- (int32_t)seed { return _seed; }
- (void)setSeed:(int32_t)seed { _seed = seed; }

@end

@implementation GKPerlinNoiseSource

+ (instancetype)perlinNoiseSourceWithFrequency:(double)frequency octaveCount:(NSInteger)octaveCount persistence:(double)persistence lacunarity:(double)lacunarity seed:(int32_t)seed
{
    return [[[self alloc] initWithFrequency:frequency octaveCount:octaveCount persistence:persistence lacunarity:lacunarity seed:seed] autorelease];
}

- (instancetype)init
{
    return [self initWithFrequency:1.0 octaveCount:6 persistence:0.5 lacunarity:2.0 seed:0];
}

- (instancetype)initWithFrequency:(double)frequency octaveCount:(NSInteger)octaveCount persistence:(double)persistence lacunarity:(double)lacunarity seed:(int32_t)seed
{
    self = [super init];
    if (self != nil)
    {
        _frequency = frequency;
        _octaveCount = octaveCount;
        _persistence = persistence;
        _lacunarity = lacunarity;
        _seed = seed;
    }
    return self;
}

- (double)persistence { return _persistence; }
- (void)setPersistence:(double)persistence { _persistence = persistence; }

@end

@implementation GKBillowNoiseSource

+ (instancetype)billowNoiseSourceWithFrequency:(double)frequency octaveCount:(NSInteger)octaveCount persistence:(double)persistence lacunarity:(double)lacunarity seed:(int32_t)seed
{
    return [[[self alloc] initWithFrequency:frequency octaveCount:octaveCount persistence:persistence lacunarity:lacunarity seed:seed] autorelease];
}

- (instancetype)init
{
    return [self initWithFrequency:1.0 octaveCount:6 persistence:0.5 lacunarity:2.0 seed:0];
}

- (instancetype)initWithFrequency:(double)frequency octaveCount:(NSInteger)octaveCount persistence:(double)persistence lacunarity:(double)lacunarity seed:(int32_t)seed
{
    self = [super init];
    if (self != nil)
    {
        _frequency = frequency;
        _octaveCount = octaveCount;
        _persistence = persistence;
        _lacunarity = lacunarity;
        _seed = seed;
    }
    return self;
}

- (double)persistence { return _persistence; }
- (void)setPersistence:(double)persistence { _persistence = persistence; }

@end

@implementation GKRidgedNoiseSource

+ (instancetype)ridgedNoiseSourceWithFrequency:(double)frequency octaveCount:(NSInteger)octaveCount lacunarity:(double)lacunarity seed:(int32_t)seed
{
    return [[[self alloc] initWithFrequency:frequency octaveCount:octaveCount lacunarity:lacunarity seed:seed] autorelease];
}

- (instancetype)initWithFrequency:(double)frequency octaveCount:(NSInteger)octaveCount lacunarity:(double)lacunarity seed:(int32_t)seed
{
    self = [super init];
    if (self != nil)
    {
        _frequency = frequency;
        _octaveCount = octaveCount;
        _lacunarity = lacunarity;
        _seed = seed;
    }
    return self;
}

@end

@implementation GKVoronoiNoiseSource

+ (instancetype)voronoiNoiseWithFrequency:(double)frequency displacement:(double)displacement distanceEnabled:(BOOL)distanceEnabled seed:(int32_t)seed
{
    return [[[self alloc] initWithFrequency:frequency displacement:displacement distanceEnabled:distanceEnabled seed:seed] autorelease];
}

- (instancetype)init
{
    return [self initWithFrequency:1.0 displacement:1.0 distanceEnabled:NO seed:0];
}

- (instancetype)initWithFrequency:(double)frequency displacement:(double)displacement distanceEnabled:(BOOL)distanceEnabled seed:(int32_t)seed
{
    self = [super init];
    if (self != nil)
    {
        _frequency = frequency;
        _displacement = displacement;
        _distanceEnabled = distanceEnabled;
        _seed = seed;
    }
    return self;
}

- (double)frequency { return _frequency; }
- (void)setFrequency:(double)frequency { _frequency = frequency; }
- (double)displacement { return _displacement; }
- (void)setDisplacement:(double)displacement { _displacement = displacement; }
- (BOOL)isDistanceEnabled { return _distanceEnabled; }
- (void)setDistanceEnabled:(BOOL)distanceEnabled { _distanceEnabled = distanceEnabled; }
- (int32_t)seed { return _seed; }
- (void)setSeed:(int32_t)seed { _seed = seed; }

@end

@implementation GKConstantNoiseSource

+ (instancetype)constantNoiseWithValue:(double)value
{
    return [[[self alloc] initWithValue:value] autorelease];
}

- (instancetype)initWithValue:(double)value
{
    self = [super init];
    if (self != nil)
        _value = value;
    return self;
}

- (double)value { return _value; }
- (void)setValue:(double)value { _value = value; }

@end

@implementation GKCylindersNoiseSource

+ (instancetype)cylindersNoiseWithFrequency:(double)frequency
{
    return [[[self alloc] initWithFrequency:frequency] autorelease];
}

- (instancetype)init
{
    return [self initWithFrequency:1.0];
}

- (instancetype)initWithFrequency:(double)frequency
{
    self = [super init];
    if (self != nil)
        _frequency = frequency;
    return self;
}

- (double)frequency { return _frequency; }
- (void)setFrequency:(double)frequency { _frequency = frequency; }

@end

@implementation GKSpheresNoiseSource

+ (instancetype)spheresNoiseWithFrequency:(double)frequency
{
    return [[[self alloc] initWithFrequency:frequency] autorelease];
}

- (instancetype)init
{
    return [self initWithFrequency:1.0];
}

- (instancetype)initWithFrequency:(double)frequency
{
    self = [super init];
    if (self != nil)
        _frequency = frequency;
    return self;
}

- (double)frequency { return _frequency; }
- (void)setFrequency:(double)frequency { _frequency = frequency; }

@end

@implementation GKCheckerboardNoiseSource

+ (instancetype)checkerboardNoiseWithSquareSize:(double)squareSize
{
    return [[[self alloc] initWithSquareSize:squareSize] autorelease];
}

- (instancetype)init
{
    return [self initWithSquareSize:1.0];
}

- (instancetype)initWithSquareSize:(double)squareSize
{
    self = [super init];
    if (self != nil)
        _squareSize = squareSize;
    return self;
}

- (double)squareSize { return _squareSize; }
- (void)setSquareSize:(double)squareSize { _squareSize = squareSize; }

@end
