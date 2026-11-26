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

#import <Foundation/Foundation.h>

#if __has_include(<simd/simd.h>)
#include <simd/simd.h>
#else
// The same vector types (and ABI) as Apple's <simd/simd.h>.
typedef float vector_float2 __attribute__((ext_vector_type(2)));
typedef float vector_float3 __attribute__((ext_vector_type(3)));
typedef int vector_int2 __attribute__((ext_vector_type(2)));
#endif

#define GK_EXPORT extern __attribute__((visibility("default")))
