//
//  NSMutableAttributedString+Weibo.m
//  CoreTextDemo
//
//  Created by 蔡 雪钧 on 14-4-15.
//  Copyright (c) 2014年 cxjwin. All rights reserved.
//

#import <CoreText/CoreText.h>
#import "NSMutableAttributedString+Weibo.h"

NSString *const kCustomGlyphAttributeType = @"CustomGlyphAttributeType";
NSString *const kCustomGlyphAttributeRange = @"CustomGlyphAttributeRange";
NSString *const kCustomGlyphAttributeImageName = @"CustomGlyphAttributeImageName";
NSString *const kCustomGlyphAttributeInfo = @"CustomGlyphAttributeInfo";

NSString *const kRegexEmoji = @"\\[[a-zA-Z0-9\\u4e00-\\u9fa5]+\\]";
NSString *const kRegexShortLink = @"http://t.cn/[a-zA-Z0-9]+";

const CGFloat kLineSpacing = 4.0;
const CGFloat kContentTextSize = 13.0;
const CGFloat kAscentDescentScale = 0.25;

/* Callbacks */
static void deallocCallback(void *refCon) {
	free(refCon), refCon = NULL;
}

static CGFloat ascentCallback(void *refCon) {
	CustomGlyphMetricsRef metrics = (CustomGlyphMetricsRef)refCon;
	return metrics->ascent;
}

static CGFloat descentCallback(void *refCon) {
	CustomGlyphMetricsRef metrics = (CustomGlyphMetricsRef)refCon;
	return metrics->descent;
}

static CGFloat widthCallback(void *refCon) {
	CustomGlyphMetricsRef metrics = (CustomGlyphMetricsRef)refCon;
	return metrics->width;
}

@implementation NSMutableAttributedString (Weibo)

+ (NSDictionary *)weiboEmojiDictionary {
    static NSDictionary *emojiDictionary = nil;
    static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	    NSString *emojiFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"emotionImage.plist"];
	    emojiDictionary = [[NSDictionary alloc] initWithContentsOfFile:emojiFilePath];
	});
	return emojiDictionary;
}

+ (NSMutableAttributedString *)weiboAttributedStringWithString:(NSString *)string {
	// 匹配emoji
	NSRegularExpression *exp_emoji =
    [[NSRegularExpression alloc] initWithPattern:kRegexEmoji
                                         options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                           error:nil];
	NSArray *emojis = [exp_emoji matchesInString:string
	                                     options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
	                                       range:NSMakeRange(0, [string length])];
    
	NSMutableAttributedString *newStr = [[NSMutableAttributedString alloc] init];
	NSUInteger location = 0;
	for (NSTextCheckingResult *result in emojis) {
		NSRange range = result.range;
		NSString *subStr = [string substringWithRange:NSMakeRange(location, range.location - location)];
		NSMutableAttributedString *attSubStr = [[NSMutableAttributedString alloc] initWithString:subStr];
		[newStr appendAttributedString:attSubStr];
        
		location = range.location + range.length;
        
		NSString *emojiKey = [string substringWithRange:range];
		NSString *imageName = [[self weiboEmojiDictionary] objectForKey:emojiKey];
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
			metrics->descent = 12 * kAscentDescentScale;
			metrics->width = 16;
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
			NSString *rSubStr = [string substringWithRange:range];
			NSMutableAttributedString *originalStr = [[NSMutableAttributedString alloc] initWithString:rSubStr];
			[newStr appendAttributedString:originalStr];
		}
	}
    
	if (location < [string length]) {
		NSRange range = NSMakeRange(location, [string length] - location);
		NSString *subStr = [string substringWithRange:range];
		NSMutableAttributedString *attSubStr = [[NSMutableAttributedString alloc] initWithString:subStr];
		[newStr appendAttributedString:attSubStr];
	}
    
	// 匹配短链接
	NSString *__newStr = [newStr string];
	NSRegularExpression *exp_http =
    [[NSRegularExpression alloc] initWithPattern:kRegexShortLink
                                         options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                           error:nil];
	NSArray *https = [exp_http matchesInString:__newStr
	                                   options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
	                                     range:NSMakeRange(0, [__newStr length])];
    
	for (NSTextCheckingResult *result in https) {
		NSRange _range = [result range];
        
		// 设置自定义属性，绘制的时候需要用到
		[newStr addAttribute:kCustomGlyphAttributeType
		               value:[NSNumber numberWithInt:CustomGlyphAttributeURL]
		               range:_range];
		[newStr addAttribute:kCustomGlyphAttributeRange
		               value:[NSValue valueWithRange:_range]
		               range:_range];
	}
    
    // 匹配@
    NSString *regex_at = @"@[\\u4e00-\\u9fa5\\w\\-]+";
    NSRegularExpression *exp_at =
    [[NSRegularExpression alloc] initWithPattern:regex_at
                                         options:(NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators)
                                           error:nil];
    NSArray *ats =
    [exp_at matchesInString:__newStr
                    options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                      range:NSMakeRange(0, [__newStr length])];
    for (NSTextCheckingResult *result in ats) {
        NSRange _range = [result range];
        // 设置自定义属性，绘制的时候需要用到
        [newStr addAttribute:kCustomGlyphAttributeType
                       value:[NSNumber numberWithInt:CustomGlyphAttributeAt]
                       range:_range];
        [newStr addAttribute:kCustomGlyphAttributeRange
                       value:[NSValue valueWithRange:_range]
                       range:_range];
        [newStr addAttribute:NSForegroundColorAttributeName
                       value:[UIColor purpleColor]
                       range:_range];
    }
    
    // 匹配＃＃
    NSString *regex_topic = @"#([^\\#|.]+)#";
    NSRegularExpression *exp_topic =
    [[NSRegularExpression alloc] initWithPattern:regex_topic
                                         options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                           error:nil];
    NSArray *topics =
    [exp_topic matchesInString:__newStr
                       options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                         range:NSMakeRange(0, [__newStr length])];
    for (NSTextCheckingResult *result in topics) {
        NSRange _range = [result range];
        // 设置自定义属性，绘制的时候需要用到
        [newStr addAttribute:kCustomGlyphAttributeType
                       value:[NSNumber numberWithInt:CustomGlyphAttributeTopic]
                       range:_range];
        [newStr addAttribute:kCustomGlyphAttributeRange
                       value:[NSValue valueWithRange:_range]
                       range:_range];
        [newStr addAttribute:NSForegroundColorAttributeName
                       value:[UIColor purpleColor]
                       range:_range];
    }
    
    NSRange allTextRange = NSMakeRange(0, [newStr.string length]);
    [newStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:kContentTextSize] range:allTextRange];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.lineSpacing = kLineSpacing;
    [newStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:allTextRange];
    
	return newStr;
}

@end
