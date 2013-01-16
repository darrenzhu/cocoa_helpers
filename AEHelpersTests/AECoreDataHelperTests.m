//
//  AEHelpersTests.m
//  AEHelpersTests
//
//  Created by ap4y on 1/16/13.
//
//

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
