//
//  UIViewController+iPhoneModalController.m
//  HRApply
//
//  Created by Arthur Evstifeev on 21/03/13.
//  Copyright (c) 2013 Findly. All rights reserved.
//

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
    
    CGRect viewFrame        = self.view.bounds;
    viewFrame.size.height  -= controller.view.bounds.size.height;
    UIButton *hudButton     = [self hudButtonWithFrame:viewFrame];
    hudButton.alpha         = 0.0f;
    [self.view addSubview:hudButton];
    
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
