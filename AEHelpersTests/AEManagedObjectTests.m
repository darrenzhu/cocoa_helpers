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
#import "JSONKit.h"
#import "AEHTTPClient.h"

#import "TestEntity.h"
#import "TestSubentity.h"

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
        NSString *jsonString = @"{\"entity\":[{\"entity_id\": 1,\"testField\": \"test value\"},{\"entity_id\": 2,\"testField\": \"another test value\"}]}";
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

@end
