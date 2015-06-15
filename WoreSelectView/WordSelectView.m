//
//  WordSelectView.m
//  PPLabel
//
//  Created by renxin on 15/6/9.
//  Copyright (c) 2015年 Petr Pavlik. All rights reserved.
//

#import "WordSelectView.h"
#import <CoreText/CoreText.h>

#define TEXT_FONT_SIZE_NORMAL 12
#define REGULAR_DEFAULT @"\\*[^*]+\\*"

@implementation WordSelectRelationMap

@end

@interface WordSelectView()


@property (nonatomic, strong) NSMutableAttributedString     *m_stringShow;
@property (nonatomic, strong) NSMutableArray                *m_arrRelations;
@property (nonatomic, strong) NSMutableArray                *m_arrSelectedRange;
@property (nonatomic, strong) UIFont                        *m_fontNormal;
@property (nonatomic, strong) UIFont                        *m_fontSelected;
@property (nonatomic, strong) UIColor                       *m_colorNormal;
@property (nonatomic, strong) UIColor                       *m_colorRight;
@property (nonatomic, strong) UIColor                       *m_colorWrong;
@property (nonatomic, assign) WordType                       m_typeForSelecte;


@end

@implementation WordSelectView

- (id) initWithFrame:(CGRect) frame andString:(NSString *)string forSelect:(WordType) type
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _m_fontNormal = [UIFont systemFontOfSize:TEXT_FONT_SIZE_NORMAL];
        _m_fontSelected = _m_fontNormal;
        _m_colorNormal = [UIColor blackColor];
        _m_colorRight = [UIColor redColor];
        _m_colorWrong = [UIColor grayColor];
        _m_arrRelations = [[NSMutableArray alloc] initWithCapacity:0];
        _m_arrSelectedRange = [[NSMutableArray alloc] initWithCapacity:0];
        _m_typeForSelecte = type;
        
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor whiteColor];
        
        [self analyzeString:string withRegular:nil];
    }
    return self;
}

- (NSString *) analyzeString:(NSString *)string withRegular:(NSString *)regular
{
    NSString *result = [[NSString alloc] initWithString:string];
    NSString *_regular = regular;
    NSError  *error;
    
    if (nil == _regular)
    {
        _regular = REGULAR_DEFAULT;
    }
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:_regular
                                                                           options:0
                                                                             error:&error];
    while (true)
    {
        NSTextCheckingResult *match = nil;
        match = [regex firstMatchInString:result options:0 range:NSMakeRange(0, [result length])];
        if (nil == match)
        {
            break;
        }
        NSRange range = match.range;
        WordType type = WordTypeNone;
        
        switch ([result characterAtIndex:range.location])
        {
            case '*':
                type = WordTypeSubject;
                break;
            case '#':
                type = WordTypePredicate;
                break;
            case '+':
                type = WordTypeAccusative;
                break;
            default:
                break;
        }
        
        result = [result stringByReplacingCharactersInRange:NSMakeRange(range.location, 1) withString:@""];
        result = [result stringByReplacingCharactersInRange:NSMakeRange(range.location+range.length-2, 1) withString:@""];
        
        WordSelectRelationMap *aMap = [[WordSelectRelationMap alloc] init];
        aMap.m_range = NSMakeRange(range.location, range.length-2);
        aMap.m_type = type;
        
        [self.m_arrRelations addObject:aMap];
    }
    
    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
    [ps setAlignment:NSTextAlignmentLeft];
    NSDictionary *dictAttri = @{NSFontAttributeName: self.m_fontNormal,NSParagraphStyleAttributeName:ps};
    _m_stringShow = [[NSMutableAttributedString alloc] initWithString:result attributes:dictAttri];

    [self.m_stringShow addAttribute:(NSString*)kCTFontAttributeName value:[UIFont systemFontOfSize:20] range:NSMakeRange(0, self.m_stringShow.length)];
    
    return  result;
}

- (CFIndex) getCharacterIndexAtPoint:(CGPoint) point
{
    CGRect rect = self.bounds;
    point = CGPointMake(point.x, rect.size.height - point.y);
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.m_stringShow);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);
    CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, self.m_stringShow.length), path, NULL);
    
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineNum = CFArrayGetCount(lines);
    NSInteger index = NSNotFound;
    
    CGPoint lineOri[lineNum];
    
    CTFrameGetLineOrigins(frame, CFRangeMake(0, lineNum), lineOri);
    for(CFIndex i=0; i<lineNum; i++)
    {
        CGPoint lineOrigin = lineOri[i];
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGFloat ascent, descent, leading, width;
        width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        CGFloat yMin = floor(lineOrigin.y - descent);
        CGFloat yMax = ceil(lineOrigin.y + ascent);
        if (point.y > yMax)
        {
            break;
        }
        if(point.y >= yMin)
        {
            if (point.x >= lineOrigin.x && point.x <= lineOrigin.x + width)
            {
                CGPoint relativePoint = CGPointMake(point.x - lineOrigin.x, point.y - lineOrigin.y);
                index = CTLineGetStringIndexForPosition(line, relativePoint);
                break;
            }
        }
    }
    CGPathRelease(path);
    CFRelease(frame);
    CFRelease(frameSetter);
    
    return index;
}

- (void) showColorWithRangeMaps:(NSMutableArray*)arrRangeMaps
{
    for (int i=0; i<arrRangeMaps.count; i++)
    {
        WordSelectRelationMap *aMap = [arrRangeMaps objectAtIndex:i];
        [self setColorWithaMap:aMap];
    }
}

- (void) setColorWithaMap:(WordSelectRelationMap*)aMap
{
    if (self.m_typeForSelecte == aMap.m_type)
    {
        [self showColor:self.m_colorRight inRange:aMap.m_range];
    }
    else
    {
        [self showColor:self.m_colorWrong inRange:aMap.m_range];
    }
}

