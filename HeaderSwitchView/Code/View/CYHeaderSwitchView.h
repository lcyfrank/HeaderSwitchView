//
//  CYHeaderSwitchView.h
//  HITool
//
//  Created by 林超阳 on 2018/3/21.
//  Copyright © 2018 Frank. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYHeaderCalculator.h"

@class CYHeaderSwitchView;

@protocol CYHeaderSwitchViewDelegate <NSObject>

@optional
- (void)headerSwitchView:(CYHeaderSwitchView *)switchView willChangeIndex:(NSUInteger)index;
- (void)headerSwitchView:(CYHeaderSwitchView *)switchView didChangeIndex:(NSUInteger)index;

@end

@interface CYHeaderSwitchView : UIView

@property (nonatomic, readonly, assign) NSUInteger currentIndex;        // indicate current index
@property (nonatomic, weak) id<CYHeaderSwitchViewDelegate> delegate;
@property (nonatomic, strong) CYHeaderCalculator *calculator;

@end
