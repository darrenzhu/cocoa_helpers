//
// NSArray+orderByTests.m
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

#import "NSArray+orderByTests.h"
#import "NSArray+orderBy.h"

@interface NSArray_orderByTests ()
@property (retain, nonatomic) NSArray *testArray;
@property (retain, nonatomic) NSArray *assertArray;
@end

@implementation NSArray_orderByTests

- (void)setUp {
    [super setUp];
    
    self.testArray = @[@"b", @"c", @"a"];
    self.assertArray = @[@"a", @"b", @"c"];
}

- (void)testOrderByStringPredicate {
    NSArray *sortedArray = [_testArray orderBy:@"self", nil];
    STAssertEqualObjects(_assertArray, sortedArray, nil);
}

- (void)testOrderBySortindDescriptor {
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    NSArray *sortedArray = [_testArray orderByDescriptors:sortDescriptor, nil];
    STAssertEqualObjects(_assertArray, sortedArray, nil);
}

@end
