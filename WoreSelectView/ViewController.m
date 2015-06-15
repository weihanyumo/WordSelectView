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

@property (nonatomic, strong) IBOutlet UIButton *btnShow;
@property (nonatomic, strong) WordSelectView *m_wordView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.cStringUsingEncoding:NSUnicodeStringEncoding
    
    NSString *test = @"*this is* a word test, *dog* is dog and *cat* is cat, so what *i* am saying";
    _m_wordView = [[WordSelectView alloc] initWithFrame:CGRectMake(10, 20, self.view.frame.size.width-20, 300) andString:test forSelect:WordTypeSubject];
    _m_wordView.backgroundColor = [UIColor lightGrayColor];
    _m_wordView.delegate = self;
    [self.view addSubview:_m_wordView];
    
    
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

- (IBAction)shwoResult:(id)sender
{
    static int i=0;
    if (i%2==0) {
        i++;
        [self.m_wordView showResult];
        [self.btnShow setTitle:@"Clean" forState:UIControlStateNormal];
    }
    else
    {
        i--;
        [self.m_wordView removeAllColor];
        [self.btnShow setTitle:@"OK" forState:UIControlStateNormal];
    }
}



@end

