//
//  NSMutableAttributedString+Weibo.h
//  CoreTextDemo
//
//  Created by 蔡 雪钧 on 14-4-15.
//  Copyright (c) 2014年 cxjwin. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CTAttachmentChar "\uFFFC"
#define CTAttachmentCharacter @"\uFFFC"

extern NSString *const kCustomGlyphAttributeType;
extern NSString *const kCustomGlyphAttributeRange;
extern NSString *const kCustomGlyphAttributeImageName;
extern NSString *const kCustomGlyphAttributeInfo;

typedef enum CustomGlyphAttributeType {
    CustomGlyphAttributeURL = 0,
    CustomGlyphAttributeAt,
    CustomGlyphAttributeTopic,
    CustomGlyphAttributeImage,
    CustomGlyphAttributeInfoImage,// 预留，给带相应信息的图片（如点击图片获取相关属性）
} CustomGlyphAttributeType;

typedef struct CustomGlyphMetrics {
    CGFloat ascent;
    CGFloat descent;
    CGFloat width;
} CustomGlyphMetrics, *CustomGlyphMetricsRef;

@interface NSMutableAttributedString (Weibo)

+ (NSDictionary *)weiboEmojiDictionary;

+ (NSMutableAttributedString *)weiboAttributedStringWithString:(NSString *)string;

@end
