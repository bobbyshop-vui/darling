/*
 This file is part of Darling.

 Copyright (C) 2026 Darling Developers

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

/*
 * Accelerate does not ship the vImage headers here, so the matrix type is
 * declared locally. The layout matches Apple's vImage/vImage_Types.h:
 * five consecutive IEEE-754 single precision floats.
 */
typedef struct vImage_YpCbCrToARGBMatrix {
	float Yp;
	float Cr_R;
	float Cr_G;
	float Cb_G;
	float Cb_B;
} vImage_YpCbCrToARGBMatrix;

/* ITU-R Recommendation BT.601-4 (SD, 8-bit video range) */
const vImage_YpCbCrToARGBMatrix kvImage_YpCbCrToARGBMatrix_ITU_R_601_4 = {
	1.164384f,
	1.596027f,
	-0.812968f,
	-0.391762f,
	2.017232f,
};
