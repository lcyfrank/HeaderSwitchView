//
//  CYHeaderCalculator.m
//  HITool
//
//  Created by 林超阳 on 2018/3/26.
//  Copyright © 2018 Frank. All rights reserved.
//

#import "CYHeaderCalculator.h"

static NSString *const kMinimalIndex = @"_minimalIndex";
static NSString *const kMaximalIndex = @"_maximalIndex";
static NSString *const kDefaultIndex = @"_defaultIndex";
static NSString *const kPropertyChangedNotification = @"_PropertyChangedNotification";

@interface CYHeaderCalculator ()

@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, strong) NSNumberFormatter *numberFormatter;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation CYHeaderCalculator {
    CYCalculatorType _type;
    
    NSMutableDictionary *_cachedTitle;
    NSMutableDictionary *_cachedIndex;
}

#pragma mark - Lazy Load

- (NSCalendar *)calendar
{
    if (_calendar == nil) {
        _calendar = [NSCalendar currentCalendar];
        _calendar.timeZone = _timeZone;
        _calendar.locale = _locale;
    }
    return _calendar;
}

- (NSNumberFormatter *)numberFormatter
{
    if (_numberFormatter == nil) {
        _numberFormatter = [[NSNumberFormatter alloc] init];
        _numberFormatter.numberStyle = NSNumberFormatterSpellOutStyle;
        _numberFormatter.locale = _locale;
    }
    return _numberFormatter;
}

- (NSDateFormatter *)dateFormatter
{
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.locale = _locale;
        _dateFormatter.timeZone = _timeZone;
    }
    return _dateFormatter;
}


#pragma mark - Initializer

+ (instancetype)calculatorWithType:(CYCalculatorType)type
{
    return [[self alloc] initWithType:type];
}


- (instancetype)initWithType:(CYCalculatorType)type
{
    if (self = [super init]) {
        _type = type;
        _timeZone = [NSTimeZone localTimeZone];
        _locale = [NSLocale localeWithLocaleIdentifier:@"zh_Hans"];
        
        _cachedIndex = [NSMutableDictionary dictionary];
        _cachedTitle = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Interact With CYHeaderSwitchView

- (NSUInteger)minimalIndex {
    if ([[_cachedIndex allKeys] containsObject:kMinimalIndex]) {
        return [_cachedIndex[kMinimalIndex] unsignedIntegerValue];
    } else {
        NSUInteger minimalIndex = [self _getMinimalIndex];
        _cachedIndex[kMinimalIndex] = @(minimalIndex);
        return minimalIndex;
    }
}

- (NSUInteger)maximalIndex {
    if ([[_cachedIndex allKeys] containsObject:kMaximalIndex]) {
        return [_cachedIndex[kMaximalIndex] unsignedIntegerValue];
    } else {
        NSUInteger maximalIndex = [self _getMaximalIndex];
        _cachedIndex[kMaximalIndex] = @(maximalIndex);
        return maximalIndex;
    }
}

- (NSUInteger)defaultIndex {
    if ([[_cachedIndex allKeys] containsObject:kDefaultIndex]) {
        return [_cachedIndex[kDefaultIndex] unsignedIntegerValue];
    } else {
        NSUInteger defaultIndex = [self _getDefaultIndex];
        _cachedIndex[kDefaultIndex] = @(defaultIndex);
        return defaultIndex;
    }
}

- (NSString *)currentTitleOfIndex:(NSUInteger)index {
    if ([[_cachedTitle allKeys] containsObject:@(index)]) {
        return _cachedTitle[@(index)];
    } else {
        NSString *title = [self _getTitleOfIndex:index];
        _cachedTitle[@(index)] = title;
        return title;
    }
}

#pragma mark - Inner Method

- (NSUInteger)_getMinimalIndex {
    return 0;
}

- (NSUInteger)_getMaximalIndex {
    return [self _getIndexFromDate:_minimalDate toDate:_maximalDate];
}

- (NSUInteger)_getDefaultIndex {
    return [self _getIndexFromDate:_minimalDate toDate:[NSDate date]];
}

- (NSUInteger)_getIndexFromDate:(NSDate *)from toDate:(NSDate *)to {
    if (from == nil || to == nil) {
        return 0;
    }
    NSInteger index = 0;
    switch (_type) {
        case CYCalculatorTypeDay:
        case CYCalculatorTypeWeekDay:
            index = [self.calendar components:NSCalendarUnitDay fromDate:from toDate:to options:NSCalendarWrapComponents].day;
            break;
        case CYCalculatorTypeWeek:
        {
            NSInteger firstWeekDay = 1;  // Sunday
            NSInteger fromWeekDay = [self.calendar component:NSCalendarUnitWeekday fromDate:from];
            NSInteger toWeekDay = [self.calendar component:NSCalendarUnitWeekday fromDate:to];
            NSInteger fromDelta = (firstWeekDay - fromWeekDay - 7) % 7;
            NSInteger toDelta = (firstWeekDay - toWeekDay - 7) % 7;
            from = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:fromDelta toDate:from options:NSCalendarMatchNextTime];
            to = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:toDelta toDate:to options:NSCalendarMatchNextTime];
            index = [self.calendar components:NSCalendarUnitDay fromDate:from toDate:to options:NSCalendarWrapComponents].day / 7;
        }
            break;
        case CYCalculatorTypeMonth:
        {
            NSCalendarUnit componentsUnit = NSCalendarUnitYear | NSCalendarUnitMonth;
            NSDateComponents *fromComponents = [self.calendar components:componentsUnit fromDate:from];
            NSDateComponents *toComponents = [self.calendar components:componentsUnit fromDate:to];
            index = (toComponents.year - fromComponents.year) * 12 + (toComponents.month - fromComponents.month);
        }
            break;
    }
    return index < 0 ? 0 : index;
}

