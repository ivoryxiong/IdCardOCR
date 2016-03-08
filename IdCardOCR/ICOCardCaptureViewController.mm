//
//  ICOCardCaptureViewController.m
//  IdCardOCR
//
//  Created by Hua Xiong on 16/3/8.
//  Copyright © 2016年 ivoryxiong. All rights reserved.
//

#import "ICOCardCaptureViewController.h"
#import "ICOMacros.h"

#import "ViewController.h"

#import <CardIO/CardIO.h>
#import <stdint.h>

#pragma mark - Other constants

#define kStatusBarHeight      20

#define kButtonSizeOutset 20
#define kRotationAnimationDuration 0.2f
#define kButtonRotationDelay (kRotationAnimationDuration + 0.1f)

#define kDropShadowRadius 3.0f
#define kShadowInsets UIEdgeInsetsMake(-kDropShadowRadius, -kDropShadowRadius, -kDropShadowRadius, -kDropShadowRadius)

static inline CGRect CGRectRoundedToNearestPixel(CGRect rect) {
#ifdef __LP64__
    return CGRectMake(round(rect.origin.x),
                      round(rect.origin.y),
                      round(rect.size.width),
                      round(rect.size.height));
#else
    return CGRectMake(roundf(rect.origin.x),
                      roundf(rect.origin.y),
                      roundf(rect.size.width),
                      roundf(rect.size.height));
#endif
}

static inline CGRect CGRectWithRotatedRect(CGRect rect) {
    return CGRectMake(rect.origin.y, rect.origin.x, rect.size.height, rect.size.width);
}

@interface ICOCardCaptureViewController () <CardIOViewDelegate>

@property(nonatomic, strong, readwrite) CardIOView         *cardIOView;
@property(nonatomic, strong, readwrite) CALayer            *shadowLayer;
@property(nonatomic, assign, readwrite) BOOL                changeStatusBarHiddenStatus;
@property(nonatomic, assign, readwrite) BOOL                newStatusBarHiddenStatus;
@property(nonatomic, assign, readwrite) BOOL                statusBarWasOriginallyHidden;
@property(nonatomic, strong, readwrite) UIButton           *cancelButton;
@property(nonatomic, assign, readwrite) UIDeviceOrientation deviceOrientation;
@property(nonatomic, assign, readwrite) CGSize              cancelButtonFrameSize;

@end

#pragma mark -

@implementation ICOCardCaptureViewController

- (instancetype)init {
    if((self = [super init])) {
        if (iOS_7_PLUS) {
            self.automaticallyAdjustsScrollViewInsets = YES;
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
        else {
            self.wantsFullScreenLayout = YES;
        }
        _statusBarWasOriginallyHidden = [UIApplication sharedApplication].statusBarHidden;
    }
    return self;
}


#pragma mark - View Load/Unload sequence

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.15f alpha:1.0f];
    
    CGRect cardIOViewFrame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    cardIOViewFrame = CGRectRoundedToNearestPixel(cardIOViewFrame);
    self.cardIOView = [[CardIOView alloc] initWithFrame:cardIOViewFrame];
    
    self.cardIOView.delegate = self;
    self.cardIOView.languageOrLocale = @"zh-Hans";
    self.cardIOView.useCardIOLogo = NO;
    self.cardIOView.hideCardIOLogo = YES;
    self.cardIOView.guideColor = [UIColor orangeColor];
//    self.cardIOView.scannedImageDuration = 5;
    self.cardIOView.allowFreelyRotatingCardGuide = YES;
    
//    self.cardIOView.scanInstructions = nil;
    self.cardIOView.scanExpiry = NO;
//    self.cardIOView.scanOverlayView = self.context.scanOverlayView;
    
    //  self.cardIOView.detectionMode = self.context.detectionMode;
    self.cardIOView.detectionMode = CardIODetectionModeCardImageOnly;

    [self.view addSubview:self.cardIOView];
    
    _cancelButton = [self makeButtonWithTitle:@"Cancel" // Cancel
                                 withSelector:@selector(cancel:)];
    _cancelButtonFrameSize = self.cancelButton.frame.size;
    [self.view addSubview:self.cancelButton];
    
    // Add shadow to camera preview
    _shadowLayer = [CALayer layer];
    self.shadowLayer.shadowRadius = kDropShadowRadius;
    self.shadowLayer.shadowColor = [UIColor blackColor].CGColor;
    self.shadowLayer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.shadowLayer.shadowOpacity = 0.5f;
    self.shadowLayer.masksToBounds = NO;
    [self.cardIOView.layer insertSublayer:self.shadowLayer atIndex:0]; // must go *behind* everything
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.cardIOView.frame = self.view.bounds;
    
    // Only muck around with the status bar at all if we're in full screen modal style
    if (self.navigationController.modalPresentationStyle == UIModalPresentationFullScreen
        && [ICOMacros appHasViewControllerBasedStatusBar]
        && !self.statusBarWasOriginallyHidden) {
        
        self.changeStatusBarHiddenStatus = YES;
        self.newStatusBarHiddenStatus = YES;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.cardIOView layoutIfNeeded]; // otherwise self.cardIOView's layoutSubviews doesn't get called until *after* viewDidLayoutSubviews returns!
    
    // Re-layout shadow
    CGRect cameraPreviewFrame = self.cardIOView.cameraPreviewFrame;
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:UIEdgeInsetsInsetRect(cameraPreviewFrame, kShadowInsets)];
    self.shadowLayer.shadowPath = shadowPath.CGPath;
    
