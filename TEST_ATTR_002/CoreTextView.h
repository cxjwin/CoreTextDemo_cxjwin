//
//  CoreTextView.h
//  TEST_ATTR_002
//
//  Created by cxjwin on 13-7-29.
//  Copyright (c) 2013年 cxjwin. All rights reserved.
//

#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

@protocol CoreTextViewDelegate <NSObject>
@optional
- (void)touchedURLWithURLStr:(NSString *)urlStr;
@end

@interface CoreTextView : UIView

@property (weak, nonatomic) id<CoreTextViewDelegate> delegate;

@property (copy, nonatomic) NSMutableAttributedString *attributedString;
@property (nonatomic) CGFloat adjustWidth;
@property (nonatomic) CGSize adjustSize;

- (void)updateFrameWithAttributedString;
inline Boolean CFRangesIntersect(CFRange range1, CFRange range2);

@end