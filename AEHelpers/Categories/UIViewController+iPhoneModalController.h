//
//  UIViewController+iPhoneModalController.h
//  HRApply
//
//  Created by Arthur Evstifeev on 21/03/13.
//  Copyright (c) 2013 Findly. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 A `UIViewController` category for presenting `UIActionSheet`-like modal controllers in `iPhone` applications
 */
@interface UIViewController (iPhoneModalController)

/**
 Adds `controller` as a child view controller and presents it with animation in current view controller.
 
 @param controller A controller to present.
 */
- (void)presentInIphoneModalViewController:(UIViewController *)controller;

/**
 Dismisses `controller` from the screen, and removes it from child controllers.
 
 @param controller A controller to dismiss.
 */
- (void)dismissIphoneModalViewController:(UIViewController *)controller;

@end
