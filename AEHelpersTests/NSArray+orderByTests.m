//
//  NSArray+orderByTests.m
//  AEHelpers
//
//  Created by ap4y on 1/17/13.
//
//

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
