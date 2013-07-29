//
//  ViewController.m
//  TEST_ATTR_002
//
//  Created by cxjwin on 13-7-16.
//  Copyright (c) 2013年 cxjwin. All rights reserved.
//

#import <CoreText/CoreText.h>
#import "ViewController.h"
#import "CoreTextView.h"

@interface ViewController ()<CoreTextViewDelegate>

@property (strong, nonatomic) NSDictionary *emojiDic;
@property (copy, nonatomic) NSString *testText;
@property (weak, nonatomic) CoreTextView *textView;

@end

/* Callbacks */
static void deallocCallback(void *refCon){
  free(refCon), refCon = NULL;
}
static CGFloat ascentCallback(void *refCon){
  CustomGlyphMetricsRef metrics = (CustomGlyphMetricsRef)refCon;
  return metrics->ascent;
}
static CGFloat descentCallback(void *refCon){
  CustomGlyphMetricsRef metrics = (CustomGlyphMetricsRef)refCon;
  return metrics->descent;
}
static CGFloat widthCallback(void *refCon){
  CustomGlyphMetricsRef metrics = (CustomGlyphMetricsRef)refCon;
  return metrics->width;
}

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  
  // 表情字典，不同的表情文字对应一个表情图片地址
  NSString *emojiFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"emotionImage.plist"];
  self.emojiDic = [[NSDictionary alloc] initWithContentsOfFile:emojiFilePath];
  
  // 我们需要绘制的文本内容
  self.testText = @"http://t.cn/123QHz http://t.cn/1er6Hz [兔子][熊猫][给力][浮云][熊猫]   http://t.cn/1er6Hz   [熊猫][熊猫][熊猫][熊猫] Hello World 你好世界[熊猫][熊猫]";
  
  // 初始化文字界面
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  CGRect frame = CGRectMake(0, 0, 100, 100);
  CoreTextView *textView = [[CoreTextView alloc] initWithFrame:frame];
  textView.center = CGPointMake(CGRectGetMidX(screenBounds), CGRectGetMidY(screenBounds) - 10);
  self.textView = textView;
  textView.delegate = self;
  textView.backgroundColor = [UIColor whiteColor];
  [self transformText:self.testText];
  [self.view addSubview:textView];
}

// 将普通文字转化成绘文字
- (void)transformText:(NSString *)text {  
  @autoreleasepool {
    // 匹配emoji
    NSString *regex_emoji = @"\\[[a-zA-Z0-9\\u4e00-\\u9fa5]+\\]";
    NSRegularExpression *exp_emoji = 
    [[NSRegularExpression alloc] initWithPattern:regex_emoji
                                         options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                           error:nil];
    NSArray *emojis = [exp_emoji matchesInString:text 
                                         options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                           range:NSMakeRange(0, [text length])];
    
    NSMutableAttributedString *newStr = [[NSMutableAttributedString alloc] init];
    NSUInteger location = 0;
    for (NSTextCheckingResult *result in emojis) {
      NSRange range = result.range;
      NSString *subStr = [text substringWithRange:NSMakeRange(location, range.location - location)];
      NSMutableAttributedString *attSubStr = [[NSMutableAttributedString alloc] initWithString:subStr];
      [newStr appendAttributedString:attSubStr];
      
      location = range.location + range.length;
      
      NSString *emojiKey = [text substringWithRange:range];
      NSString *imageName = [self.emojiDic objectForKey:emojiKey];
      if (imageName) {
        // 这里不用空格，空格有个问题就是连续空格的时候只显示在一行
        NSMutableAttributedString *replaceStr = [[NSMutableAttributedString alloc] initWithString:@"-"];
        NSRange __range = NSMakeRange([newStr length], 1);
        [newStr appendAttributedString:replaceStr];
        
        // 定义回调函数
        CTRunDelegateCallbacks callbacks;
        callbacks.version = kCTRunDelegateVersion1;
        callbacks.getAscent = ascentCallback;
        callbacks.getDescent = descentCallback;
        callbacks.getWidth = widthCallback;
        callbacks.dealloc = deallocCallback;
        
        // 这里设置下需要绘制的图片的大小，这里我自定义了一个结构体以便于存储数据
        CustomGlyphMetricsRef metrics = malloc(sizeof(CustomGlyphMetrics));
        metrics->ascent = 11;
        metrics->descent = 4;
        metrics->width = 14;
        CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, metrics);
        [newStr addAttribute:(NSString *)kCTRunDelegateAttributeName 
                       value:(__bridge id)delegate 
                       range:__range];
        CFRelease(delegate);
        
        // 设置自定义属性，绘制的时候需要用到
        [newStr addAttribute:kCustomGlyphAttributeType 
                       value:[NSNumber numberWithInt:CustomGlyphAttributeImage] 
                       range:__range];
        [newStr addAttribute:kCustomGlyphAttributeImageName 
                       value:imageName
                       range:__range];
      } else {
        NSString *rSubStr = [text substringWithRange:range];
        NSMutableAttributedString *originalStr = [[NSMutableAttributedString alloc] initWithString:rSubStr];
        [newStr appendAttributedString:originalStr];
      }
    }
    
    if (location < [text length]) {
      NSRange range = NSMakeRange(location, [text length] - location);
      NSString *subStr = [text substringWithRange:NSMakeRange(location, range.location - location)];
      NSMutableAttributedString *attSubStr = [[NSMutableAttributedString alloc] initWithString:subStr];
      [newStr appendAttributedString:attSubStr];
    }
    
    // 匹配短链接
    NSString *__newStr = [newStr string];
    NSString *regex_http = @"http://t.cn/[a-zA-Z0-9]+";// 短链接的算法是固定的，格式比较一直，所以比较好匹配
    NSRegularExpression *exp_http = 
    [[NSRegularExpression alloc] initWithPattern:regex_http
                                         options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                           error:nil];
    NSArray *https = [exp_http matchesInString:__newStr
                                       options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators 
                                         range:NSMakeRange(0, [__newStr length])];
    
    for (NSTextCheckingResult *result in https) {
      NSRange _range = [result range];
      
      // 因为绘制用的是CTRun所以这个属性设置了也没有用
      /*
      CTUnderlineStyle style = kCTUnderlineStyleSingle;
      CFNumberRef underlineStyle = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &style);
      [newStr addAttribute:(id)kCTUnderlineStyleAttributeName
                     value:(__bridge id)underlineStyle
                     range:_range];
      CFRelease(underlineStyle);
      */
      
      // 设置自定义属性，绘制的时候需要用到
      [newStr addAttribute:kCustomGlyphAttributeType 
                     value:[NSNumber numberWithInt:CustomGlyphAttributeURL] 
                     range:_range];
      [newStr addAttribute:kCustomGlyphAttributeRange 
                     value:[NSValue valueWithRange:_range] 
                     range:_range];
    }
    
    // 根据绘文字计算一个建议的尺寸，那么我们绘制的区域会刚好合适
    self.textView.attributedString = newStr;
    CGRect frame = self.textView.frame;
    frame.size = self.textView.adjustSize;
    self.textView.frame = frame;
  }
}

#pragma mark - CoreTextViewDelegate
- (void)touchedURLWithURLStr:(NSString *)urlStr {
  NSURL *url = [NSURL URLWithString:urlStr];
  NSLog(@"url : %@", url);
  // TODO:打开url
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
