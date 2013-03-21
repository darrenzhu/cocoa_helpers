//
//  UIView+Highlightning.h
//  HRApply
//
//  Created by Arthur Evstifeev on 28/02/13.
//  Copyright (c) 2013 Findly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Highlighting)

/**
 Iterates through all subviews(except `UIButton` instances) and sets `isHighlighted` property.
 
 @param highlighted A value to assign to the subviews.
 */
- (void)setSubviewsHighlighted:(BOOL)highlighted;

@end
