//
//  ViewController.m
//  TEST_ATTR_002
//
//  Created by cxjwin on 13-7-16.
//  Copyright (c) 2013年 cxjwin. All rights reserved.
//

#import "ViewController.h"
#import "CoreTextView.h"
#import "NSMutableAttributedString+Weibo.h"

@interface ViewController ()<CoreTextViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad 
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // 我们需要绘制的文本内容
    NSString *text 
    = @"http://t.cn/123QHz http://t.cn/1er6Hz [兔子][熊猫][给力][浮云][熊猫]   http://t.cn/1er6Hz   \
    [熊猫][熊猫][熊猫][熊猫] Hello World 你好世界[熊猫][熊猫]熊@猫熊猫[熊猫] #iOS# ";
    
    NSMutableAttributedString *newText = [NSMutableAttributedString weiboAttributedStringWithString:text];
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect frame = CGRectMake(0, 0, 200, 100);
    self.textView = [[CoreTextView alloc] initWithFrame:frame];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.textView.center = CGPointMake(CGRectGetMidX(screenBounds), CGRectGetMidY(screenBounds) - 10);
    self.textView.delegate = self;
    self.textView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.textView];
    
    frame = self.textView.frame;
    self.textView.attributedString = newText;
    frame.size = [CoreTextView adjustSizeWithAttributedString:newText maxWidth:150];
    self.textView.frame = frame;
}

#pragma mark - CoreTextViewDelegate
- (void)touchedURLWithURLStr:(NSString *)urlStr 
{
    NSURL *url = [NSURL URLWithString:urlStr];
    NSLog(@"url : %@", url);
    // TODO:打开url
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end