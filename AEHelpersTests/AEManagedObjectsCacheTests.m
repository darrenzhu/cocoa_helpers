//
// AEManagedObjectsCacheTests.m
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

#import "AEManagedObjectsCacheTests.h"
#import "AEManagedObjectsCache.h"

#import "TestEntity.h"

@interface AEManagedObjectsCacheTests ()
@property (strong, nonatomic) AEManagedObjectsCache *subject;
@property (strong, nonatomic) TestEntity *entity;
@end

@implementation AEManagedObjectsCacheTests

static NSString * const kTestEtag = @"12345";

- (void)setUp {
    [super setUp];
    
    self.subject    = [[AEManagedObjectsCache alloc] init];
    self.entity     = [NSEntityDescription insertNewObjectForEntityForName:@"TestEntity"
                                                    inManagedObjectContext:mainThreadContext()];
    [AECoreDataHelper save:mainThreadContext()];
    
    [_subject setObjectIds:@[ [_entity objectID] ] forEtag:kTestEtag];
}

- (void)tearDown {
    [mainThreadContext() deleteObject:_entity];
    [AECoreDataHelper save:mainThreadContext()];
    
    [super tearDown];
}

- (void)testContainsObjectIdsForEtag {
    
    STAssertTrue([_subject containsObjectIdsForEtag:kTestEtag], nil);
}

- (void)testObjectIdsForEtag {

    STAssertEqualObjects([_entity objectID], [[_subject objectIdsForEtag:kTestEtag] lastObject], nil);
}

- (void)testRemoveObjectIdsForEtag {
 
    [_subject removeObjectIdsForEtag:kTestEtag];
    STAssertFalse([_subject containsObjectIdsForEtag:kTestEtag], nil);
}

@end
