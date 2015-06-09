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
#define REGULAR_DEFAULT @"(\\*)([a-zA-Z0-9])*([\\*])"

@implementation WordSelectRelationMap

@end

@interface WordSelectView()


@property (nonatomic, strong) NSMutableArray                *m_arrRelations;
@property (nonatomic, strong) UIFont                        *m_fontNormal;
@property (nonatomic, strong) UIFont                        *m_fontSelected;
@property (nonatomic, strong) UIColor                       *m_colorNormal;
@property (nonatomic, strong) UIColor                       *m_colorSelected;
@property (nonatomic, strong) NSString                      *m_stringOri;
@property (nonatomic, strong) NSMutableAttributedString     *m_stringShow;
@property (nonatomic, assign) float                          m_lineSpace;
@property (nonatomic, assign) WordType                       m_typeForSelecte;
@property (nonatomic, assign) NSRange                        m_selectedRange;


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
        _m_colorSelected = [UIColor redColor];
        _m_arrRelations = [[NSMutableArray alloc] initWithCapacity:1];
        _m_lineSpace = 8;
        _m_typeForSelecte = type;
        _m_selectedRange = NSMakeRange(0, 0);
        
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
            }
        }
    }
    return index;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform textTran = CGAffineTransformIdentity;
    textTran = CGAffineTransformMakeTranslation(0.0, self.bounds.size.height);
    textTran = CGAffineTransformScale(textTran, 1.0, -1.0);
    CGContextConcatCTM(context, textTran);
    
    float drawLineX = 0;
    float drawLineY = 0;
    CFRange lineRange = CFRangeMake(0,0);
    CTTypesetterRef typeSetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.m_stringShow);
    drawLineY = self.bounds.origin.y + self.bounds.size.height;
    BOOL drawFlag = YES;
    
    while(drawFlag)
    {
        CFIndex testLineLength = CTTypesetterSuggestLineBreak(typeSetter,lineRange.location,self.bounds.size.width);
check:  lineRange = CFRangeMake(lineRange.location,testLineLength);
        CTLineRef line = CTTypesetterCreateLine(typeSetter,lineRange);
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        
        CTRunRef lastRun = CFArrayGetValueAtIndex(runs, CFArrayGetCount(runs) - 1);
        CGFloat lastRunAscent;
        CGFloat lastRunDescent;
        CGFloat leading;
        CGFloat lastRunWidth  = CTRunGetTypographicBounds(lastRun, CFRangeMake(0,0), &lastRunAscent, &lastRunDescent, &leading);
        CGFloat lastRunPointX = drawLineX + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(lastRun).location, NULL);
        
        if ((lastRunWidth + lastRunPointX) > self.bounds.size.width)
        {
            testLineLength--;
            CFRelease(line);
            goto check;
        }
        drawLineY -= (lastRunAscent + ABS(lastRunDescent) );
        if (drawLineY<self.bounds.origin.y)
        {
            CFRelease(line);
            break;
        }
        
        drawLineX = CTLineGetPenOffsetForFlush(line,0,self.bounds.size.width);
        CGContextSetTextPosition(context, drawLineX, drawLineY );
        
        CTLineDraw(line,context);
        
        if(lineRange.location + lineRange.length >= self.m_stringShow.length)
        {
            drawFlag = NO;
        }
        lineRange.location += lineRange.length;
        CFRelease(line);
    }
    
    CFRelease(typeSetter);
}

- (void)setWordColor:(UIColor*)color AtIndex:(CFIndex)charIndex
{
    if (charIndex==NSNotFound)
    {
        [self removeColor];
        return;
    }
    
    NSString* string = [self.m_stringShow string];;
    NSRange end = [string rangeOfString:@" " options:0 range:NSMakeRange(charIndex, string.length - charIndex)];
    NSRange front = [string rangeOfString:@" " options:NSBackwardsSearch range:NSMakeRange(0, charIndex)];
    
    if (front.location == NSNotFound)
    {
        front.location = 0;
    }
    
    if (end.location == NSNotFound)
    {
        end.location = string.length-1;
    }
    
    NSRange wordRange = NSMakeRange(front.location, end.location-front.location);
    
    if (front.location!=0) {
        wordRange.location += 1;
        wordRange.length -= 1;
    }
    [self.m_stringShow addAttribute:(NSString*)kCTForegroundColorAttributeName value:(__bridge id)color.CGColor range:wordRange];
}

- (void)removeColor
{
    if (self.m_selectedRange.length != 0)
    {
        [self.m_stringShow removeAttribute:(NSString*)kCTForegroundColorAttributeName range:self.m_selectedRange];
    }
    self.m_selectedRange = NSMakeRange(0, 0);
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CFIndex charIndex = [self getCharacterIndexAtPoint:[touch locationInView:self]];
    
    
    if (charIndex==NSNotFound)
    {
        return;
    }
    NSLog(@"selecte char at index:%ld", charIndex);
    BOOL isSelectedRightWord = NO;
    
    for (int i=0; i<self.m_arrRelations.count; i++)
    {
        WordSelectRelationMap *aMap = [self.m_arrRelations objectAtIndex:i];
        if(aMap.m_type == self.m_typeForSelecte)
        {
            NSRange range = aMap.m_range;
            if (charIndex >= range.location && charIndex <= range.location+range.length)
            {
                isSelectedRightWord = YES;
                break;
            }
        }
    }
    if (isSelectedRightWord)
    {
        [self setWordColor:self.m_colorSelected AtIndex:charIndex];
    }
    else
    {
        [self removeColor];
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(selectFinishedWithResult:)])
    {
        [_delegate selectFinishedWithResult:isSelectedRightWord];
    }
    
    [super touchesEnded:touches withEvent:event];
    
    [self setNeedsDisplay];
}



@end
