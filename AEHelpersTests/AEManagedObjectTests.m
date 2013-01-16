//
//  AEManagedObjectTests.m
//  AEHelpers
//
//  Created by ap4y on 1/16/13.
//
//

#import "AEManagedObjectTests.h"
#import "OHHTTPStubs.h"
#import "TestEntity.h"
#import "JSONKit.h"
#import "AEHTTPClient.h"

@interface AEManagedObjectTests ()
@property(retain, nonatomic) id jsonObject;
@end

@implementation AEManagedObjectTests

- (void)setUp {
    [super setUp];
    
    NSString *jsonString = @"{\"id\": 1,\"testField\": \"test value\"}";
    self.jsonObject = [jsonString objectFromJSONString];
}

- (void)tearDown {
    NSArray *entities = [TestEntity requestResult:[TestEntity all] managedObjectContext:mainThreadContext()];
    for (id entity in entities) {
        [mainThreadContext() deleteObject:entity];
    }
    [AECoreDataHelper save:mainThreadContext()];
    
    [super tearDown];
}

- (void)testInitFromJsonObject {
    TestEntity *entity = [[TestEntity alloc] initFromJSONObject:_jsonObject
                                         inManagedObjectContext:mainThreadContext()];
    STAssertEqualObjects(@"test value", entity.testField, nil);
}

- (void)testCreateFromJsonObject {
    TestEntity *entity = (TestEntity *)[TestEntity createOrUpdateFromJsonObject:_jsonObject
                                                         inManagedObjectContext:mainThreadContext()];
    STAssertEqualObjects(@"test value", entity.testField, nil);
}

- (void)testCreateOrUpdateFromJsonObject {
    TestEntity *first = (TestEntity *)[TestEntity createOrUpdateFromJsonObject:_jsonObject
                                                        inManagedObjectContext:mainThreadContext()];
    [AECoreDataHelper save:mainThreadContext()];

    TestEntity *second = (TestEntity *)[TestEntity createOrUpdateFromJsonObject:_jsonObject
                                                         inManagedObjectContext:mainThreadContext()];
    [AECoreDataHelper save:mainThreadContext()];

    STAssertEqualObjects([first objectID], [second objectID], nil);
}

- (void)testUpdateFromJson {
    TestEntity *entity = (TestEntity *)[TestEntity createOrUpdateFromJsonObject:_jsonObject
                                                         inManagedObjectContext:mainThreadContext()];

    NSString *jsonString = @"{\"id\": 1,\"testField\": \"another test value\"}";
    id jsonObject = [jsonString objectFromJSONString];
    [entity updateFromJSONObject:jsonObject];
    
    STAssertEqualObjects(@"another test value", entity.testField, nil);
}

- (void)testToJSONString {
    TestEntity *entity = (TestEntity *)[TestEntity createOrUpdateFromJsonObject:_jsonObject
                                                         inManagedObjectContext:mainThreadContext()];
    STAssertEqualObjects(@"{\"id\":1,\"testField\":\"test value\"}", [entity toJSONString], nil);
}

- (void)testRequestAll {
    [[TestEntity alloc] initFromJSONObject:_jsonObject inManagedObjectContext:mainThreadContext()];
    [[TestEntity alloc] initFromJSONObject:_jsonObject inManagedObjectContext:mainThreadContext()];
    [AECoreDataHelper save:mainThreadContext()];
    
    NSArray *entities = [TestEntity requestResult:[TestEntity all]
                             managedObjectContext:mainThreadContext()];
    STAssertEquals(2U, entities.count, nil);
}

- (void)testFindEntity {
    [[TestEntity alloc] initFromJSONObject:_jsonObject inManagedObjectContext:mainThreadContext()];
    
    NSFetchRequest *request = [TestEntity find:@(1)];
    TestEntity *entity = [TestEntity requestFirstResult:request
                                   managedObjectContext:mainThreadContext()];
    STAssertEquals(@(1), entity.id, nil);
}

- (void)testRequestWithPredicate {
    TestEntity *entity = [[TestEntity alloc] initFromJSONObject:_jsonObject
                                         inManagedObjectContext:mainThreadContext()];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"testField == \"test value\""];
    NSFetchRequest *request = [TestEntity where:predicate];
    TestEntity *found = [TestEntity requestFirstResult:request
                                  managedObjectContext:mainThreadContext()];
    STAssertEquals([entity objectID], [found objectID], nil);
}

- (void)testFetchWithClient {
    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse *(NSURLRequest *request, BOOL onlyCheck) {
        return [OHHTTPStubsResponse responseWithFile:@"mocked_respond.json"
                                         contentType:@"application/json"
                                        responseTime:0.1];
    }];
    
    __block BOOL finished = NO;
    [TestEntity fetchWithClient:[AEHTTPClient sharedClient] path:@"/tests" parameters:nil jsonResponse:^(id json) {
        NSString *jsonString =
            @"[{\"id\": 1,\"testField\": \"test value\"},{\"id\": 2,\"testField\": \"another test value\"}]";
        STAssertEqualObjects([jsonString objectFromJSONString], json, nil);
    } success:^(NSArray *entities) {
        STAssertEquals(2U, entities.count, nil);
        finished = YES;
    } failure:^(NSError *error) {
        STFail(nil);
    }];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:2];
    while (!finished && [loopUntil timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    STAssertTrue(finished, nil);
}

@end
