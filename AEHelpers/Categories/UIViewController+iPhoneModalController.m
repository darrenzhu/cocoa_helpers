//
// UIViewController+iPhoneModalController.m
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

#import "UIViewController+iPhoneModalController.h"
#import "UIView+RelativePositioning.h"

@implementation UIViewController (iPhoneModalController)

static const CGFloat kDefaultAnimationInterval = 0.2f;

static UIViewController *currentModalController;
static UIButton *currentHudButton;

- (void)presentInIphoneModalViewController:(UIViewController *)controller {
    
    [self addChildViewController:controller];
    [controller.view setFrameBySettingNonZeroCoordinates:CGRectMake(0.0f, self.view.bounds.size.height, 0.0f, 0.0f)];
    [self.view addSubview:controller.view];
    
    UIButton *hudButton     = [self hudButtonWithFrame:self.view.bounds];
    hudButton.alpha         = 0.0f;
    [self.view insertSubview:hudButton belowSubview:controller.view];
    
    [UIView animateWithDuration:kDefaultAnimationInterval animations:^{
        
        hudButton.alpha     = 1.0f;
        [controller.view setFrameByAddingCoordinates:CGRectMake(0.0f, -controller.view.bounds.size.height, 0.0f, 0.0f)];
        
    } completion:^(BOOL finished) {
        
        currentHudButton        = hudButton;
    }];
    
    currentModalController = controller;
}

- (void)dismissIphoneModalViewController:(UIViewController *)controller {

    [currentHudButton removeFromSuperview];

    [UIView animateWithDuration:kDefaultAnimationInterval animations:^{
        
        [controller.view setFrameByAddingCoordinates:CGRectMake(0.0f, self.view.bounds.size.height, 0.0f, 0.0f)];
        
    } completion:^(BOOL finished) {
        
        [controller.view removeFromSuperview];
        [controller removeFromParentViewController];
        currentModalController  = nil;
        currentHudButton        = nil;
    }];
}

#pragma mark - private

- (UIButton *)hudButtonWithFrame:(CGRect)frame {
    
    UIButton *hudButton = [[UIButton alloc] initWithFrame:frame];
    [hudButton setBackgroundColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.3f]];
    [hudButton addTarget:self action:@selector(dismissCurrentModalController:)
        forControlEvents:UIControlEventTouchUpInside];
    
    return hudButton;
}

- (void)dismissCurrentModalController:(id)sender {
    
    if (!currentModalController) return;
    
    [self dismissIphoneModalViewController:currentModalController];
}

@end
