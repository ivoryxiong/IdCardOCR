//
//  UIImage+IDOImgPrc.m
//  IdCardOCR
//
//  Created by Hua Xiong on 16/2/26.
//  Copyright © 2016年 ivoryxiong. All rights reserved.
//

#import "UIImage+IDOImgPrc.h"

#import <OpenCV/opencv2/opencv.hpp>

@implementation UIImage (IDOImgPrc)

- (UIImage *)ido_darkWhiteImage:(CGFloat )fuzz {
    cv::Mat mat = [self ido_convertToCvMat];
    CV_Assert(mat.depth() == CV_8U);
    
    const int channels = mat.channels();
    switch(channels) {
        case 1: {
            cv::Mat_<uchar> _mat = mat;
            for( int i = 0; i < mat.rows; ++i)
                for( int j = 0; j < mat.cols; ++j ) {
                    uchar c = mat.at<uchar>(i,j);
                    if (c > 256 * 0.2) {
                        _mat(i,j) = 0;
                    }
                }
            mat = _mat;
            break;
        }
        case 4: {
            cv::Mat_<cv::Vec4b> _mat = mat;
            
            for( int i = 0; i < mat.rows; ++i)
                for( int j = 0; j < mat.cols; ++j ) {
                    if (_mat(i,j)[0] * _mat(i,j)[0] + _mat(i,j)[1] * _mat(i,j)[1] + _mat(i,j)[2] * _mat(i,j)[2] > 255 * 255 * 3 *0.2) {
                        _mat(i,j)[0] = _mat(i,j)[1] = _mat(i,j)[2] = 0;
                    }
                }
            mat = _mat;
            break;
        }
    }
    
    return [self ido_UIImageFromCVMat:mat];
}

- (cv::Mat)ido_convertToCvMat {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(self.CGImage);
    CGFloat cols = self.size.width;
    CGFloat rows = self.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), self.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

-(UIImage *)ido_UIImageFromCVMat:(cv::Mat)cvMat {
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}
@end
