//
// AEManagedObjectTests.m
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

#import "AEManagedObjectTests.h"
#import "OHHTTPStubs.h"
#import "NSJSONSerializationCategories.h"
#import "AEHTTPClient.h"
#import "OCMock.h"

#import "AEManagedObject+AEJSONSerialization.h"
#import "AEManagedObject+AERemoteFetch.h"
#import "AEManagedObjectsCache.h"

#import "TestEntity.h"
#import "TestSubentity.h"
#import "TestChildEntity.h"

#define loopWithRunLoop(interval) \
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:2]; \
    while (!finished && [loopUntil timeIntervalSinceNow] > 0) { \
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode \
                                 beforeDate:loopUntil]; \
    }

@interface AEManagedObjectTests ()
@property(retain, nonatomic) id jsonObject;
@end

@implementation AEManagedObjectTests

- (void)setUp {
    [super setUp];
    
    NSString *jsonString = @"{\"entity_id\": 1,\"testField\": \"test value\"}";
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
    STAssertEqualObjects(@"{\"entity\":{\"entity_id\":1,\"testField\":\"test value\"}}",
                         [[entity toJSONObject] JSONString], nil);
}

- (void)testRequestAll {
    [[TestEntity alloc] initFromJSONObject:_jsonObject inManagedObjectContext:mainThreadContext()];
    [[TestEntity alloc] initFromJSONObject:_jsonObject inManagedObjectContext:mainThreadContext()];
    
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
        return [OHHTTPStubsResponse responseWithFile:@"mocked_response.json"
                                         contentType:@"application/json"
                                        responseTime:0.1];
    }];
    
    __block BOOL finished = NO;
    [TestEntity fetchWithClient:[AEHTTPClient sharedClient] path:@"/tests" parameters:nil jsonResponse:^(id json) {
        NSString *jsonString = @"{\"entity\":[{\"entity_id\": 1,\"testField\": \"test value\"},{\"entity_id\": 2,\"testField\": \"another test value\"}]}";
        STAssertEqualObjects([jsonString objectFromJSONString], json, nil);
    } success:^(NSArray *entities) {
        STAssertEquals(2U, entities.count, nil);
        finished = YES;
    } failure:^(NSError *error) {
        STFail(nil);
    }];        
    
    loopWithRunLoop(2);
    STAssertTrue(finished, nil);
}

- (void)testParsePosixDate {
    NSDate *date = [[TestEntity dateFormatter] dateFromString:@"2013-01-04T01:22:40Z"];
    STAssertEqualObjects(@"2013-01-04T01:22:40Z", [[TestEntity dateFormatter] stringFromDate:date], nil);
}

- (void)testRespectMappingsDictionary {
    NSString *jsonString = @"{\"entity_id\":2,\"testField\":\"test value\",\"another_field\":\"test value\"}";
    id jsonObject = [jsonString objectFromJSONString];
    TestEntity *entity = [[TestEntity alloc] initFromJSONObject:jsonObject
                                         inManagedObjectContext:mainThreadContext()];
    STAssertEqualObjects(@"test value", entity.anotherField, nil);
    STAssertEqualObjects(@"test value", entity.testField, nil);
    STAssertEqualObjects(@(2), entity.id, nil);
    NSString *rootedJsonObject = [NSString stringWithFormat:@"{\"entity\":%@}", jsonString];
    STAssertEqualObjects(rootedJsonObject, [[entity toJSONObject] JSONString], nil);
}

