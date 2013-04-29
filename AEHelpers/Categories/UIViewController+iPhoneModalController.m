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

static const CGFloat kDefaultAnimationInterval  = 0.2f;
static const CGFloat kPageSheetSideGaps         = 20.0f;

static NSMutableArray *modalControllers;

- (void)presentInIphoneModalViewController:(UIViewController *)controller {
    
    [self presentInIphoneModalViewController:controller completion:nil];
}

- (void)presentInIphoneModalViewController:(UIViewController *)controller completion:(void (^)())completion {
    
    [self addChildViewController:controller];
    
    CGRect childRect = CGRectMake(0.0f, self.view.bounds.size.height, 0.0f, 0.0f);
    if (controller.modalPresentationStyle == UIModalPresentationPageSheet) {
        
        childRect = CGRectMake(kPageSheetSideGaps,
                               kPageSheetSideGaps,
                               [self windowSize].width - 2 * kPageSheetSideGaps,
                               [self windowSize].height - 3 * kPageSheetSideGaps);
        controller.view.alpha = 0.0f;
    }
    
    [controller.view setFrameBySettingNonZeroCoordinates:childRect];
    [self.view addSubview:controller.view];
    
    UIButton *hudButton = [self hudButtonWithFrame:self.view.bounds];
    hudButton.alpha     = 0.0f;
    hudButton.tag       = controller.hash;
    [self.view insertSubview:hudButton belowSubview:controller.view];
    
    [UIView animateWithDuration:kDefaultAnimationInterval animations:^{
        
        hudButton.alpha = 1.0f;
        if (controller.modalPresentationStyle == UIModalPresentationPageSheet) {
            
            controller.view.alpha = 1.0f;
            
        } else {
            
            [controller.view setFrameByAddingCoordinates:CGRectMake(0.0f, -controller.view.bounds.size.height,
                                                                    0.0f, 0.0f)];
        }
        
    } completion:^(BOOL finished) {
        
        [self pushController:controller];
        
        if (completion) completion();
    }];
}

- (void)dismissIphoneModalViewController:(UIViewController *)controller {
    
    [self dismissIphoneModalViewController:controller completion:nil];
}

- (void)dismissIphoneModalViewController:(UIViewController *)controller completion:(void (^)())completion {
    
    [[self.view viewWithTag:controller.hash] removeFromSuperview];
    
    [UIView animateWithDuration:kDefaultAnimationInterval animations:^{
        
        if (controller.modalPresentationStyle == UIModalPresentationPageSheet) {
            
            controller.view.alpha = 0.0f;
            
        } else {
            
            [controller.view setFrameByAddingCoordinates:CGRectMake(0.0f, self.view.bounds.size.height, 0.0f, 0.0f)];
        }
        
    } completion:^(BOOL finished) {
        
        [controller.view removeFromSuperview];
        [controller removeFromParentViewController];
        [self popController];
        
        if (completion) completion();
    }];
}

#pragma mark - private

- (UIButton *)hudButtonWithFrame:(CGRect)frame {
    
    UIButton *hudButton = [[UIButton alloc] initWithFrame:frame];
    [hudButton setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [hudButton setBackgroundColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.3f]];
    [hudButton addTarget:self
                  action:@selector(dismissCurrentModalController:)
        forControlEvents:UIControlEventTouchUpInside];
    
    return hudButton;
}

- (void)dismissCurrentModalController:(id)sender {
    
    UIViewController *currentModalController = [modalControllers lastObject];
    if (!currentModalController) return;
    
    [self dismissIphoneModalViewController:currentModalController];
}

- (CGSize)windowSize
{
    UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;
    return mainWindow.bounds.size;
}

- (void)pushController:(UIViewController *)controller {
    
    if (!modalControllers) modalControllers = [NSMutableArray new];
    [modalControllers addObject:controller];
}

- (UIViewController *)popController {
    
    UIViewController *controller = [modalControllers lastObject];
    [modalControllers removeLastObject];
    return controller;
}

@end
