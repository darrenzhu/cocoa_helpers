//
//  UIImage+ImageWithUIView.h
//  HRApply
//
//  Created by Arthur Evstifeev on 21/02/13.
//  Copyright (c) 2013 Findly. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 A `UIImage` category for creating view screenshots
 */
@interface UIImage (ImageWithUIView)

/**
 Creates new `UIImage` instance by drawing `view` layer in new context.
 
 @param view A view to make screenshot from.
 
 @return View screenshot image
 */
+ (UIImage *)imageWithUIView:(UIView *)view;

@end