- (void)testSerializeAssociations {
    TestEntity *entity          = [[TestEntity alloc] initFromJSONObject:_jsonObject
                                                  inManagedObjectContext:mainThreadContext()];
    TestSubentity *oneToOne     = [NSEntityDescription insertNewObjectForEntityForName:@"TestSubentity"
                                                                inManagedObjectContext:mainThreadContext()];
    TestSubentity *oneToMany    = [NSEntityDescription insertNewObjectForEntityForName:@"TestSubentity"
                                                                inManagedObjectContext:mainThreadContext()];
    oneToOne.id                 = @1;
    oneToOne.title              = @"Title 1";
    entity.oneToOne             = oneToOne;
    
    oneToMany.id                = @2;
    oneToMany.title             = @"Title 2";
    [entity addOneToManyObject:oneToMany];

    [mainThreadContext() save:nil];
    
    NSDictionary *expected = @{
        @"entity": @{
            @"entity_id": @1,
            @"testField": @"test value",
            @"oneToOne": @{
                @"id":  @1,
                @"title": @"Title 1"
            },
            @"oneToMany": @[
                @{
                    @"id":  @2,
                    @"title": @"Title 2"
                }
            ]
        }
    };
    
    NSDictionary *serialized = [entity toJSONObject];
    STAssertEqualObjects(expected, serialized, nil);
    
    TestEntity *deserialized = [[TestEntity alloc] initFromJSONObject:[serialized objectForKey:@"entity"]
                                               inManagedObjectContext:mainThreadContext()];

    STAssertEqualObjects(@(1),          deserialized.id,                nil);
    STAssertEqualObjects(@"test value", deserialized.testField,         nil);
    STAssertEqualObjects(@(1),          deserialized.oneToOne.id,       nil);
    STAssertEqualObjects(@"Title 1",    deserialized.oneToOne.title,    nil);
    STAssertEquals(1U,                  [deserialized.oneToMany count], nil);
    
    TestSubentity *oneToManyDeserialized = [[deserialized.oneToMany allObjects] lastObject];
    STAssertEqualObjects(@(2),          oneToManyDeserialized.id,       nil);
    STAssertEqualObjects(@"Title 2",    oneToManyDeserialized.title,    nil);
}

- (void)testSubmitNewObject {
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        
        NSString *jsonString = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
        
        STAssertEqualObjects(@"{\"entity\":{\"entity_id\":0,\"testField\":\"test Field\"}}", jsonString, nil);
        STAssertEqualObjects(@"http://api.test.com/tests", [request.URL absoluteString], nil);
        return YES;
        
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        
        return [OHHTTPStubsResponse responseWithFile:@"submit_mocked_response.json"
                                         contentType:@"application/json"
                                        responseTime:0.1];
    }];

    __block BOOL finished = NO;
    TestEntity *entity  = (TestEntity *)[NSEntityDescription insertNewObjectForEntityForName:@"TestEntity"
                                                                      inManagedObjectContext:mainThreadContext()];
    entity.testField    = @"test Field";
    
    [TestEntity submitRecord:entity
                  withClient:[AEHTTPClient sharedClient]
                        path:@"/tests"
                     success:^(id entity) {
                         
                         STAssertNotNil(entity, nil);
                         
                         TestEntity *testEntity = (TestEntity *)entity;
                         STAssertEqualObjects(@(1), testEntity.id, nil);
                         STAssertEqualObjects(@"test value", testEntity.testField, nil);
                         
                         finished = YES;
                     } failure:^(NSError *error) {
                         STFail(nil);
                     }];
    
    loopWithRunLoop(2);
    STAssertTrue(finished, nil);
}

- (void)testSubmitUpdatedObject {
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        
        NSString *jsonString = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
        
        STAssertEqualObjects(@"{\"entity\":{\"entity_id\":1,\"testField\":\"test Field\"}}", jsonString, nil);
        STAssertEqualObjects(@"http://api.test.com/tests/1", [request.URL absoluteString], nil);
        return YES;
        
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        
        return [OHHTTPStubsResponse responseWithFile:@"submit_mocked_response.json"
                                         contentType:@"application/json"
                                        responseTime:0.1];
    }];
    
    __block BOOL finished = NO;
    TestEntity *entity  = (TestEntity *)[NSEntityDescription insertNewObjectForEntityForName:@"TestEntity"
                                                                      inManagedObjectContext:mainThreadContext()];
    entity.testField    = @"test Field";
    entity.id           = @(1);
    
    [TestEntity submitRecord:entity
                  withClient:[AEHTTPClient sharedClient]
                        path:@"/tests"
                     success:^(id entity) {
                         
                         STAssertNotNil(entity, nil);
                         
                         TestEntity *testEntity = (TestEntity *)entity;
                         STAssertEqualObjects(@(1), testEntity.id, nil);
                         STAssertEqualObjects(@"test value", testEntity.testField, nil);
                         
                         finished = YES;
                     } failure:^(NSError *error) {
                         STFail(nil);
                     }];
        
    loopWithRunLoop(2);
    STAssertTrue(finished, nil);
}

