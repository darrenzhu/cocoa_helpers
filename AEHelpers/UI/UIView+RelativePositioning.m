//
// UIView+RelativePositioning.m
//
// Copyright (c) 2012 ap4y (lod@pisem.net)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

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
