//
//  ICOCardScanner.m
//  icc
//
//  Created by Hua Xiong on 16/3/9.
//
//

#import "ICOCardScanner.h"

#import <TesseractOCR/TesseractOCR.h>
#import <CardIO/UIImage+OCR.h>

#define SCAN_FOREVER 0  // useful for debugging expiry

@interface ICOCardScanner () <G8TesseractDelegate>

@property (nonatomic, strong) NSOperationQueue *operationQueue;

// intentionally atomic -- card scanners get passed around between threads
@property(nonatomic, strong) NSDictionary *nameDict;
- (void)markCachesDirty;

@end

@implementation ICOCardScanner

- (void)markCachesDirty {
}

- (instancetype)init {
  if((self = [super init])) {
    [self markCachesDirty];
    self.cardInfo = [NSMutableDictionary dictionary];
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.nameDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FName" ofType:@"plist"]];
    NSLog(@"%@, name count %ld\n", [[NSBundle mainBundle] pathForResource:@"FName" ofType:@"plist"], [[self nameDict] count]);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recognizeOK:) name:@"kRecognizeOK" object:nil];
  }
  return self;
}

- (void)reset {
  [self markCachesDirty];
  self.cardInfo = [NSMutableDictionary dictionary];
}

- (void)addFrame:(UIImage *)y {
  
  if (self.complete) {
    return;
  }

  UIImage *image = [y ico_number_ocr_image_threshold:2];
  image = [self imageByDrawingRectsOnImage:image];
  G8RecognitionOperation *numOp = [self recognizeIDCardNumber:image];
  [self.operationQueue addOperation:numOp];

  [self markCachesDirty];
}

- (UIImage *)imageByDrawingRectsOnImage:(UIImage *)image {
  // begin a graphics context of sufficient size
  UIGraphicsBeginImageContext(image.size);
  
  // draw original image into the context
  [image drawAtPoint:CGPointZero];
  
  // get the context for CoreGraphics
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  
  // set stroking color and draw circle
  [[UIColor redColor] setStroke];
  
  // make name rect
  CGSize s = image.size;
  CGRect numberRect = CGRectMake(s.width / 3 - 1, 4 * s.height / 5 - 1, 2 * s.width / 3 / 10 * 9 + 2, 2 * s.height / 11 + 2);
  CGContextStrokeRectWithWidth(ctx, numberRect, 1);

  CGRect nameRect = CGRectMake(8 * s.width / 45 -1 , s.height / 11 - 1, 3 * s.width / 7 + 2, s.height / 7 + 2);
  CGContextStrokeRectWithWidth(ctx, nameRect, 1);

  // make image out of bitmap context
  UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
  
  // free the context
  UIGraphicsEndImageContext();
  
  return retImage;
}

