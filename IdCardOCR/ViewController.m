//
//  ViewController.m
//  IdCardOCR
//
//  Created by ivoryxiong on 16/2/25.
//  Copyright © 2016年 ivoryxiong. All rights reserved.
//

#import "ViewController.h"

#import "UIImage+IDOImgPrc.h"
#import "FCImageCaptureViewController.h"
#import <TesseractOCR/TesseractOCR.h>

@interface ViewController () <FCImageCaptureViewControllerDelegate, G8TesseractDelegate>
@property (nonatomic, strong) UIButton *autoRunnerBtn;
@property (nonatomic, strong) UIButton *pickerBtn;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation ViewController

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = [UIColor orangeColor];
    
    [self.view addSubview:self.pickerBtn];
    self.pickerBtn.center = CGPointMake(CGRectGetMidX(self.view.bounds), 120);
    
    [self.view addSubview:self.activityIndicator];
    self.activityIndicator.center = CGPointMake( self.pickerBtn.center.x,  self.pickerBtn.center.y + 60);
    [self.view addSubview:self.imageView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create a queue to perform recognition operations
    self.operationQueue = [[NSOperationQueue alloc] init];
}

-(void)recognizeImageWithTesseract:(UIImage *)image {
    // Animate a progress activity indicator
    [self.activityIndicator startAnimating];
    
    // Create a new `G8RecognitionOperation` to perform the OCR asynchronously
    // It is assumed that there is a .traineddata file for the language pack
    // you want Tesseract to use in the "tessdata" folder in the root of the
    // project AND that the "tessdata" folder is a referenced folder and NOT
    // a symbolic group in your project
    G8RecognitionOperation *operation = [[G8RecognitionOperation alloc] initWithLanguage:@"iv"];
    
    // Use the original Tesseract engine mode in performing the recognition
    // (see G8Constants.h) for other engine mode options
    operation.tesseract.engineMode = G8OCREngineModeTesseractOnly;
    
    // Let Tesseract automatically segment the page into blocks of text
    // based on its analysis (see G8Constants.h) for other page segmentation
    // mode options
    operation.tesseract.pageSegmentationMode = G8PageSegmentationModeAutoOnly;
    
    // Optionally limit the time Tesseract should spend performing the
    // recognition
    operation.tesseract.maximumRecognitionTime = 20.0;
    
    // Set the delegate for the recognition to be this class
    // (see `progressImageRecognitionForTesseract` and
    // `shouldCancelImageRecognitionForTesseract` methods below)
    operation.delegate = self;
    
    // Optionally limit Tesseract's recognition to the following whitelist
    // and blacklist of characters
//    operation.tesseract.charWhitelist = @"0123456789X";
    //operation.tesseract.charBlacklist = @"56789";
    
    // Set the image on which Tesseract should perform recognition
    operation.tesseract.image = image;
    
    // Optionally limit the region in the image on which Tesseract should
    // perform recognition to a rectangle
    //operation.tesseract.rect = CGRectMake(20, 20, 100, 100);
    
    // Specify the function block that should be executed when Tesseract
    // finishes performing recognition on the image
    operation.recognitionCompleteBlock = ^(G8Tesseract *tesseract) {
        // Fetch the recognized text
        NSString *recognizedText = tesseract.recognizedText;
        
        NSLog(@"%@", recognizedText);
        
        // Remove the animated progress activity indicator
        [self.activityIndicator stopAnimating];
        
        // Spawn an alert with the recognized text
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OCR Result"
                                                        message:recognizedText
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    };
    
    // Display the image to be recognized in the view
    //    self.imageToRecognize.image = operation.tesseract.thresholdedImage;
    
    // Finally, add the recognition operation to the queue
    [self.operationQueue addOperation:operation];
}

/**
 *  This function is part of Tesseract's delegate. It will be called
 *  periodically as the recognition happens so you can observe the progress.
 *
 *  @param tesseract The `G8Tesseract` object performing the recognition.
 */
- (void)progressImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    NSLog(@"progress: %lu", (unsigned long)tesseract.progress);
}

/**
 *  This function is part of Tesseract's delegate. It will be called
 *  periodically as the recognition happens so you can cancel the recogntion
 *  prematurely if necessary.
 *
 *  @param tesseract The `G8Tesseract` object performing the recognition.
 *
 *  @return Whether or not to cancel the recognition.
 */
- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    return NO;  // return YES, if you need to cancel recognition prematurely
}

- (void)clearCache:(id)sender {
    [G8Tesseract clearCache];
}
#pragma mark - actions
- (void)showPicker {
    FCImageCaptureViewController *imageCaptureController = [FCImageCaptureViewController new];
    imageCaptureController.delegate = self;
    [self.navigationController presentViewController:imageCaptureController animated:YES completion:nil];
}

#pragma mark - ImageCaptureViewControllerDelegate

- (void)imageCaptureControllerCancelledCapture:(FCImageCaptureViewController *)controller{
    
    [self recognizeImageWithTesseract:[UIImage imageNamed:@"test"]];

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageCaptureController:(FCImageCaptureViewController *)controller
                 capturedImage:(UIImage *)image {
    if (image) {
        UIImage *imageToDisplay = [self fixrotation:image];
        self.imageView.image = imageToDisplay;

//        self.imageView.image = [imageToDisplay ido_darkWhiteImage:0.2];
        CGFloat height = self.imageView.bounds.size.width / imageToDisplay.size.width * imageToDisplay.size.height;
        CGRect frame = self.imageView.frame;
        frame.size.height = height;
        self.imageView.frame = frame;
        
        [self recognizeImageWithTesseract:imageToDisplay];
    }

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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

- (UIActivityIndicatorView *)activityIndicator {
    if (_activityIndicator == nil) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    }
    
    return _activityIndicator;
}

- (UIImageView *)imageView {
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(40, 200, self.view.bounds.size.width - 80, 120)];
    }
    
    return _imageView;
}
@end
