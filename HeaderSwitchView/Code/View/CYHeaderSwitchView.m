//
//  CYHeaderSwitchView.m
//  HITool
//
//  Created by 林超阳 on 2018/3/21.
//  Copyright © 2018 Frank. All rights reserved.
//

#import "CYHeaderSwitchView.h"

static NSString *const kPropertyChangedNotification = @"_PropertyChangedNotification";

typedef enum : NSUInteger {
    _DirectionTypeForward,
    _DirectionTypeBackward,
} _DirectionType;

static NSNumberFormatter *_formatter = nil;

@interface CYHeaderSwitchView ()

@property (nonatomic, weak) UILabel *headerLabel;
@property (nonatomic, weak) UIButton *leftButton;
@property (nonatomic, weak) UIButton *rightButton;
@property (nonatomic, weak) UILabel *assistedLabel;

@property (nonatomic, strong) UITapGestureRecognizer *tap;

@end

@implementation CYHeaderSwitchView {
    BOOL _isAnimating;  // indicate if during animation now
    
    NSUInteger _currentIndex;  // indicate current index
    NSUInteger _defaultIndex;  // indicate default index
    NSUInteger _minIndex;  // indicate minimal index
    NSUInteger _maxIndex;  // indicate maximal index
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        CGFloat width = CGRectGetWidth(frame);
        CGFloat height = CGRectGetHeight(frame);
        
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, width - 120, height)];
        headerLabel.textAlignment = NSTextAlignmentCenter;
        headerLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
        headerLabel.userInteractionEnabled = YES;
        [self addSubview:headerLabel];
        self.headerLabel = headerLabel;
        
        UILabel *assistedLabel = [[UILabel alloc] init];
        assistedLabel.textAlignment = headerLabel.textAlignment;
        assistedLabel.font = headerLabel.font;
        assistedLabel.alpha = 0;
        assistedLabel.userInteractionEnabled = YES;
        [self addSubview:assistedLabel];
        self.assistedLabel = assistedLabel;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapToReset:)];
        self.tap = tap;
        
        UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeSystem];
        UIImage *left = [[UIImage imageNamed:@"left"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [leftButton setImage:left forState:UIControlStateNormal];
        leftButton.frame = CGRectMake(10, 0, 30, height);
        leftButton.hidden = YES;
        [self addSubview:leftButton];
        [leftButton addTarget:self action:@selector(_goDown:) forControlEvents:UIControlEventTouchUpInside];
        self.leftButton = leftButton;
        
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
        UIImage *right = [[UIImage imageNamed:@"right"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [rightButton setImage:right forState:UIControlStateNormal];
        rightButton.frame = CGRectMake(width - 40, 0, 30, height);
        rightButton.hidden = YES;
        [self addSubview:rightButton];
        [rightButton addTarget:self action:@selector(_goUp:) forControlEvents:UIControlEventTouchUpInside];
        self.rightButton = rightButton;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_calculatorChangedNotification:) name:kPropertyChangedNotification object:nil];
    }
    return self;
}

- (NSUInteger)currentIndex
{
    return _currentIndex;
}

- (void)setCalculator:(CYHeaderCalculator *)calculator
{
    _calculator = calculator;
    [self _initialToShow];
}

#pragma mark - Inner Method

- (void)_initialToShow {
    if (_calculator) {
        _minIndex = [_calculator minimalIndex];
        _maxIndex = [_calculator maximalIndex];
        _defaultIndex = [_calculator defaultIndex];
        _currentIndex = _defaultIndex;
        
        self.headerLabel.text = [_calculator currentTitleOfIndex:_defaultIndex];
        if (_defaultIndex == _minIndex) {
            self.leftButton.hidden = YES;
        } else {
            self.leftButton.hidden = NO;
        }
        if (_defaultIndex == _maxIndex) {
            self.rightButton.hidden = YES;
        } else {
            self.rightButton.hidden = NO;
        }
    }
}

- (void)_resetCurrent  // comeback to current week index
{
    [self _setCurrentIndex:_defaultIndex];
}

// set the current week to goal with animation
- (void)_setCurrentIndex:(NSUInteger)currentIndex
{
    if (_isAnimating) {
        return;
    }
    if (currentIndex == _currentIndex) {
        return;
    }
    
    _DirectionType direction = _DirectionTypeBackward;
    if (currentIndex < _currentIndex) {
        direction = _DirectionTypeForward;
    }
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(headerSwitchView:willChangeIndex:)]) {
        [self.delegate headerSwitchView:self willChangeIndex:currentIndex];
    }
    
    _currentIndex = [self _normalizedIndex:currentIndex];
    [self _updateHeaderLabelWithDirection:direction];
}

- (void)_updateHeaderLabelWithDirection:(_DirectionType)direction
{
    _isAnimating = YES;
    CGFloat distant = 50;
    if (direction == _DirectionTypeForward) {
        distant = -distant;
    }
    self.assistedLabel.text = [self.calculator currentTitleOfIndex:_currentIndex];
    CGRect headerFrame = self.headerLabel.frame;
    self.assistedLabel.frame = CGRectOffset(headerFrame, distant, 0);
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.headerLabel.frame = CGRectOffset(headerFrame, -distant, 0);
        self.headerLabel.alpha = 0;
        self.assistedLabel.frame = headerFrame;
        self.assistedLabel.alpha = 1;
    } completion:^(BOOL finished) {
        UILabel *tempLabel = self.assistedLabel;
        self.assistedLabel = self.headerLabel;
        self.headerLabel = tempLabel;
        [self.headerLabel addGestureRecognizer:self.tap];
        self->_isAnimating = NO;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(headerSwitchView:didChangeIndex:)]) {
            [self.delegate headerSwitchView:self didChangeIndex:self->_currentIndex];
        }
    }];
}

// to make the number valid
// and decide should hide the button
- (NSUInteger)_normalizedIndex:(NSUInteger)index
{
    if (index > _minIndex && index < _maxIndex) {
        if (_leftButton.hidden == YES) {
            _leftButton.hidden = NO;
        }
        if (_rightButton.hidden == YES) {
            _rightButton.hidden = NO;
        }
        return index;
    } else if (index <= _minIndex) {
        _leftButton.hidden = YES;
        return _minIndex;
    } else {
        _rightButton.hidden = YES;
        return _maxIndex;
    }
}

- (void)_calculatorChangedNotification:(NSNotification *)notification
{
    if (notification.object == _calculator) {
        [self _initialToShow];
    }
}

#pragma mark - touch event

- (void)_tapToReset:(UIGestureRecognizer *)sender
{
    [self _resetCurrent];
}

- (void)_goDown:(UIButton *)sender
{
    [self _setCurrentIndex:_currentIndex - 1];
}

- (void)_goUp:(UIButton *)sender
{
    [self _setCurrentIndex:_currentIndex + 1];
}

@end

