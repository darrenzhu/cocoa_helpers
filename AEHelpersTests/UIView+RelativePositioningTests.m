//
// UIView+RelativePositioningTests.m
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

#import "UIView+RelativePositioningTests.h"
#import "UIView+RelativePositioning.h"

@interface UIView_RelativePositioningTests ()
@property (strong, nonatomic) UIView *subject;
@end

@implementation UIView_RelativePositioningTests

- (void)setUp {
    [super setUp];
    
    self.subject = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 300.0f)];
}

- (void)testShouldSetFrameFromSettingNonZeroCoordinates {
    
    [_subject setFrameBySettingNonZeroCoordinates:CGRectMake(-10.0f, 10.0f, 0.0f, 0.0f)];
    STAssertEquals(CGRectMake(-10.0f, 10.0f, 300.0f, 300.0f), _subject.frame, nil);
}

- (void)testShouldSetFrameByAddingCoordinates {
    
    [_subject setFrameByAddingCoordinates:CGRectMake(-10.0f, 10.0f, -10.0f, 10.0f)];
    STAssertEquals(CGRectMake(-10.0f, 10.0f, 290.0f, 310.0f), _subject.frame, nil);
}

- (void)testShouldSetCenterByAddingCoordinates {
    
    [_subject setCenterByAddingCoordinates:CGPointMake(-10.0f, 10.0f)];
    STAssertEquals(CGPointMake(140.0f, 160.0f), _subject.center, nil);
}

- (void)testShouldReturnRelativeHeight {
    
    _subject.frame = CGRectMake(0.0f, 50.0f, 300.0f, 300.0f);
    STAssertEquals(350.0f, [_subject relativeHeight], nil);
}

- (void)testShouldInsertSubviewWithPositionBelowView {
    
    UIView *aboveView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 100.0f)];
    UIView *belowView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 100.0f)];
    [_subject addSubview:aboveView];
    [_subject insertSubview:belowView positionedBelow:aboveView];
    
    STAssertEqualObjects(_subject, belowView.superview, nil);
    STAssertEquals(CGRectMake(0.0f, 100.0f, 300.0f, 100.0f), belowView.frame, nil);
}

@end