- (NSString *)_getTitleOfIndex:(NSUInteger)index {
    if (_minimalDate == nil || _maximalDate == nil) {
        return @"";
    }
    NSString *title;
    switch (_type) {
        case CYCalculatorTypeDay:
        {
            NSDate *date = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:index toDate:_minimalDate options:NSCalendarMatchLast];
            self.dateFormatter.dateFormat = @"MMM";
            NSString *monthString = [self.dateFormatter stringFromDate:date];
            NSInteger day = [self.calendar component:NSCalendarUnitDay fromDate:date];
            if ([self.locale.localeIdentifier hasPrefix:@"zh"]) {
                title = [NSString stringWithFormat:@"%@ %ld日", monthString, (long)day];
            } else if ([self.locale.localeIdentifier hasPrefix:@"en"]) {
                self.numberFormatter.numberStyle = NSNumberFormatterOrdinalStyle;
                title = [NSString stringWithFormat:@"%@ %@", monthString, [self.numberFormatter stringFromNumber:@(day)]];
            }
        }
            break;
        case CYCalculatorTypeWeek:
        {
            self.numberFormatter.numberStyle = NSNumberFormatterSpellOutStyle;
            NSString *numString = [self.numberFormatter stringFromNumber:@(index)];
            if ([self.locale.localeIdentifier hasPrefix:@"zh"]) {
                title = [NSString stringWithFormat:@"第%@周", numString];
            } else if ([self.locale.localeIdentifier hasPrefix:@"en"]) {
                title = [NSString stringWithFormat:@"Week %@", numString];
            }
        }
            break;
        case CYCalculatorTypeWeekDay:
        {
            NSDate *date = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:index toDate:_minimalDate options:NSCalendarMatchLast];
            self.dateFormatter.dateFormat = @"EEEE";
            title = [self.dateFormatter stringFromDate:date];
        }
            break;
        case CYCalculatorTypeMonth:
        {
            NSDate *date = [self.calendar dateByAddingUnit:NSCalendarUnitMonth value:index toDate:_minimalDate options:NSCalendarMatchLast];
            self.dateFormatter.dateFormat = @"MMMM";
            title = [self.dateFormatter stringFromDate:date];
        }
            break;
    }
    return title;
}

- (void)_clearCached {
    [_cachedIndex removeAllObjects];
    [_cachedTitle removeAllObjects];
}

- (void)_postPropertyChangedNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kPropertyChangedNotification object:self];
}

#pragma mark - Setter

- (void)setTimeZone:(NSTimeZone *)timeZone
{
    _timeZone = timeZone;
    if (_calendar)  {
        _calendar.timeZone = _timeZone;
    }
    [self _clearCached];
    [self _postPropertyChangedNotification];
}

- (void)setLocale:(NSLocale *)locale
{
    _locale = locale;
    if (_numberFormatter) {
        _numberFormatter.locale = _locale;
    }
    [self _clearCached];
    [self _postPropertyChangedNotification];
}

- (void)setMinimalDate:(NSDate *)minimalDate
{
    _minimalDate = minimalDate;
    [self _clearCached];
    [self _postPropertyChangedNotification];
}

- (void)setMaximalDate:(NSDate *)maximalDate
{
    _maximalDate = maximalDate;
    [self _clearCached];
    [self _postPropertyChangedNotification];
}

@end
