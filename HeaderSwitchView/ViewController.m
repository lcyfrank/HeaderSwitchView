//
//  ViewController.m
//  HeaderSwitchView
//
//  Created by Frank Lin on 2018/5/24.
//  Copyright © 2018 Frank Lin. All rights reserved.
//

#import "ViewController.h"
#import "CYHeaderSwitchView.h"

@interface ViewController () <CYHeaderSwitchViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    CYHeaderSwitchView *headerView = [[CYHeaderSwitchView alloc] initWithFrame:CGRectMake(0, statusBarHeight, [UIScreen mainScreen].bounds.size.width, 44)];
    [self.view addSubview:headerView];
    
    // Delegate
    headerView.delegate = self;

    // Calculator
    CYHeaderCalculator *calculator = [CYHeaderCalculator calculatorWithType:CYCalculatorTypeMonth];
    calculator.minimalDate = [NSDate dateWithTimeIntervalSinceNow:-3600 * 24 * 100];  // 100 days age
    calculator.maximalDate = [NSDate dateWithTimeIntervalSinceNow:3600 * 24 * 100];   // 100 days after
    headerView.calculator = calculator;
}

@end
