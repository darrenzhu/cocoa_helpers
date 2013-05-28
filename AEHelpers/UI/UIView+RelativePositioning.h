//
// UIView+RelativePositioning.h
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