//    [self layoutButtonsForCameraPreviewFrame:self.cardIOView.cameraPreviewFrame];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.deviceOrientation = UIDeviceOrientationUnknown;
    
    self.cardIOView.hidden = NO;
    [self.navigationController setNavigationBarHidden:YES animated:animated];
        
//    [self didReceiveDeviceOrientationNotification:nil];
    
    NSLog(@"%@ - %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.changeStatusBarHiddenStatus) {
        [[UIApplication sharedApplication] setStatusBarHidden:self.newStatusBarHiddenStatus withAnimation:UIStatusBarAnimationFade];
        if (iOS_7_PLUS) {
            [self setNeedsStatusBarAppearanceUpdate];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.cardIOView.hidden = YES;
    if (self.changeStatusBarHiddenStatus) {
        [[UIApplication sharedApplication] setStatusBarHidden:self.statusBarWasOriginallyHidden withAnimation:UIStatusBarAnimationFade];
        if (iOS_7_PLUS) {
            [self setNeedsStatusBarAppearanceUpdate];
        }
    }
    [super viewWillDisappear:animated];
}

#pragma mark - Make the Cancel and Manual Entry buttons

- (UIButton *)makeButtonWithTitle:(NSString *)title withSelector:(SEL)selector {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    NSMutableDictionary *attributes = [@{
                                         NSStrokeWidthAttributeName : [NSNumber numberWithFloat:-1.0f]   // negative value => do both stroke & fill
                                         } mutableCopy];
    
    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:18.0f];
    attributes[NSForegroundColorAttributeName] = [UIColor colorWithWhite:1.0f alpha:0.8f];
    [button setAttributedTitle:[[NSAttributedString alloc] initWithString:title attributes:attributes] forState:UIControlStateNormal];
    
    attributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
    [button setAttributedTitle:[[NSAttributedString alloc] initWithString:title attributes:attributes] forState:UIControlStateHighlighted];
    
    CGSize buttonTitleSize = [button.titleLabel.attributedText size];
#ifdef __LP64__
    buttonTitleSize.height = ceil(buttonTitleSize.height);
    buttonTitleSize.width = ceil(buttonTitleSize.width);
#else
    buttonTitleSize.height = ceilf(buttonTitleSize.height);
    buttonTitleSize.width = ceilf(buttonTitleSize.width);
#endif
    button.bounds = CGRectMake(0, 0, buttonTitleSize.width + kButtonSizeOutset, buttonTitleSize.height + kButtonSizeOutset);
    
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

#pragma mark - View Controller orientation

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
//    return [self.navigationController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
//}
//
//- (BOOL)shouldAutorotate {
//    return [self.navigationController shouldAutorotate];
//}
//
//- (NSUInteger)supportedInterfaceOrientations {
//    return [self.navigationController supportedInterfaceOrientations];
//}

#pragma mark - Button orientation
//
//- (void)layoutButtonsForCameraPreviewFrame:(CGRect)cameraPreviewFrame {
//    if (cameraPreviewFrame.size.width == 0 || cameraPreviewFrame.size.height == 0) {
//        return;
//    }
//    
//    // - When setting each button's frame, it's simplest to do that without any rotational transform applied to the button.
//    //   So immediately prior to setting the frame, we set `button.transform = CGAffineTransformIdentity`.
//    // - Later in this method we set a new transform for each button.
//    // - We call [CATransaction setDisableActions:YES] to suppress the visible animation to the
//    //   CGAffineTransformIdentity position; for reasons we haven't explored, this is only desirable for the
//    //   InterfaceToDeviceOrientationRotatedClockwise and InterfaceToDeviceOrientationRotatedCounterclockwise rotations.
//    //   (Thanks to https://github.com/card-io/card.io-iOS-source/issues/30 for the [CATransaction setDisableActions:YES] suggestion.)
//    
//    InterfaceToDeviceOrientationDelta delta = orientationDelta([UIApplication sharedApplication].statusBarOrientation, self.deviceOrientation);
//    BOOL disableTransactionActions = (delta == InterfaceToDeviceOrientationRotatedClockwise ||
//                                      delta == InterfaceToDeviceOrientationRotatedCounterclockwise);
//    
//    if (disableTransactionActions) {
//        [CATransaction begin];
//        [CATransaction setDisableActions:YES];
//    }
//    
//    self.cancelButton.transform = CGAffineTransformIdentity;
//    self.cancelButton.frame = CGRectWithXYAndSize(cameraPreviewFrame.origin.x + 5.0f,
//                                                  CGRectGetMaxY(cameraPreviewFrame) - self.cancelButtonFrameSize.height - 5.0f,
//                                                  self.cancelButtonFrameSize);
//        
//    if (disableTransactionActions) {
//        [CATransaction commit];
//    }
//    
//    CGAffineTransform r;
//    CGFloat rotation = -rotationForOrientationDelta(delta); // undo the orientation delta
//    r = CGAffineTransformMakeRotation(rotation);
//    
//    switch (delta) {
//        case InterfaceToDeviceOrientationSame:
//        case InterfaceToDeviceOrientationUpsideDown: {
//            self.cancelButton.transform = r;
//            self.manualEntryButton.transform = r;
//            break;
//        }
//        case InterfaceToDeviceOrientationRotatedClockwise:
//        case InterfaceToDeviceOrientationRotatedCounterclockwise: {
//            CGFloat cancelDelta = (self.cancelButtonFrameSize.width - self.cancelButtonFrameSize.height) / 2;
//            CGFloat manualEntryDelta = (self.manualEntryButtonFrameSize.width - self.manualEntryButtonFrameSize.height) / 2;
//            if (delta == InterfaceToDeviceOrientationRotatedClockwise) {
//                cancelDelta = -cancelDelta;
//                manualEntryDelta = -manualEntryDelta;
//            }
//            self.cancelButton.transform = CGAffineTransformTranslate(r, cancelDelta, -cancelDelta);
//            self.manualEntryButton.transform = CGAffineTransformTranslate(r, manualEntryDelta, manualEntryDelta);
//            break;
//        }
//        default: {
//            break;
//        }
//    }
//}
//
//// Overlay orientation has the same constraints as the view controller,
//// unless self.config.allowFreelyRotatingCardGuide == YES.
//
//- (UIInterfaceOrientationMask)supportedOverlayOrientationsMask {
//    UIInterfaceOrientationMask supportedOverlayOrientationsMask = UIInterfaceOrientationMaskAll;
//    CardIOPaymentViewController *vc = [CardIOPaymentViewController cardIOPaymentViewControllerForResponder:self];
//    if (vc) {
//        supportedOverlayOrientationsMask = [vc supportedOverlayOrientationsMask];
//    }
//    return supportedOverlayOrientationsMask;
//}
//
//- (BOOL)isSupportedOverlayOrientation:(UIInterfaceOrientation)orientation {
//    return (([self supportedOverlayOrientationsMask] & (1 << orientation)) != 0);
//}
//
//- (UIInterfaceOrientation)defaultSupportedOverlayOrientation {
//    if (self.context.allowFreelyRotatingCardGuide) {
//        return UIInterfaceOrientationPortrait;
//    }
//    else {
//        UIInterfaceOrientation defaultOrientation = UIInterfaceOrientationUnknown;
//        UIInterfaceOrientationMask supportedOverlayOrientationsMask = [self supportedOverlayOrientationsMask];
//        for (NSInteger orientation = UIInterfaceOrientationMaskPortrait;
//             orientation <= UIInterfaceOrientationLandscapeRight;
//             orientation++) {
//            if ((supportedOverlayOrientationsMask & (1 << orientation)) != 0) {
//                defaultOrientation = (UIInterfaceOrientation)orientation;
//                break;
//            }
//        }
//        return defaultOrientation;
//    }
//}

#pragma mark - Status bar preferences (iOS 7)

- (BOOL)prefersStatusBarHidden {
    if (self.changeStatusBarHiddenStatus) {
        return self.newStatusBarHiddenStatus;
    }
    else {
        return YES;
    }
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Handle button taps


- (void)cancel:(id)sender {
    // Hiding the CardIOView causes it to call its stopSession method, thus eliminating a visible stutter.
    // See https://github.com/card-io/card.io-iOS-SDK/issues/97
    self.cardIOView.hidden = YES;
    
    [self.navigationController setNavigationBarHidden:NO animated:YES]; // to restore the color of the status bar!
    
//    CardIOPaymentViewController *root = (CardIOPaymentViewController *)self.navigationController;
//    [root.paymentDelegate userDidCancelPaymentViewController:root];
    
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - CardIOViewDelegate method

- (void)cardIOView:(CardIOView *)cardIOView didScanCard:(CardIOCreditCardInfo *)cardInfo {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSArray *vcs = [self.navigationController viewControllers];
    for (UIViewController *vc in vcs) {
        if ([vc isKindOfClass:[ViewController class]]) {
            [(ViewController *)vc updateImage:cardInfo.cardImage];
        }
    }

    [self.navigationController popViewControllerAnimated:YES];
}

@end