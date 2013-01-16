//
//  NSFetchRequest+orderByTests.m
//  AEHelpers
//
//  Created by ap4y on 1/17/13.
//
//

#import "NSFetchRequest+orderByTests.h"
#import "JSONKit.h"
#import "TestEntity.h"

@interface NSFetchRequest_orderByTests ()
@property (retain, nonatomic) NSArray *assert;
@end

@implementation NSFetchRequest_orderByTests

- (void)setUp {
    [super setUp];
    
    id jsonObject = [@"{\"id\": 1,\"testField\": \"b\"}" objectFromJSONString];
    TestEntity *first = (TestEntity *)[TestEntity createOrUpdateFromJsonObject:jsonObject
                                                        inManagedObjectContext:mainThreadContext()];
    
    jsonObject = [@"{\"id\": 2,\"testField\": \"c\"}" objectFromJSONString];
    TestEntity *second = (TestEntity *)[TestEntity createOrUpdateFromJsonObject:jsonObject
                                                         inManagedObjectContext:mainThreadContext()];
    
    jsonObject = [@"{\"id\": 3,\"testField\": \"a\"}" objectFromJSONString];
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
