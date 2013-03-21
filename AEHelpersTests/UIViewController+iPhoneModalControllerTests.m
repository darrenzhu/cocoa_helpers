//
//  UIViewController+iPhoneModalControllerTests.m
//  AEHelpers
//
//  Created by Arthur Evstifeev on 22/03/13.
//
//

#import <UIKit/UIKit.h>
#import "UIViewController+iPhoneModalControllerTests.h"
#import "UIViewController+iPhoneModalController.h"

@interface UIViewController_iPhoneModalControllerTests ()
@property (strong, nonatomic) UIViewController *parent;
@property (strong, nonatomic) UIViewController *subject;
@end

@implementation UIViewController_iPhoneModalControllerTests

- (void)setUp {
    [super setUp];
    
    self.parent = [[UIViewController alloc] init];
    [_parent.view setFrame:CGRectMake(0.0f, 0.0f, 320.0f, 480.0f)];
    self.subject= [[UIViewController alloc] init];
    [_subject.view setFrame:CGRectMake(0.0f, 0.0f, 320.0f, 100.0f)];
}

- (void)testShouldPresentIphoneModalViewController {

    [_parent presentInIphoneModalViewController:_subject];
    
    STAssertEqualObjects(_parent, [_subject parentViewController], nil);
    STAssertEqualObjects(_parent.view, [_subject.view superview], nil);
    STAssertEquals(CGRectMake(0.0f, 380.0f, 320.0f, 100.0f), _subject.view.frame, nil);
}

- (void)testShouldDismissIphoneModalViewController {
    
    [_parent dismissIphoneModalViewController:_subject];
    
    STAssertEquals(CGRectMake(0.0f, 480.0f, 320.0f, 100.0f), _subject.view.frame, nil);
}

@end
