//
//  CYHeaderCalculator.h
//  HITool
//
//  Created by 林超阳 on 2018/3/26.
//  Copyright © 2018 Frank. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    CYCalculatorTypeDay,        // eg. Jan 1st
    CYCalculatorTypeWeek,       // eg. Week 1
    CYCalculatorTypeWeekDay,    // eg. Monday
    CYCalculatorTypeMonth,      // eg. January
} CYCalculatorType;

@interface CYHeaderCalculator : NSObject

@property (nonatomic, strong) NSTimeZone *timeZone;     // time-zone
@property (nonatomic, strong) NSLocale *locale;         // and locale

@property (nonatomic, strong) NSDate *minimalDate;      // minimal date
@property (nonatomic, strong) NSDate *maximalDate;      // maximal date

// the type of calculator
@property (nonatomic, assign, readonly) CYCalculatorType type;

+ (instancetype)calculatorWithType:(CYCalculatorType)type;
- (instancetype)initWithType:(CYCalculatorType)type;

#pragma mark - Method Interact With CYHeaderSwitchView

- (NSUInteger)minimalIndex;
- (NSUInteger)maximalIndex;
- (NSUInteger)defaultIndex;
- (NSString *)currentTitleOfIndex:(NSUInteger)index;

@end
