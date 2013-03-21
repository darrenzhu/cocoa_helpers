//
//  UIView+RelativePositioning.m
//  HRApply
//
//  Created by Arthur Evstifeev on 28/02/13.
//  Copyright (c) 2013 Findly. All rights reserved.
//

#import "UIView+RelativePositioning.h"

@implementation UIView (RelativePositioning)

static const CGFloat eps = 0.001;

- (void)setFrameBySettingNonZeroCoordinates:(CGRect)rect {
    
    CGRect viewFrame        = self.frame;
    viewFrame.origin.x      = isNonZeroFloat(rect.origin.x) ? rect.origin.x : viewFrame.origin.x;
    viewFrame.origin.y      = isNonZeroFloat(rect.origin.y) ? rect.origin.y : viewFrame.origin.y;
    viewFrame.size.width    = isNonZeroFloat(rect.size.width) ? rect.size.width : viewFrame.size.width;
    viewFrame.size.height   = isNonZeroFloat(rect.size.height) ? rect.size.height : viewFrame.size.height;
    self.frame              = viewFrame;
}

- (void)setFrameByAddingCoordinates:(CGRect)rect {
    
    CGRect viewFrame        = self.frame;
    viewFrame.origin.x      += rect.origin.x;
    viewFrame.origin.y      += rect.origin.y;
    viewFrame.size.width    += rect.size.width;
    viewFrame.size.height   += rect.size.height;
    self.frame              = viewFrame;
}

- (void)setCenterByAddingCoordinates:(CGPoint)point {
    
    self.center = CGPointMake(self.center.x + point.x, self.center.y + point.y);
}

- (CGFloat)relativeHeight {
    
    return self.frame.origin.y + self.frame.size.height;
}

- (void)insertSubview:(UIView *)view positionedBelow:(UIView *)aboveView {
    
    CGRect viewFrame    = view.frame;
    viewFrame.origin.y  = [aboveView relativeHeight];
    view.frame          = viewFrame;
    [self addSubview:view];
}

#pragma mark - private

BOOL isNonZeroFloat(CGFloat value) {
    
    return ABS(value) > eps;
}

@end
