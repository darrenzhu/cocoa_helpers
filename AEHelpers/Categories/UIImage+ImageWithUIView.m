//
//  UIImage+ImageWithUIView.m
//  HRApply
//
//  Created by Arthur Evstifeev on 21/02/13.
//  Copyright (c) 2013 Findly. All rights reserved.
//

#import "UIImage+ImageWithUIView.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIImage (ImageWithUIView)

+ (UIImage *)imageWithUIView:(UIView *)view {

    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 0.0f);
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
