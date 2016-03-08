//
//  ICOMacros.h
//  IdCardOCR
//
//  Created by Hua Xiong on 16/3/8.
//  Copyright © 2016年 ivoryxiong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ICOMacros : NSObject

+ (NSUInteger)deviceSystemMajorVersion;

+ (BOOL)appHasViewControllerBasedStatusBar;

@end

#define iOS_MAJOR_VERSION  [ICOMacros deviceSystemMajorVersion]
#define iOS_8_PLUS         (iOS_MAJOR_VERSION >= 8)
#define iOS_7_PLUS         (iOS_MAJOR_VERSION >= 7)
#define iOS_6              (iOS_MAJOR_VERSION == 6)
#define iOS_5              (iOS_MAJOR_VERSION == 5)
