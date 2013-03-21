//
//  UIView+Highlightning.m
//  HRApply
//
//  Created by Arthur Evstifeev on 28/02/13.
//  Copyright (c) 2013 Findly. All rights reserved.
//

#import "UIView+Highlighting.h"

@implementation UIView (Highlighting)

- (void)setSubviewsHighlighted:(BOOL)highlighted {
    
    [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ( ![obj isKindOfClass:[UIButton class]] && [obj respondsToSelector:@selector(setHighlighted:)] ) {
         
            [obj setHighlighted:highlighted];
        }
    }];
}

@end
