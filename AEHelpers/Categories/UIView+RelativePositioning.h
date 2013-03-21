//
//  UIView+RelativePositioning.h
//  HRApply
//
//  Created by Arthur Evstifeev on 28/02/13.
//  Copyright (c) 2013 Findly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (RelativePositioning)

/**
 Sets view frame by extracting all non-zero values for `rect` parameter and setting them to the corresponding frame values.
 
 @param rect A rect to be used during view frame recalculation.
 */
- (void)setFrameBySettingNonZeroCoordinates:(CGRect)rect;

/**
 Sets view frame by extracting all non-zero values for `rect` parameter and adding them to the corresponding frame values.
 
 @param rect A rect to be used during view frame recalculation. 
 */
- (void)setFrameByAddingCoordinates:(CGRect)rect;

/**
 Sets view center by extracting all non-zero values for `point` parameter and adding them to the corresponding center values.

 @param point A point to be used during view center recalculation. 
 */
- (void)setCenterByAddingCoordinates:(CGPoint)point;

/**
 Returns sum of the `origin.y` and `size.height`.
 
 @return Height relativly to the parent view.
 */
- (CGFloat)relativeHeight;

/**
 Inserts `view` and assigns coordinates, so it will be positioned under the `aboveView`.
 
 @param view A view to insert.
 @param aboveView A view used during postion recalculation.
 */
- (void)insertSubview:(UIView *)view positionedBelow:(UIView *)aboveView;

@end
