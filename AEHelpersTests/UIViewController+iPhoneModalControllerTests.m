//
// UIViewController+iPhoneModalControllerTests.m
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
