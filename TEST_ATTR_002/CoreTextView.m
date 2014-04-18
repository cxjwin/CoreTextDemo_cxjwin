//
//  CoreTextView.m
//  TEST_ATTR_002
//
//  Created by cxjwin on 13-7-29.
//  Copyright (c) 2013年 cxjwin. All rights reserved.
//

#import "CoreTextView.h"
#import "NSMutableAttributedString+Weibo.h"

const CFIndex kNoTouchIndex = -1;
const CGPoint kErrorPoint = {.x = CGFLOAT_MAX, .y = CGFLOAT_MAX};

// Don't use this method for origins. Origins always depend on the height of the rect.
NS_INLINE CGPoint CGPointFlipped(CGPoint point, CGRect bounds) {
	return CGPointMake(point.x, CGRectGetMaxY(bounds) - point.y);
}

NS_INLINE CGRect CGRectFlipped(CGRect rect, CGRect bounds) {
	return CGRectMake(CGRectGetMinX(rect),
	                  CGRectGetMaxY(bounds) - CGRectGetMaxY(rect),
	                  CGRectGetWidth(rect),
	                  CGRectGetHeight(rect));
}

static Boolean isTouchRange(CFIndex index, CFRange touch_range, CFRange run_range) {
	if (touch_range.location < index && touch_range.location + touch_range.length >= index) {
		return CFRangesIntersect(touch_range, run_range);
	} else {
		return FALSE;
	}
}

@implementation CoreTextView  {
<<<<<<< HEAD
	CTFrameRef textFrame;
	CFRange touchRange;
	CFIndex touchIndex;
	
	CFIndex beginIndex;
	CFIndex endIndex;
	
=======
>>>>>>> FETCH_HEAD
	UITouchPhase touchPhase;
    
    CGPoint beginPoint;
	CGPoint endPoint;
    
    CFIndex beginIndex;
	CFIndex endIndex;
}

+ (CGSize)adjustSizeWithAttributedString:(NSAttributedString *)attributedString maxWidth:(CGFloat)width {
    CTFramesetterRef framesetter =
        CTFramesetterCreateWithAttributedString((__bridge CFMutableAttributedStringRef)attributedString);
    
    CGSize maxSize = CGSizeMake(width, CGFLOAT_MAX);
    CGSize size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, maxSize, NULL);

    CFRelease(framesetter);
    
    return CGSizeMake(floor(size.width) + 1, floor(size.height) + 1);
}

- (id)initWithFrame:(CGRect)frame  {
	self = [super initWithFrame:frame];
	if (self) {
		[self initCommon];
	}

	return self;
}

- (void)initCommon {
    touchPhase = UITouchPhaseCancelled;
}

