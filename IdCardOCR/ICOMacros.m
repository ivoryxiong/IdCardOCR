//
//  ICOMacros.m
//  IdCardOCR
//
//  Created by Hua Xiong on 16/3/8.
//  Copyright © 2016年 ivoryxiong. All rights reserved.
//

#import "ICOMacros.h"

@implementation ICOMacros

// Via recommended detection logic in the iOS7 prerelease docs:
// https://developer.apple.com/library/prerelease/ios/documentation/UserExperience/Conceptual/TransitionGuide/SupportingEarlieriOS.html

+ (NSUInteger)deviceSystemMajorVersion {
    static NSUInteger _deviceSystemMajorVersion = -1;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _deviceSystemMajorVersion = [[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] intValue];
    });
    return _deviceSystemMajorVersion;
}

+ (BOOL)appHasViewControllerBasedStatusBar {
    static BOOL _appHasViewControllerBasedStatusBar = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _appHasViewControllerBasedStatusBar = !iOS_7_PLUS || [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"] boolValue];
    });
    return _appHasViewControllerBasedStatusBar;
}

@end