- (G8RecognitionOperation *)recognizeIDCardNumber:(UIImage *)image {
  G8RecognitionOperation *operation = [[G8RecognitionOperation alloc] initWithLanguage:@"cid"];
  
  operation.tesseract.engineMode = G8OCREngineModeTesseractOnly;
  operation.tesseract.pageSegmentationMode = G8PageSegmentationModeSingleLine;
  operation.tesseract.maximumRecognitionTime = 1;
  operation.delegate = self;
  
  operation.tesseract.charWhitelist = @"0123456789X";
  operation.tesseract.charBlacklist = @" \t";
  operation.tesseract.image = image;
  
  CGSize s = image.size;
  operation.tesseract.rect = CGRectMake(s.width / 3 , 4 * s.height / 5, 2 * s.width / 3 / 10 * 9 , s.height / 5);
  
  NSTimeInterval b = [[NSDate date] timeIntervalSince1970];
  __block NSMutableDictionary *info = [NSMutableDictionary dictionary];
  operation.recognitionCompleteBlock = ^(G8Tesseract *tesseract) {
    NSString *recognizedText = [tesseract.recognizedText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSTimeInterval e = [[NSDate date] timeIntervalSince1970];
    BOOL ok = [self validateIDCardNumber:recognizedText];
    NSLog(@"elapse time = %0.3f ok = %d ##%@##", e-b, ok, recognizedText);
    
    if (ok && ![self complete]) {
      info[@"id"] = recognizedText;
      info[@"image"] = tesseract.image;
      info[@"image-id"] = tesseract.thresholdedImage;
      [[NSNotificationCenter defaultCenter] postNotificationName:@"kRecognizeOK" object:nil userInfo:info];
      
      G8RecognitionOperation *nameOp = [self recognizeIDCardName:image];
      [self.operationQueue addOperation:nameOp];
    }
  };
  
  return operation;
}

- (G8RecognitionOperation *)recognizeIDCardName:(UIImage *)image {
  G8RecognitionOperation *operation = [[G8RecognitionOperation alloc] initWithLanguage:@"chi_idcard"];
  operation.tesseract.engineMode = G8OCREngineModeTesseractOnly;
  operation.tesseract.pageSegmentationMode = G8PageSegmentationModeSingleLine;
  operation.tesseract.maximumRecognitionTime = 1;
  operation.delegate = self;
  
  operation.tesseract.charBlacklist = @"0123456789X \t";
  operation.tesseract.image = image;
  
  CGSize s = image.size;
  operation.tesseract.rect = CGRectMake(8 * s.width / 45 , s.height / 11, 3 * s.width / 7 , s.height / 7);
  
  NSTimeInterval b = [[NSDate date] timeIntervalSince1970];
  __block NSMutableDictionary *info = [NSMutableDictionary dictionary];
  operation.recognitionCompleteBlock = ^(G8Tesseract *tesseract) {
    NSString *recognizedText = [tesseract.recognizedText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSTimeInterval e = [[NSDate date] timeIntervalSince1970];
    NSLog(@"elapse time = %0.3f ok = %d ##%@##", e-b, 1, tesseract.characterChoices);
    for (int i = 0; i < [tesseract.characterChoices count] ; i ++) {
        NSArray *cs = tesseract.characterChoices[i];
      for (int j = 0; j < [cs count]; j ++) {
          G8RecognizedBlock *b = cs[j];
        NSLog(@"%@ %0.2f", b.text , b.confidence);
      }
      NSLog(@"<===============>");
    }
    
    if ([recognizedText length] > 0 && ![self complete]) {
      info[@"name"] = recognizedText;
      info[@"image"] = tesseract.image;
      info[@"image-name"] = tesseract.thresholdedImage;
      [[NSNotificationCenter defaultCenter] postNotificationName:@"kRecognizeOK" object:nil userInfo:info];
    }
  };
  
  return operation;
}

- (void)recognizeOK:(NSNotification *)n {
  [self.cardInfo addEntriesFromDictionary:n.userInfo];
  NSLog(@"success carinfo = %@",self.cardInfo);

}
- (BOOL)complete {
  return ([self.cardInfo count] >= 4);
}

/// 验证身份证号码
- (BOOL)validateIDCardNumber:(NSString *)idNumber {
  NSString *regex = @"(^\\d{15}$)|(^\\d{17}([0-9]|X)$)";
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
  if (![predicate evaluateWithObject:idNumber]) return NO;
  // 省份代码。如果需要更精确的话，可以把六位行政区划代码都列举出来比较。
  NSString *provinceCode = [idNumber substringToIndex:2];
  NSArray *proviceCodes = @[@"11", @"12", @"13", @"14", @"15",
                            @"21", @"22", @"23",
                            @"31", @"32", @"33", @"34", @"35", @"36", @"37",
                            @"41", @"42", @"43", @"44", @"45", @"46",
                            @"50", @"51", @"52", @"53", @"54",
                            @"61", @"62", @"63", @"64", @"65",
                            @"71", @"81", @"82", @"91"];
  if (![proviceCodes containsObject:provinceCode]) return NO;
  
  if (idNumber.length == 15) {
    return [self validate15DigitsIDCardNumber:idNumber];
  } else {
    return [self validate18DigitsIDCardNumber:idNumber];
  }
}

#pragma mark Helpers
/// 15位身份证号码验证。6位行政区划代码 + 6位出生日期码(yyMMdd) + 3位顺序码
- (BOOL)validate15DigitsIDCardNumber:(NSString *)idNumber {
  NSString *birthday = [NSString stringWithFormat:@"19%@", [idNumber substringWithRange:NSMakeRange(6, 6)]]; // 00后都是18位的身份证号
  
  return [self validateBirthDate:birthday];
}

/// 18位身份证号码验证。6位行政区划代码 + 8位出生日期码(yyyyMMdd) + 3位顺序码 + 1位校验码
- (BOOL)validate18DigitsIDCardNumber:(NSString *)idNumber {
  NSString *birthday = [idNumber substringWithRange:NSMakeRange(6, 8)];
  if (![self validateBirthDate:birthday]) return NO;
  
  // 验证校验码
  int weight[] = {7,9,10,5,8,4,2,1,6,3,7,9,10,5,8,4,2};
  
  int sum = 0;
  for (int i = 0; i < 17; i ++) {
    sum += [idNumber substringWithRange:NSMakeRange(i, 1)].intValue * weight[i];
  }
  int mod11 = sum % 11;
  NSArray<NSString *> *validationCodes = [@"1 0 X 9 8 7 6 5 4 3 2" componentsSeparatedByString:@" "];
  NSString *validationCode = validationCodes[mod11];
  
  return [idNumber hasSuffix:validationCode];
}

/// 验证出生年月日(yyyyMMdd)
- (BOOL)validateBirthDate:(NSString *)birthDay {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"yyyyMMdd";
  NSDate *date = [dateFormatter dateFromString:birthDay];
  return date != nil;
}

@end