- (void)testUpdateFromJSONObjectWithParentEntity {
    
    NSDictionary *jsonObject = @{
        @"entity_id": @1,
        @"testField": @"test value",
        @"childField": @"child value"
    };
    
    TestChildEntity *childEntity = [NSEntityDescription insertNewObjectForEntityForName:@"TestChildEntity"
                                                                 inManagedObjectContext:mainThreadContext()];
    [childEntity updateFromJSONObject:jsonObject];
    
    STAssertEqualObjects(@(1),              childEntity.id,         nil);
    STAssertEqualObjects(@"test value",     childEntity.testField,  nil);
    STAssertEqualObjects(@"child value",    childEntity.childField, nil);
}

- (void)testCacheRequestedManagedObjects {
    
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;        
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        
        NSDictionary *headers = @{
            @"Content-Type": @"application/json",
            @"Etag": @"1234"
        };
        return [OHHTTPStubsResponse responseWithFile:@"mocked_response.json"
                                   statusCode:200
                                 responseTime:0.0
                                      headers:headers];
    }];
    
    id partialCacheMock = [OCMockObject partialMockForObject:[AEManagedObjectsCache sharedCache]];
    [[partialCacheMock expect] setObjectIds:OCMOCK_ANY forEtag:@"1234"];
    
    __block BOOL finished = NO;
    [TestEntity fetchWithClient:[AEHTTPClient sharedClient]
                           path:@"/test"
                     parameters:nil
                        success:^(NSArray *entities) {
                                                      
                            finished = YES;
                            
                        } failure:^(NSError *error) {
                            STFail(nil);
                        }];
    
    loopWithRunLoop(0.1);
    STAssertTrue(finished, nil);
    [partialCacheMock verify];
}

- (void)testReturnCachedRecords {
    
    /**
     Stubbing response
     */
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        
        NSDictionary *headers = @{
            @"Content-Type": @"application/json",
            @"Etag": @"1234"
        };
        return [OHHTTPStubsResponse responseWithFile:@"mocked_response.json"
                                          statusCode:200
                                        responseTime:0.0
                                             headers:headers];
    }];
    
    /**
     Stubbing cached response
     */
    NSURLRequest *stubRequest;
    NSHTTPURLResponse *stubResponse;
    NSCachedURLResponse *stubCachedResponse;
    NSDictionary *headers;
    
    stubRequest         = [[AEHTTPClient sharedClient] requestWithMethod:@"GET"
                                                                    path:@"/test"
                                                              parameters:nil];
    headers             = @{
        @"Content-Type": @"application/json",
        @"Etag": @"1234"
    };
    stubResponse        = [[NSHTTPURLResponse alloc] initWithURL:[stubRequest URL]
                                               statusCode:200
                                              HTTPVersion:@"1.0"
                                             headerFields:headers];
    stubCachedResponse  = [[NSCachedURLResponse alloc] initWithResponse:stubResponse data:nil];
    [[NSURLCache sharedURLCache] storeCachedResponse:stubCachedResponse forRequest:stubRequest];
    
    /**
     Preparing expectation
     */
    id partialCacheMock = [OCMockObject partialMockForObject:[AEManagedObjectsCache sharedCache]];
    BOOL positiveResult = YES;
    [[[partialCacheMock expect] andReturnValue:OCMOCK_VALUE(positiveResult)] containsObjectIdsForEtag:@"1234"];
    [[partialCacheMock expect] objectIdsForEtag:@"1234"];
    
    /**
     Test fetch
     */
    __block BOOL finished = NO;
    [TestEntity fetchWithClient:[AEHTTPClient sharedClient]
                           path:@"/test"
                     parameters:nil
                        success:^(NSArray *entities) {
                            
                            finished = YES;
                            
                        } failure:^(NSError *error) {
                            STFail(nil);
                        }];
    
    loopWithRunLoop(0.1);
    STAssertTrue(finished, nil);
    [partialCacheMock verify];
}

@end
