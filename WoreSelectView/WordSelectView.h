//
//  WordSelectView.h
//  PPLabel
//
//  Created by renxin on 15/6/9.
//  Copyright (c) 2015年 Petr Pavlik. All rights reserved.
//

#import <UIKit/UIKit.h>

//type
typedef enum
{
    WordTypeNone = 0,
    WordTypeSubject,
    WordTypePredicate,
    WordTypeAccusative,
}WordType;


//map
@interface WordSelectRelationMap : NSObject
@property(nonatomic, assign) NSRange m_range;
@property(nonatomic, assign) WordType m_type;
@end



//protocol
@protocol WordSelectViewDelegate <NSObject>
- (void) selectFinishedWithResult:(BOOL) isRightSelected;
@end


//view
@interface WordSelectView : UIView
@property(nonatomic,  weak) id <WordSelectViewDelegate> delegate;


- (id) initWithFrame:(CGRect) frame andString:(NSString *)string forSelect:(WordType) type;
- (void) showResult;
- (void) removeAllColor;


@end
