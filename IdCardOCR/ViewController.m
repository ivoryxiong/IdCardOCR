//
//  ViewController.m
//  IdCardOCR
//
//  Created by ivoryxiong on 16/2/25.
//  Copyright © 2016年 ivoryxiong. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UIButton *autoRunnerBtn;
@property (nonatomic, strong) UIButton *pickerBtn;

@property (nonatomic, strong) UIImageView *imageView;
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
    
    self.title = @"ID Card OCR";
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - actions
- (void)showPicker {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {

    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (image) {
        self.imageView.image = image;
        CGFloat height = self.imageView.bounds.size.width / image.size.width * image.size.height;
        CGRect frame = self.imageView.frame;
        frame.size.height = height;
        self.imageView.frame = frame;
    }

    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
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
