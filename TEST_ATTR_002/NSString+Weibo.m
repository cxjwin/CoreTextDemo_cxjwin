//
//  NSString+Weibo.m
//  CoreTextDemo
//
//  Created by cxjwin on 13-10-31.
//  Copyright (c) 2013年 cxjwin. All rights reserved.
//

#import "NSString+Weibo.h"

NSString *const kCustomGlyphAttributeType = @"CustomGlyphAttributeType";
NSString *const kCustomGlyphAttributeRange = @"CustomGlyphAttributeRange";
NSString *const kCustomGlyphAttributeImageName = @"CustomGlyphAttributeImageName";
NSString *const kCustomGlyphAttributeInfo = @"CustomGlyphAttributeInfo";

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

@implementation NSString (Weibo)

static NSDictionary *emojiDictionary = nil;
NSDictionary *SinaEmojiDictionary()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *emojiFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"emotionImage.plist"];
        emojiDictionary = [[NSDictionary alloc] initWithContentsOfFile:emojiFilePath];
    });
    return emojiDictionary;
}

- (NSMutableAttributedString *)transformText
{
    // 匹配emoji
    NSString *regex_emoji = @"\\[[a-zA-Z0-9\\u4e00-\\u9fa5]+\\]";
    NSRegularExpression *exp_emoji = 
    [[NSRegularExpression alloc] initWithPattern:regex_emoji
                                         options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                           error:nil];
    NSArray *emojis = [exp_emoji matchesInString:self 
                                         options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                           range:NSMakeRange(0, [self length])];
    
    NSMutableAttributedString *newStr = [[NSMutableAttributedString alloc] init];
    NSUInteger location = 0;
    for (NSTextCheckingResult *result in emojis) {
        NSRange range = result.range;
        NSString *subStr = [self substringWithRange:NSMakeRange(location, range.location - location)];
        NSMutableAttributedString *attSubStr = [[NSMutableAttributedString alloc] initWithString:subStr];
        [newStr appendAttributedString:attSubStr];
        
        location = range.location + range.length;
        
        NSString *emojiKey = [self substringWithRange:range];
        NSString *imageName = [SinaEmojiDictionary() objectForKey:emojiKey];
        if (imageName) {
            // 这里不用空格，空格有个问题就是连续空格的时候只显示在一行
            NSMutableAttributedString *replaceStr = [[NSMutableAttributedString alloc] initWithString:CTAttachmentCharacter];
            NSRange __range = NSMakeRange([newStr length], 1);
            [newStr appendAttributedString:replaceStr];
            
            // 定义回调函数
            CTRunDelegateCallbacks callbacks;
            callbacks.version = kCTRunDelegateCurrentVersion;
            callbacks.getAscent = ascentCallback;
            callbacks.getDescent = descentCallback;
            callbacks.getWidth = widthCallback;
            callbacks.dealloc = deallocCallback;
            
            // 这里设置下需要绘制的图片的大小，这里我自定义了一个结构体以便于存储数据
            CustomGlyphMetricsRef metrics = malloc(sizeof(CustomGlyphMetrics));
            metrics->ascent = 12;
            metrics->descent = 3;
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
            NSString *rSubStr = [self substringWithRange:range];
            NSMutableAttributedString *originalStr = [[NSMutableAttributedString alloc] initWithString:rSubStr];
            [newStr appendAttributedString:originalStr];
        }
    }
    
    if (location < [self length]) {
        NSRange range = NSMakeRange(location, [self length] - location);
        NSString *subStr = [self substringWithRange:range];
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
    
    return newStr;
}

@end
