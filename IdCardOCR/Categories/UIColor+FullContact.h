/*
	UIColor+FullContact.h

	Created by Duane Schleen on 12/17/13.
	Copyright (c) 2013 FullContact Inc.

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	you may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
 */

#define RGB(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define RGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]

#import <Foundation/Foundation.h>

@interface UIColor (FullContact)

#pragma mark - Red

+ (UIColor *)fullContactRedColor;

#pragma mark - Orange

+ (UIColor *)fullContactOrangeColor;

#pragma mark - Gold

+ (UIColor *)fullContactGoldColor;

#pragma mark - Gray

+ (UIColor *)fullContactCoolGrayColor;

#pragma mark - Blue

+ (UIColor *)fullContactBlueColor;

#pragma mark - Green

+ (UIColor *)fullContactGreenColor;

#pragma mark - Purple

+ (UIColor *)fullContactPurpleColor;

@end
