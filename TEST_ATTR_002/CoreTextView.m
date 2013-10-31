//
//  CoreTextView.m
//  TEST_ATTR_002
//
//  Created by cxjwin on 13-7-29.
//  Copyright (c) 2013年 cxjwin. All rights reserved.
//

#import "CoreTextView.h"
#import "NSString+Weibo.h"

#define kNoTouchIndex -1

@implementation CoreTextView 
{
    CTFrameRef textFrame;
    CFRange touchRange;
    CFIndex touchIndex;
    UITouchPhase touchPhase;
}

- (id)initWithFrame:(CGRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) {
        touchIndex = kNoTouchIndex;
        _adjustWidth = CGRectGetWidth(frame);
    }
    return self;
}

- (void)dealloc 
{
    if (textFrame) {
        CFRelease(textFrame), textFrame = NULL;
    }
}

// Don't use this method for origins. Origins always depend on the height of the rect.
CGPoint CGPointFlipped(CGPoint point, CGRect bounds) 
{
	return CGPointMake(point.x, CGRectGetMaxY(bounds) - point.y);
}

CGRect CGRectFlipped(CGRect rect, CGRect bounds) 
{
	return CGRectMake(CGRectGetMinX(rect),
                      CGRectGetMaxY(bounds) - CGRectGetMaxY(rect),
                      CGRectGetWidth(rect),
                      CGRectGetHeight(rect));
}

- (void)drawRect:(CGRect)rect 
{
    if (textFrame) {
        @autoreleasepool {
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGAffineTransform flipVertical = CGAffineTransformMake(1,0,0,-1,0,rect.size.height);
            CGContextConcatCTM(context, flipVertical);
            CGContextSetTextDrawingMode(context, kCGTextFill);
            
            // 获取CTFrame中的CTLine
            CFArrayRef lines = CTFrameGetLines(textFrame);
            CGPoint origins[CFArrayGetCount(lines)];
            CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), origins);
            
            for (int i = 0; i < CFArrayGetCount(lines); i++) {
                // 获取CTLine中的CTRun
                CTLineRef line = CFArrayGetValueAtIndex(lines, i);
                CFArrayRef runs = CTLineGetGlyphRuns(line);
                
                for (int j = 0; j < CFArrayGetCount(runs); j++) {
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
                        runBounds.size.width = CTRunGetTypographicBounds(run, 
                                                                         CFRangeMake(0, 0), 
                                                                         &ascent,
                                                                         &descent,
                                                                         &leading);        
                        runBounds.size.height = ascent + descent; 
                        CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringIndicesPtr(run)[0], NULL);
                        runBounds.origin.x = origins[i].x + xOffset;
                        runBounds.origin.y = origins[i].y - descent;
                        
                        int type = [num intValue];
                        if (type == CustomGlyphAttributeURL) {// 如果是绘制链接
                            // 先取出链接的文字范围，后算计算点击区域的时候要用
                            NSValue *value = [attDic valueForKey:kCustomGlyphAttributeRange];
                            NSRange _range = [value rangeValue];
                            CFRange linkRange = CFRangeMake(_range.location, _range.length);
                            
                            // 我们先绘制背景，不然文字会被背景覆盖
                            if (touchPhase == UITouchPhaseBegan) {// 点击开始
                                if (isTouchRange(touchIndex, linkRange, range)) {// 如果点击区域落在链接区域内
                                    CGColorRef tempColor = CGColorCreateCopyWithAlpha([UIColor lightGrayColor].CGColor, 1);
                                    CGContextSetFillColorWithColor(context, tempColor);
                                    CGColorRelease(tempColor);
                                    CGContextFillRect(context, runBounds);
                                    // 传回我们点击的链接
                                    if ([_delegate respondsToSelector:@selector(touchedURLWithURLStr:)]) {
                                        [_delegate touchedURLWithURLStr:[self.attributedString.string substringWithRange:_range]];
                                    }
                                }
                            } else {// 点击结束
                                if (isTouchRange(touchIndex, linkRange, range)) {// 如果点击区域落在链接区域内
                                    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
                                    CGContextFillRect(context, runBounds);
                                }
                            }
                            
                            // 这里需要绘制下划线，记住CTRun是不会自动绘制下滑线的
                            // 即使你设置了这个属性也不行
                            // CTRun.h中已经做出了相应的说明
                            // 所以这里的下滑线我们需要自己手动绘制
                            CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
                            CGContextSetLineWidth(context, 0.5);
                            CGContextMoveToPoint(context, runBounds.origin.x  , runBounds.origin.y);
                            CGContextAddLineToPoint(context, runBounds.origin.x + runBounds.size.width, runBounds.origin.y);
                            CGContextStrokePath(context);
                            
                            // 绘制文字
                            CTRunDraw(run, context, CFRangeMake(0, 0));
                        } else if (type == CustomGlyphAttributeImage) {// 如果是绘制表情
                            // 表情区域是不需要文字的，所以我们只进行图片的绘制
                            NSString *imageName = [attDic objectForKey:kCustomGlyphAttributeImageName];
                            UIImage *image = [UIImage imageNamed:imageName];
                            CGContextDrawImage(context, runBounds, image.CGImage);
                        }
                    } else {// 没有特殊处理的时候我们只进行文字的绘制
                        CTRunDraw(run, context, CFRangeMake(0, 0));
                    }
                }
            }
        }
    }
}

