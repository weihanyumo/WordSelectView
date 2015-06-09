//
//  ViewController.m
//  WoreSelectView
//
//  Created by renxin on 15/6/9.
//  Copyright (c) 2015年 dhd. All rights reserved.
//


#import "ViewController.h"
#import "WordSelectView.h"


@interface ViewController ()<WordSelectViewDelegate>

@property(nonatomic) NSRange highlightedRange;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *test = @"*this* is a word test, *dog* is dog and *cat* is cat, so what *i* am saying???";
    WordSelectView *wordView = [[WordSelectView alloc] initWithFrame:CGRectMake(10, 20, 200, 300) andString:test forSelect:WordTypeSubject];
    wordView.delegate = self;
    [self.view addSubview:wordView];
    
}


#pragma mark WordSelectViewdDelegate
- (void) selectFinishedWithResult:(BOOL)isRightSelected
{
    if (isRightSelected)
    {
        NSLog(@"selected word right!!!");
    }
    else
    {
        NSLog(@"selected word wrong!!!");
    }
}

@end

