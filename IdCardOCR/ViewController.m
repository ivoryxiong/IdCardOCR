//
//  ViewController.m
//  IdCardOCR
//
//  Created by ivoryxiong on 16/2/25.
//  Copyright © 2016年 ivoryxiong. All rights reserved.
//

#import "ViewController.h"
#import "ICOCardScanner.h"

#import <TesseractOCR/TesseractOCR.h>
#import <CardIO/CardIOIdCardViewController.h>

@interface ViewController () <G8TesseractDelegate, CardIOIdCardViewControllerDelegate>
@property (nonatomic, strong) UIButton *autoRunnerBtn;
@property (nonatomic, strong) UIButton *pickerBtn;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) ICOCardScanner *scanner;

@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation ViewController

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = [UIColor orangeColor];
    
    [self.view addSubview:self.pickerBtn];
    self.pickerBtn.center = CGPointMake(CGRectGetMidX(self.view.bounds), 120);
    
    [self.view addSubview:self.imageView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create a queue to perform recognition operations
    self.operationQueue = [[NSOperationQueue alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSLog(@"%@ - %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

#pragma mark - actions

- (void)showPicker {
    if (self.scanner == nil) {
        self.scanner = [[ICOCardScanner alloc] init];
    }
    CardIOIdCardViewController *vc = [[CardIOIdCardViewController alloc] initWithIdCardDelegate:self scanner:self.scanner];
    [self.navigationController presentViewController:vc animated:YES completion:nil];
}

#pragma mark - CardIOIdCardViewControllerDelegate
- (void)userDidCancelIdCardViewController:(CardIOIdCardViewController *) idCardViewController {
    self.scanner = nil;
    
    [idCardViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)userDidProvideIdCardCardInfo:(NSDictionary *)cardInfo inIdCardViewController:(CardIOIdCardViewController *)idCardViewController {
    NSLog(@"====> card io info = %@", cardInfo);
    [self showCardInfo:cardInfo];
    self.scanner = nil;
    [idCardViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)showCardInfo:(NSDictionary *)cardInfo {
    UIImage *image = cardInfo[@"image"];
    if (image) {
        UIImage *imageToDisplay = [self fixrotation:image];
        self.imageView.image = imageToDisplay;
        CGFloat height = self.imageView.bounds.size.width / imageToDisplay.size.width * imageToDisplay.size.height;
        CGRect frame = self.imageView.frame;
        frame.size.height = height;
        self.imageView.frame = frame;
    }

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OCR Result"
                                                    message:[NSString stringWithFormat:@"name:%@\nid:%@", cardInfo[@"name"], cardInfo[@"id"]]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (UIImage *)fixrotation:(UIImage *)image{
    
    
    if (image.imageOrientation == UIImageOrientationUp) return image;
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
    
}
#pragma mark - view getters
- (UIButton *)pickerBtn {
    if (_pickerBtn == nil) {
        _pickerBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 120, 40)];
        _pickerBtn.backgroundColor = [UIColor whiteColor];
        [_pickerBtn setTitle:@"Pick Image" forState:UIControlStateNormal];
        [_pickerBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_pickerBtn addTarget:self action:@selector(showPicker) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _pickerBtn;
}

- (UIImageView *)imageView {
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(40, 200, self.view.bounds.size.width - 80, 120)];
    }
    
    return _imageView;
}
@end
