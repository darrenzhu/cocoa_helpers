//
//  UIView+RelativePositioningTests.m
//  HRApply
//
//  Created by Arthur Evstifeev on 28/02/13.
//  Copyright (c) 2013 Findly. All rights reserved.
//

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
