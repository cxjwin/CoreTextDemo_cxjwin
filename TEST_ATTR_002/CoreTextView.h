//
//  CoreTextView.h
//  TEST_ATTR_002
//
//  Created by cxjwin on 13-7-29.
//  Copyright (c) 2013年 cxjwin. All rights reserved.
//

#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

UIKIT_EXTERN NSString *const kCustomGlyphAttributeType;
UIKIT_EXTERN NSString *const kCustomGlyphAttributeRange;
UIKIT_EXTERN NSString *const kCustomGlyphAttributeImageName;
UIKIT_EXTERN NSString *const kCustomGlyphAttributeInfo;

typedef enum CustomGlyphAttributeType {
  CustomGlyphAttributeURL = 0,
  CustomGlyphAttributeImage,
  CustomGlyphAttributeInfoImage,// 预留，给带相应信息的图片（如点击图片获取相关属性）
}CustomGlyphAttributeType;

typedef struct CustomGlyphMetrics {
  CGFloat ascent;
  CGFloat descent;
  CGFloat width;
}CustomGlyphMetrics, *CustomGlyphMetricsRef;

@protocol CoreTextViewDelegate <NSObject>
@optional
- (void)touchedURLWithURLStr:(NSString *)urlStr;
@end

@interface CoreTextView : UIView

@property (weak, nonatomic) id<CoreTextViewDelegate> delegate;
@property (copy, nonatomic) NSMutableAttributedString *attributedString;
@property (assign, nonatomic) CGFloat adjustWidth;
@property (readonly, nonatomic) CGSize adjustSize;
@property (retain, nonatomic) UIColor *touchedColor;

- (void)updateFrameWithAttributedString;
inline Boolean CFRangesIntersect(CFRange range1, CFRange range2);

@end