- (void)setAttributedString:(NSMutableAttributedString *)attributedString 
{
    if (_attributedString != attributedString) {
        _attributedString = attributedString;
        
        [self updateFrameWithAttributedString];
        [self setNeedsDisplay];
    }
}

- (void)updateFrameWithAttributedString 
{
    if (textFrame) {
        CFRelease(textFrame), textFrame = NULL;
    }
    
    CTFramesetterRef framesetter = 
    CTFramesetterCreateWithAttributedString((__bridge CFMutableAttributedStringRef)_attributedString);
    CGMutablePathRef path = CGPathCreateMutable();
    CFRange fitCFRange = CFRangeMake(0,0);
    CGSize maxSize = CGSizeMake(_adjustWidth, CGFLOAT_MAX);
    CGSize sz = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,CFRangeMake(0,0),NULL,maxSize,&fitCFRange);
    _adjustSize = sz;
    CGRect rect = (CGRect){CGPointZero, sz};
    CGPathAddRect(path, NULL, rect);
    
    textFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    
    CGPathRelease(path);
    CFRelease(framesetter);
}

Boolean CFRangesIntersect(CFRange range1, CFRange range2) 
{
    CFIndex max_location = MAX(range1.location, range2.location);
    CFIndex min_tail = MIN(range1.location + range1.length, range2.location + range2.length);
    if (min_tail - max_location > 0) {
        return TRUE;
    } else {
        return FALSE;
    }
}

Boolean isTouchRange(CFIndex index, CFRange touch_range, CFRange run_range) 
{
    if (touch_range.location < index && touch_range.location + touch_range.length >= index) {
        return CFRangesIntersect(touch_range, run_range);
    } else {
        return FALSE;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    CGPoint mirrorPoint = CGPointFlipped(point, self.bounds);
    
    CFArrayRef lines = CTFrameGetLines(textFrame);
    CGPoint origins[CFArrayGetCount(lines)];
    CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), origins);
    
    // 获取点击的文字位置
    CFIndex tempIndex = kNoTouchIndex;
    for (int i = 0; i < CFArrayGetCount(lines); i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        
        CGFloat ascent;
        CGFloat descent;
        CGFloat leading;
        CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        
        if ((origins[i].y - descent <= mirrorPoint.y) && 
            (origins[i].y + ascent >= mirrorPoint.y)) {
            tempIndex = CTLineGetStringIndexForPosition(line, mirrorPoint);
            touchPhase = touch.phase;
        }
    }
    
    touchIndex = tempIndex;
    // NSLog(@"touch index : %ld", touchIndex);
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{
    UITouch *touch = [touches anyObject];
    touchPhase = touch.phase;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
    UITouch *touch = [touches anyObject];
    touchPhase = touch.phase;
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event 
{
    UITouch *touch = [touches anyObject];
    touchPhase = touch.phase;
    [self setNeedsDisplay];
}

@end
