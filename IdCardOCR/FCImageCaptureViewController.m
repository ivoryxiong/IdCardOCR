/*
	FCImageCaptureViewController.m

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

#import "FCImageCaptureViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIColor+FullContact.h"
#import "UIImage+Rotation.h"
#import "UIImage+Sizing.h"

@interface FCImageCaptureViewController ()

@property(nonatomic) BOOL deviceCanUseCamera;

@property(nonatomic) UIView *vImagePreview;
@property(nonatomic) UIView *camFocus;

@property(nonatomic) UIButton *flash;

@property(nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property(nonatomic) UIImagePickerController *imagePicker;

@property(nonatomic) UIImageView *cardOverlay;

@property(nonatomic) AVCaptureDevice *device;
@property(nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property(nonatomic) CGFloat lastRotation;

@property(nonatomic) int currentFlashChoice;

@end

@implementation FCImageCaptureViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	[self setupScreen];

	_imagePicker = [[UIImagePickerController alloc] init];
	_imagePicker.delegate = self;
	_imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

	_deviceCanUseCamera = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear | UIImagePickerControllerCameraCaptureModePhoto];

	if (!_deviceCanUseCamera || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.view addSubview:_imagePicker.view];
}

- (void)viewDidAppear:(BOOL)animated {
	if (_deviceCanUseCamera)
		[self startAVCapture];

	[UIView animateWithDuration:1.5f animations:^{
		_cardOverlay.alpha = 0;
	}];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)setupScreen {
	[[self.view subviews] enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
		if (obj != _vImagePreview)
			[obj removeFromSuperview];
	}];

	[[UIApplication sharedApplication] setStatusBarHidden:YES];
	[[self navigationController] setNavigationBarHidden:YES animated:NO];
	self.view.backgroundColor = [UIColor fullContactCoolGrayColor];

	UIView *captureRect = [[UIView alloc] initWithFrame:CGRectMake(37.5, 55, 245, 390)];
	UIButton *capture = [[UIButton alloc] initWithFrame:CGRectMake(120, 480, 80, 80)];
	UIButton *choose = [[UIButton alloc] initWithFrame:CGRectMake(268, 507, 32, 25)];
	_flash = [[UIButton alloc] initWithFrame:CGRectMake(221, 499, 40, 40)];
	UIButton *cancel = [[UIButton alloc] initWithFrame:CGRectMake(20, 505, 28, 28)];

	if (!_vImagePreview) {
		_vImagePreview = [UIImageView new];
		[_vImagePreview setFrame:self.view.bounds];
		[self.view addSubview:_vImagePreview];
		_cardOverlay = [[UIImageView alloc] initWithFrame:captureRect.bounds];
		_cardOverlay.image = [UIImage imageNamed:@"example-card"];
		[captureRect addSubview:_cardOverlay];
	}

	UIImageView *bracketTopLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bracket-top-left"]];
	[bracketTopLeft setFrame:CGRectMake(0, 0, 45, 45)];
	[captureRect addSubview:bracketTopLeft];

	UIImageView *bracketTopRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bracket-top-right"]];
	[bracketTopRight setFrame:CGRectMake(captureRect.bounds.size.width - 45, 0, 45, 45)];
	[captureRect addSubview:bracketTopRight];

	UIImageView *bracketBottomLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bracket-bottom-left"]];
	[bracketBottomLeft setFrame:CGRectMake(0, captureRect.bounds.size.height - 45, 45, 45)];
	[captureRect addSubview:bracketBottomLeft];

	UIImageView *bracketBottomRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bracket-bottom-right"]];
	[bracketBottomRight setFrame:CGRectMake(captureRect.bounds.size.width - 45, captureRect.bounds.size.height - 45, 45, 45)];
	[captureRect addSubview:bracketBottomRight];


	[capture setImage:[UIImage imageNamed:@"button-camera"] forState:UIControlStateNormal];
	[capture addTarget:self action:@selector(capture:) forControlEvents:UIControlEventTouchUpInside];

	switch (_currentFlashChoice) {
		case FlashOff:
			[_flash setImage:[UIImage imageNamed:@"flash-off"] forState:UIControlStateNormal];
	        break;
		case FlashOn:
			[_flash setImage:[UIImage imageNamed:@"flash-on"] forState:UIControlStateNormal];
	        break;
		case FlashAuto:
			[_flash setImage:[UIImage imageNamed:@"flash-auto"] forState:UIControlStateNormal];
	        break;

		default:
			break;
	}
	[_flash addTarget:self action:@selector(flashChoice:) forControlEvents:UIControlEventTouchUpInside];

	[cancel setImage:[UIImage imageNamed:@"icon-close-camera"] forState:UIControlStateNormal];
	[cancel addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];

	[choose setImage:[UIImage imageNamed:@"icon-photos"] forState:UIControlStateNormal];
	[choose addTarget:self action:@selector(library:) forControlEvents:UIControlEventTouchUpInside];

	[self.view addSubview:captureRect];
	[self.view addSubview:capture];
	[self.view addSubview:_flash];
	[self.view addSubview:cancel];
	[self.view addSubview:choose];
}

- (void)setFlashMode {
	NSError *deviceError;
	switch (_currentFlashChoice) {
		case FlashOff:
			if (_device.hasFlash) {
				[_device lockForConfiguration:&deviceError];
				_device.flashMode = AVCaptureFlashModeOff;
				[_device unlockForConfiguration];
			}
	        break;
		case FlashOn:
			if (_device.hasFlash) {
				[_device lockForConfiguration:&deviceError];
				_device.flashMode = AVCaptureFlashModeOn;
				[_device unlockForConfiguration];
			}
	        break;
		case FlashAuto:
			if (_device.hasFlash) {
				[_device lockForConfiguration:&deviceError];
				_device.flashMode = AVCaptureFlashModeAuto;
				[_device unlockForConfiguration];
			}
	        break;
		default:
			break;
	}
}

#pragma mark - Focusing Methods

- (void)focus:(CGPoint)aPoint; {
	if (_device != nil) {
		if ([_device isFocusPointOfInterestSupported] &&
				[_device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
			CGRect screenRect = [[UIScreen mainScreen] bounds];
			CGFloat screenWidth = screenRect.size.width;  //TODO:  CGFloat
			CGFloat screenHeight = screenRect.size.height;
			CGFloat focus_x = aPoint.x / screenWidth;
			CGFloat focus_y = aPoint.y / screenHeight;
			if ([_device lockForConfiguration:nil]) {
				[_device setFocusPointOfInterest:CGPointMake((CGFloat) focus_x, (CGFloat) focus_y)];
				[_device setFocusMode:AVCaptureFocusModeAutoFocus];
				if ([_device isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
					[_device setExposureMode:AVCaptureExposureModeAutoExpose];
				}
				[_device unlockForConfiguration];
			}
		}
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([self.view.subviews containsObject:_imagePicker.view])
		return;

	UITouch *touch = [[event allTouches] anyObject];
	CGPoint touchPoint = [touch locationInView:touch.view];
	[self focus:touchPoint];

	if (_camFocus)
		[_camFocus removeFromSuperview];

	if ([[touch view] isKindOfClass:[UIView class]]) {
		_camFocus = [[UIView alloc] initWithFrame:CGRectMake(touchPoint.x - 40, touchPoint.y - 40, 80, 80)];
		[_camFocus setBackgroundColor:[UIColor clearColor]];
		[_camFocus.layer setBorderWidth:2.0];
		[_camFocus.layer setCornerRadius:4.0];
		[_camFocus.layer setBorderColor:[UIColor whiteColor].CGColor];

		CABasicAnimation *selectionAnimation = [CABasicAnimation
				animationWithKeyPath:@"borderColor"];
		selectionAnimation.toValue = (id) [UIColor fullContactGreenColor].CGColor;
		selectionAnimation.repeatCount = 8;
		[_camFocus.layer addAnimation:selectionAnimation
		                       forKey:@"selectionAnimation"];

		[self.view addSubview:_camFocus];
		[_camFocus setNeedsDisplay];

		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:1.5];
		[_camFocus setAlpha:0.0];
		[UIView commitAnimations];
	}
}

- (void)startAVCapture {
	AVCaptureSession *session = [[AVCaptureSession alloc] init];
	session.sessionPreset = AVCaptureSessionPresetHigh;

	_captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];

	_captureVideoPreviewLayer.frame = self.vImagePreview.bounds;
	_captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	_captureVideoPreviewLayer.bounds = self.vImagePreview.bounds;
	[self.vImagePreview.layer addSublayer:_captureVideoPreviewLayer];

	_device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

	[self setFlashMode];
	NSError *deviceError;

	if ([_device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
		[_device lockForConfiguration:&deviceError];
		_device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
		[_device unlockForConfiguration];
	}
	if ([_device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
		[_device lockForConfiguration:&deviceError];
		_device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
		[_device unlockForConfiguration];
	}
	if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
		[_device lockForConfiguration:&deviceError];
		_device.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
		[_device unlockForConfiguration];
	}

	NSError *error = nil;
	AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
	if (!input) {
		NSLog(@"ERROR: trying to open camera: %@", error);
	}
	[session addInput:input];

	_stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
	NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
	[_stillImageOutput setOutputSettings:outputSettings];

	[session addOutput:_stillImageOutput];

	[session startRunning];
}

- (IBAction)capture:(id)sender {
	AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in _stillImageOutput.connections) {
		for (AVCaptureInputPort *port in [connection inputPorts]) {
			if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) {break;}
	}

	[_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
		NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
		UIImage *image = [[[UIImage alloc] initWithData:imageData] fixOrientationOfImage];

		CGFloat deviceScale = image.size.width / self.view.bounds.size.width;
		CGRect refRect = CGRectMake(37.5 * deviceScale, 55 * deviceScale, 245 * deviceScale, 390 * deviceScale);
		CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, refRect);
		UIImage *finalPhoto = [[UIImage alloc] initWithCGImage:imageRef scale:1 orientation:image.imageOrientation];

		CGImageRelease(imageRef);

		image = [UIImage imageWithImage:finalPhoto scaledToSize:CGSizeMake(600, 1050)];

        NSLog(@"width = %0.2f, height = %0.2f", image.size.width, image.size.height);

		if (_lastRotation == 0) {
			image = [image imageRotatedByDegrees:-90];
		} else {
			image = [image imageRotatedByDegrees:_lastRotation * -1];
		}

		if (_delegate)
			[_delegate imageCaptureController:self capturedImage:image];
	}];
}

- (IBAction)cancel:(id)sender {
	[_delegate imageCaptureControllerCancelledCapture:self];
}

- (IBAction)library:(id)sender {
	[self.view addSubview:_imagePicker.view];
}

- (IBAction)flashChoice:(id)sender {
	_currentFlashChoice++;
	if (_currentFlashChoice > 2)
		_currentFlashChoice = 0;
	[self setFlashMode];
	[self setupScreen];
}

#pragma mark - UIImagePickerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];

	if ((image.size.height < 240) & (image.size.width < 320)) {

		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Image Too Small" message:@"The selected image is too small to process.  Please select an image at least 320x240 in size." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
	}

	CGFloat width = image.size.width;
	CGFloat height = image.size.height;
	CGFloat newWidth;
	CGFloat newHeight;

    NSLog(@"width = %0.2f, height = %0.2f", width, height);
	if (width > height) {
		newWidth = 800;
		newHeight = 800 / width * height;
	} else {
		newWidth = 800 / height * width;
		newHeight = 800;
	}

	UIImage *newImage = [UIImage imageWithImage:image scaledToSize:CGSizeMake(newWidth, newHeight)];
	if (newHeight > newWidth)
		newImage = [newImage imageRotatedByDegrees:-90];

	NSLog(@"Scaled selected image to %fx%f", newImage.size.width, newImage.size.height);
	if (_delegate)
		[_delegate imageCaptureController:self capturedImage:newImage];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	if (_delegate && (!_deviceCanUseCamera || [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)) {
		[_delegate imageCaptureControllerCancelledCapture:self];
	} else {
		[_imagePicker.view removeFromSuperview];
	}
}

@end
