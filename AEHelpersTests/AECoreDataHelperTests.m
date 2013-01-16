//
// AECoreDataHelperTests.m
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

#import "AECoreDataHelperTests.h"
#import "AECoreDataHelper.h"
#import "TestEntity.h"

@implementation AECoreDataHelperTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testReturnManagedObjectModel {
    STAssertNotNil([AECoreDataHelper managedObjectModel], nil);
}

- (void)testReturnStoreCoordinator {
    STAssertNotNil([AECoreDataHelper persistentStoreCoordinator], nil);
}

- (void)testReturnNewManagedObjectContext {
    STAssertNotNil([AECoreDataHelper createManagedObjectContext], nil);
}

- (void)testReturnMainThreadManagedObjectContext {
    STAssertEquals(mainThreadContext(), [AECoreDataHelper mainThreadContext], nil);
}

- (void)testSaveContext {
    [self createTestEntity];
    STAssertTrue([AECoreDataHelper save:mainThreadContext()], nil);
}

- (void)testPerformRequest {
    [self createTestEntity];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *description = [NSEntityDescription entityForName:@"TestEntity"
                                                   inManagedObjectContext:mainThreadContext()];
    [request setEntity:description];
    
    NSArray *result = [AECoreDataHelper requestResult:request managedObjectContext:mainThreadContext()];
    STAssertEquals(result.count, 1U, nil);
}

- (void)testRequestFirstEntity {
    TestEntity *first = [self createTestEntity];
    [AECoreDataHelper save:mainThreadContext()];
    
    TestEntity *second = [self createTestEntity];
    second.testField = @"another field";
    [AECoreDataHelper save:mainThreadContext()];

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *description = [NSEntityDescription entityForName:@"TestEntity"
                                                   inManagedObjectContext:mainThreadContext()];
    [request setEntity:description];
    TestEntity *found = [AECoreDataHelper requestFirstResult:request managedObjectContext:mainThreadContext()];
    STAssertEqualObjects(first.testField, found.testField, nil);
}


#pragma mark - private
- (TestEntity *)createTestEntity {
    NSEntityDescription *description = [NSEntityDescription entityForName:@"TestEntity"
                                                   inManagedObjectContext:mainThreadContext()];
    TestEntity *entity = [[TestEntity alloc] initWithEntity:description
                             insertIntoManagedObjectContext:mainThreadContext()];
    entity.testField = @"test data";
    return entity;
}

@end