- (void)drawRect:(CGRect)rect {
<<<<<<< HEAD
	if (textFrame) {
		@autoreleasepool {
			CGContextRef context = UIGraphicsGetCurrentContext();

			CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, rect.size.height);
			CGContextConcatCTM(context, flipVertical);
			CGContextSetTextDrawingMode(context, kCGTextFill);

			// 获取CTFrame中的CTLine
			CFArrayRef lines = CTFrameGetLines(textFrame);
			CGPoint origins[CFArrayGetCount(lines)];
			CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), origins);

			for (CFIndex i = 0; i < CFArrayGetCount(lines); ++i) {
				// 获取CTLine中的CTRun
				CTLineRef line = CFArrayGetValueAtIndex(lines, i);
				
				CGFloat ascent;
				CGFloat descent;
				CGFloat leading;
				CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
				
				if (touchPhase == UITouchPhaseBegan) {
					CGPoint mirrorPoint = CGPointFlipped(beginPoint, rect);
					if ((origins[i].y - descent <= mirrorPoint.y) &&
						(origins[i].y + ascent >= mirrorPoint.y)) {
						beginIndex = CTLineGetStringIndexForPosition(line, mirrorPoint);
					}
				} else if (touchPhase == UITouchPhaseEnded) {
					CGPoint mirrorPoint = CGPointFlipped(endPoint, rect);
					if ((origins[i].y - descent <= mirrorPoint.y) &&
						(origins[i].y + ascent >= mirrorPoint.y)) {
						endIndex = CTLineGetStringIndexForPosition(line, mirrorPoint);
					}
				}
				
				CFArrayRef runs = CTLineGetGlyphRuns(line);
				for (CFIndex j = 0; j < CFArrayGetCount(runs); ++j) {
					CTRunRef run = CFArrayGetValueAtIndex(runs, j);
					CFRange range = CTRunGetStringRange(run);
					CGContextSetTextPosition(context, origins[i].x, origins[i].y);

					// 获取CTRun的属性
					NSDictionary *attDic = (__bridge NSDictionary *)CTRunGetAttributes(run);
					NSNumber *num = [attDic objectForKey:kCustomGlyphAttributeType];
					if (num) {
						// 不管是绘制链接还是表情，我们都需要知道绘制区域的大小，所以我们需要计算下
						CGRect runBounds;
						CGFloat ascent;
						CGFloat descent;
						CGFloat leading;
						runBounds.size.width =
						    CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, &leading);

						runBounds.size.height = ascent + descent;
						CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringIndicesPtr(run)[0], NULL);
						runBounds.origin.x = origins[i].x + xOffset;
						runBounds.origin.y = origins[i].y - descent;

						int type = [num intValue];
						if (type == CustomGlyphAttributeURL) { // 如果是绘制链接
							// 先取出链接的文字范围，后算计算点击区域的时候要用
							NSValue *value = [attDic valueForKey:kCustomGlyphAttributeRange];
							NSRange _range = [value rangeValue];
							CFRange linkRange = CFRangeMake(_range.location, _range.length);

							// 我们先绘制背景，不然文字会被背景覆盖
							CGPoint mirrorBeginPoint = CGPointFlipped(beginPoint, rect);
							if (touchPhase == UITouchPhaseBegan && CGRectContainsPoint(runBounds, mirrorBeginPoint)) { // 点击开始
//								if (isTouchRange(touchIndex, linkRange, range)) { // 如果点击区域落在链接区域内
									CGColorRef tempColor = CGColorCreateCopyWithAlpha([UIColor lightGrayColor].CGColor, 1);
									CGContextSetFillColorWithColor(context, tempColor);
									CGColorRelease(tempColor);
									CGContextFillRect(context, runBounds);
//								}
							} else { // 点击结束
								if (isTouchRange(touchIndex, linkRange, range)) { // 如果点击区域落在链接区域内
									CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
									CGContextFillRect(context, runBounds);
								}

								CGPoint mirrorEndPoint = CGPointFlipped(endPoint, rect);
								if (touchPhase == UITouchPhaseEnded &&
								    CGRectContainsPoint(runBounds, mirrorEndPoint)) {
									if ([_delegate respondsToSelector:@selector(touchedURLWithURLStr:)]) {
										[_delegate touchedURLWithURLStr:[self.attributedString.string substringWithRange:_range]];
									}
								}
							}

							// 这里需要绘制下划线，记住CTRun是不会自动绘制下滑线的
							// 即使你设置了这个属性也不行
							// CTRun.h中已经做出了相应的说明
							// 所以这里的下滑线我们需要自己手动绘制
							CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
							CGContextSetLineWidth(context, 0.5);
							CGContextMoveToPoint(context, runBounds.origin.x, runBounds.origin.y);
							CGContextAddLineToPoint(context, runBounds.origin.x + runBounds.size.width, runBounds.origin.y);
							CGContextStrokePath(context);

							// 绘制文字
							CTRunDraw(run, context, CFRangeMake(0, 0));
						} else if (type == CustomGlyphAttributeImage) { // 如果是绘制表情
							// 表情区域是不需要文字的，所以我们只进行图片的绘制
							NSString *imageName = [attDic objectForKey:kCustomGlyphAttributeImageName];
							UIImage *image = [UIImage imageNamed:imageName];
							CGContextDrawImage(context, runBounds, image.CGImage);
						}
					} else { // 没有特殊处理的时候我们只进行文字的绘制
						CTRunDraw(run, context, CFRangeMake(0, 0));
					}
				}
			}
		}
