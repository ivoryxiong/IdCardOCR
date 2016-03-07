/*
	UIImage+Sizing.m

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

#import "UIImage+Sizing.h"
#import "UIColor+FullContact.h"

@implementation UIImage (Sizing)


#pragma mark - Scale

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size {
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    } else {
        UIGraphicsBeginImageContext(size);
    }
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
    return newImage;
}

#pragma mark - Circular Scale and Crop

+ (UIImage*)circularScaleAndCrop:(UIImage*)image withRect:(CGRect)rect {
    // This function returns a newImage, based on image, that has been:
    // - scaled to fit in (CGRect) rect
    // - and cropped within a circle of radius: rectWidth/2

    //Create the bitmap graphics context
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    //Get the width and heights
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;

    CGFloat rectWidth = rect.size.width;
    CGFloat rectHeight = rect.size.height;

    //Calculate the scale factor
    CGFloat scaleFactorX = rectWidth/imageWidth;
    CGFloat scaleFactorY = rectHeight/imageHeight;

    //Calculate the centre of the circle
    CGFloat imageCentreX = rectWidth/2;
    CGFloat imageCentreY = rectHeight/2;

    // Create and CLIP to a CIRCULAR Path
    // (This could be replaced with any closed path if you want a different shaped clip)
    CGFloat radius = rectWidth/2;
    CGContextBeginPath (context);
    CGContextAddArc (context, imageCentreX, imageCentreY, radius, 0, (CGFloat) (2*M_PI), 0);
    CGContextClosePath (context);
    CGContextClip (context);

    //Set the SCALE factor for the graphics context
    //All future draw calls will be scaled by this factor
    CGContextScaleCTM (context, scaleFactorX, scaleFactorY);

    // Draw the IMAGE
    CGRect myRect = CGRectMake(0, 0, imageWidth, imageHeight);


    // Create the clipping path and add it
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:myRect];
    [path addClip];
    [image drawInRect:myRect];

    CGContextSetStrokeColorWithColor(context, [RGB(200, 200, 200) CGColor]);
    [path setLineWidth:12.0f];
    [path stroke];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;

}


@end