- (void) showColor:(UIColor*)color inRange:(NSRange) range
{
    [self.m_stringShow addAttribute:(NSString*)kCTForegroundColorAttributeName value:(__bridge id)color.CGColor range:range];
}

- (void) addRang:(NSRange)range
{
    WordSelectRelationMap *aMap = [[WordSelectRelationMap alloc] init];
    aMap.m_type = WordTypeNone;
    aMap.m_range = range;
    
    if ([self isRangeRightSelect:range])
    {
        aMap.m_type = self.m_typeForSelecte;
    }
    
    [self.m_arrSelectedRange addObject:aMap];
}

- (void) removeRange:(NSRange)range
{
    NSInteger index = [self getIndexOfRange:range];
    if (INT32_MAX != index)
    {
        [self.m_arrSelectedRange removeObjectAtIndex:index];
    }
}

-(NSInteger) getIndexOfRange:(NSRange)range
{
    float midOfRange = range.location + range.length/2;
    for (NSInteger i = 0; i<self.m_arrSelectedRange.count; i++)
    {
        WordSelectRelationMap *aMap = [self.m_arrSelectedRange objectAtIndex:i];
        NSRange aRange = aMap.m_range;
        
        if (midOfRange >= aRange.location && midOfRange <= aRange.location+aRange.length)
        {
            return i;
        }
    }
    return INT32_MAX;
}

- (BOOL) isRangeHaveSelected:(NSRange)range
{
    float midOfRange = range.location + range.length/2;
    for (int i = 0; i<self.m_arrSelectedRange.count; i++)
    {
        WordSelectRelationMap *aMap = [self.m_arrSelectedRange objectAtIndex:i];
        NSRange aRange = aMap.m_range;
        
        if (midOfRange >= aRange.location && midOfRange <= aRange.location+aRange.length)
        {
            return YES;
        }
    }
    
    return NO;

}

- (BOOL) isRangeRightSelect:(NSRange)range
{
    float midOfRange = range.location + range.length/2;
    for (NSInteger i = 0; i<self.m_arrRelations.count; i++)
    {
        WordSelectRelationMap *aMap = [self.m_arrRelations objectAtIndex:i];
        NSRange aRange = aMap.m_range;
        
        if (midOfRange >= aRange.location && midOfRange <= aRange.location+aRange.length)
        {
            return YES;
        }
    }
    return NO;
}

- (NSRange) getWordRangeAtIndex:(CFIndex) charIndex
{
    
    if (charIndex == NSNotFound)
    {
        return NSMakeRange(0, 0);
    }
    
    NSString *string = [self.m_stringShow string];
    
    NSRange end = [string rangeOfString:@" " options:0 range:NSMakeRange(charIndex, string.length - charIndex)];
    NSRange front = [string rangeOfString:@" " options:NSBackwardsSearch range:NSMakeRange(0, charIndex)];
    
    if (front.location == NSNotFound)
    {
        front.location = 0;
    }
    else
    {
        front.location += 1;
    }
    
    if (end.location == NSNotFound)
    {
        end.location = string.length-1;
    }
    else
    {
        end.location -= 1;
    }
    
    NSRange wordRange = NSMakeRange(front.location, end.location-front.location+1);
    
    return wordRange;
}

- (void) removeAllColor
{
    for (int i=0; i<self.m_arrSelectedRange.count; i++)
    {
        WordSelectRelationMap *aMap = [self.m_arrSelectedRange objectAtIndex:i];

        [self showColor:self.m_colorNormal inRange:aMap.m_range];
    }
    [self.m_arrSelectedRange removeAllObjects];
    [self setNeedsDisplay];
}

- (void) showResult
{
    for (int i=0; i<self.m_arrSelectedRange.count; i++)
    {
        WordSelectRelationMap *aMap = [self.m_arrSelectedRange objectAtIndex:i];
        if (self.m_typeForSelecte == aMap.m_type)
        {
            [self showColor:self.m_colorRight inRange:aMap.m_range];
        }
        else
        {
            [self showColor:self.m_colorWrong inRange:aMap.m_range];
        }
    }
    [self setNeedsDisplay];
}

- (void) drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform textTran = CGAffineTransformIdentity;
    textTran = CGAffineTransformMakeTranslation(0.0, self.bounds.size.height);
    textTran = CGAffineTransformScale(textTran, 1.0, -1.0);
    CGContextConcatCTM(context, textTran);
    
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.m_stringShow);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);
    CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, self.m_stringShow.length), path, NULL);
    
    CTFrameDraw(frame, context);
    
    CGPathRelease(path);
    CFRelease(frame);
    CFRelease(frameSetter);
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CFIndex charIndex = [self getCharacterIndexAtPoint:[touch locationInView:self]];
    
    if (charIndex==NSNotFound)
    {
        return;
    }
    NSRange range = [self getWordRangeAtIndex:charIndex];
    if ([self isRangeHaveSelected:range])
    {
        [self removeRange:range];
    }
    else
    {
        [self addRang:range];
    }
    
    NSLog(@"selecte char at index:%ld", charIndex);
    
    for (int i=0; i<self.m_arrRelations.count; i++)
    {
        WordSelectRelationMap *aMap = [self.m_arrRelations objectAtIndex:i];
        if(aMap.m_type == self.m_typeForSelecte)
        {
            range = aMap.m_range;
            if (charIndex >= range.location && charIndex <= range.location+range.length)
            {
                break;
            }
        }
    }

    [super touchesEnded:touches withEvent:event];
    
    [self setNeedsDisplay];
}



@end
