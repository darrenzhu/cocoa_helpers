//
// UIViewController+iPhoneModalController.h
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
 Adds `controller` as a child view controller and presents it with animation in current view controller.
 
 @param controller A controller to present.
 @param completion A block that will be invoked upon completion.
 */
- (void)presentInIphoneModalViewController:(UIViewController *)controller completion:(void (^)())completion;
    
/**
 Dismisses `controller` from the screen, and removes it from child controllers.
 
 @param controller A controller to dismiss.
 */
- (void)dismissIphoneModalViewController:(UIViewController *)controller;

/**
 Dismisses `controller` from the screen, and removes it from child controllers.
 
 @param controller A controller to dismiss.
 @param completion A block that will be invoked upon completion.
 */
- (void)dismissIphoneModalViewController:(UIViewController *)controller completion:(void (^)())completion;

@end