=======
	if (self.attributedString) {
        
        CTFramesetterRef framesetter =
	    CTFramesetterCreateWithAttributedString((__bridge CFMutableAttributedStringRef)_attributedString);
        CGPathRef path = CGPathCreateWithRect(rect, &CGAffineTransformIdentity);
        CTFrameRef textFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
        
        CGContextRef context = UIGraphicsGetCurrentContext();

        CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, rect.size.height);
        CGContextConcatCTM(context, flipVertical);
        CGContextSetTextDrawingMode(context, kCGTextFill);

        // 获取CTFrame中的CTLine
        CFArrayRef lines = CTFrameGetLines(textFrame);
        CGPoint origins[CFArrayGetCount(lines)];
        CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), origins);

        // find touch begin index or touch end index
        for (CFIndex i = 0; i < CFArrayGetCount(lines); ++i) {
            CTLineRef line = CFArrayGetValueAtIndex(lines, i);
            CFArrayRef runs = CTLineGetGlyphRuns(line);
            for (CFIndex j = 0; j < CFArrayGetCount(runs); ++j) {
                CTRunRef run = CFArrayGetValueAtIndex(runs, j);
                
                CGFloat ascent;
                CGFloat descent;
                CGFloat leading;
                
                CGFloat width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, &leading);
                CGFloat height = ascent + descent;
                
                CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringIndicesPtr(run)[0], NULL);
                CGFloat x = origins[i].x + xOffset;
                CGFloat y = origins[i].y - descent;
                
                CGRect runBounds = CGRectMake(x, y, width, height);
                if (touchPhase == UITouchPhaseBegan) {
                    CGPoint mirrorPoint = CGPointFlipped(beginPoint, rect);
                    if (CGRectContainsPoint(runBounds, mirrorPoint)) {
                        beginIndex = CTLineGetStringIndexForPosition(line, mirrorPoint);
                    }
                } else if (touchPhase == UITouchPhaseEnded) {
                    CGPoint mirrorPoint = CGPointFlipped(endPoint, rect);
                    if (CGRectContainsPoint(runBounds, mirrorPoint)) {
                        endIndex = CTLineGetStringIndexForPosition(line, mirrorPoint);
                    }
                }
            }
        }
        
        // draw CTRun
        for (CFIndex i = 0; i < CFArrayGetCount(lines); ++i) {
            // 获取CTLine中的CTRun
            CTLineRef line = CFArrayGetValueAtIndex(lines, i);
            
            CGFloat lineAscent;
            CGFloat lineDescent;
            CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, NULL);
            
            CFArrayRef runs = CTLineGetGlyphRuns(line);
            for (CFIndex j = 0; j < CFArrayGetCount(runs); ++j) {
                CTRunRef run = CFArrayGetValueAtIndex(runs, j);
                CFRange range = CTRunGetStringRange(run);
                CGContextSetTextPosition(context, origins[i].x, origins[i].y);

                // 获取CTRun的属性
                NSDictionary *attDic = (__bridge NSDictionary *)CTRunGetAttributes(run);
                NSNumber *num = [attDic objectForKey:kCustomGlyphAttributeType];
                if (num) {
                    // 不管是绘制链接还是表情，我们都需要知道绘制区域的大小，所以我们需要计算下
                    CGFloat width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), NULL, NULL, NULL);
                    CGFloat height = lineAscent + lineDescent;
                    
                    CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringIndicesPtr(run)[0], NULL);
                    CGFloat x = origins[i].x + xOffset;
                    CGFloat y = origins[i].y - lineDescent;
                    
                    CGRect runBounds = CGRectMake(x, y, width, height);

                    int type = [num intValue];
                    // 如果是绘制链接,@,##
                    if (CustomGlyphAttributeURL <= type && type <= CustomGlyphAttributeTopic) {
                        // 先取出链接的文字范围，后算计算点击区域的时候要用
                        NSValue *value = [attDic valueForKey:kCustomGlyphAttributeRange];
                        NSRange _range = [value rangeValue];
                        CFRange linkRange = CFRangeFromNSRange(_range);

                        // 我们先绘制背景，不然文字会被背景覆盖
                        if (touchPhase == UITouchPhaseBegan &&
                             isTouchRange(beginIndex, linkRange, range)) { // 点击开始
                                
                            CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
                            CGContextFillRect(context, runBounds);
                        } else { // 点击结束
                            BOOL isSameRange = NO;
                            if (isTouchRange(beginIndex, linkRange, range)) { // 如果点击区域落在链接区域内
                                CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
                                CGContextFillRect(context, runBounds);
                                // beginIndex & endIndex in the same range
                                isSameRange = isTouchRange(endIndex, linkRange, range);
                            }
                            
                            CGPoint mirrorPoint = CGPointFlipped(endPoint, rect);
                            if (touchPhase == UITouchPhaseEnded &&
                                CGRectContainsPoint(runBounds, mirrorPoint) &&
                                isSameRange) {
                                
                                if (type == CustomGlyphAttributeURL) {
                                    if ([_delegate respondsToSelector:@selector(touchedURLWithURLStr:)]) {
                                        [_delegate touchedURLWithURLStr:[self.attributedString.string substringWithRange:_range]];
                                    }
                                } else if (type == CustomGlyphAttributeAt) {
                                    if ([_delegate respondsToSelector:@selector(touchedURLWithAtStr:)]) {
                                        [_delegate touchedURLWithAtStr:[self.attributedString.string substringWithRange:_range]];
                                    }
                                } else if (type == CustomGlyphAttributeTopic) {
                                    if ([_delegate respondsToSelector:@selector(touchedURLWithTopicStr:)]) {
                                        [_delegate touchedURLWithTopicStr:[self.attributedString.string substringWithRange:_range]];
                                    }
                                } else {
                                    NSAssert(NO, @"no this type");
                                }
                            }
                        }

                        // 这里需要绘制下划线，记住CTRun是不会自动绘制下滑线的
                        // 即使你设置了这个属性也不行
                        // CTRun.h中已经做出了相应的说明
                        // 所以这里的下滑线我们需要自己手动绘制
                        CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
                        CGContextSetLineWidth(context, 0.5);
                        CGContextMoveToPoint(context, runBounds.origin.x, runBounds.origin.y);
                        CGContextAddLineToPoint(context, runBounds.origin.x + runBounds.size.width, runBounds.origin.y);
                        CGContextStrokePath(context);
                        
                        // 绘制文字
                        CTRunDraw(run, context, CFRangeMake(0, 0));
                    } else if (type == CustomGlyphAttributeImage) { // 如果是绘制表情
                        // 表情区域是不需要文字的，所以我们只进行图片的绘制
                        NSString *imageName = [attDic objectForKey:kCustomGlyphAttributeImageName];
                        UIImage *image = [UIImage imageNamed:imageName];
                        CGContextDrawImage(context, runBounds, image.CGImage);
                    }
                } else { // 没有特殊处理的时候我们只进行文字的绘制
                    CTRunDraw(run, context, CFRangeMake(0, 0));
                }
            }
        }
        
        CFRelease(framesetter);
        CGPathRelease(path);
        CFRelease(textFrame);
>>>>>>> FETCH_HEAD
	}
}

- (void)setAttributedString:(NSMutableAttributedString *)attributedString {
	if (_attributedString != attributedString) {
		_attributedString = attributedString;
	}
    [self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self];
	beginPoint = point;
    touchPhase = touch.phase;
    beginIndex = kNoTouchIndex;
    
	[self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
    touchPhase = touch.phase;
    CGPoint point = [touch locationInView:self];
    if (!CGRectContainsPoint(self.bounds, point)) {
        [self touchesCancelled:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	endPoint = [touch locationInView:self];
	touchPhase = touch.phase;
    endIndex = kNoTouchIndex;

	[self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	touchPhase = touch.phase;
    endPoint = kErrorPoint;
    endIndex = kNoTouchIndex;

	[self setNeedsDisplay];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    if (!newWindow) {// disappear
        touchPhase = UITouchPhaseCancelled;
        endPoint = kErrorPoint;
        endIndex = kNoTouchIndex;
        
        [self setNeedsDisplay];
    }
}

@end
