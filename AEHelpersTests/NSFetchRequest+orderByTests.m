//
// NSFetchRequest+orderByTests.m
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

#import "NSFetchRequest+orderByTests.h"
#import "JSONKit.h"
#import "TestEntity.h"

@interface NSFetchRequest_orderByTests ()
@property (retain, nonatomic) NSArray *assert;
@end

@implementation NSFetchRequest_orderByTests

- (void)setUp {
    [super setUp];
    
    id jsonObject = [@"{\"entity_id\": 1,\"testField\": \"b\"}" objectFromJSONString];
    TestEntity *first = (TestEntity *)[TestEntity createOrUpdateFromJsonObject:jsonObject
                                                        inManagedObjectContext:mainThreadContext()];
    
    jsonObject = [@"{\"entity_id\": 2,\"testField\": \"c\"}" objectFromJSONString];
    TestEntity *second = (TestEntity *)[TestEntity createOrUpdateFromJsonObject:jsonObject
                                                         inManagedObjectContext:mainThreadContext()];
    
    jsonObject = [@"{\"entity_id\": 3,\"testField\": \"a\"}" objectFromJSONString];
    TestEntity *third = (TestEntity *)[TestEntity createOrUpdateFromJsonObject:jsonObject
                                                        inManagedObjectContext:mainThreadContext()];
    [AECoreDataHelper save:mainThreadContext()];
    
    self.assert = @[third, first, second];
}

- (void)testOrderByStringPredicate {
    NSArray *sorted = [TestEntity requestResult:[[TestEntity all] orderBy:@"testField", nil]
                           managedObjectContext:mainThreadContext()];
    STAssertEqualObjects(_assert, sorted, nil);
}

- (void)testOrderBySortingDescriptor {
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"testField" ascending:YES];
    NSArray *sorted = [TestEntity requestResult:[[TestEntity all] orderByDescriptors:descriptor, nil]
                           managedObjectContext:mainThreadContext()];
    STAssertEqualObjects(_assert, sorted, nil);
}

@end
