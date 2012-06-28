//
//  TestHelpers.h
//  Goguruz
//
//  Created by Arthur Evstifeev on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <Foundation/Foundation.h>

#import "AFHTTPRequestOperation.h"
#import "JSONKit.h"
#import <OCMock.h>

@interface AsyncTestConditon : NSObject

@property(nonatomic) BOOL trigger;

@end

@interface DataTestCase : SenTestCase {
    NSManagedObjectContext* _context;
    
    id _clientMock;
}

- (void)stubGetPath:(NSString*)path 
          andParams:(NSDictionary*)params
  withHandshakeFile:(NSString*)handshakeFile;

- (void)runAsyncTestUntil:(NSTimeInterval)interval 
                     test:(void (^)())test;
- (void)runAsyncTest:(void (^)(AsyncTestConditon* endCondition))test 
        withInterval:(NSTimeInterval)interval;
- (void)runAsyncTest:(void (^)(AsyncTestConditon* endCondition))test;

@end

@interface TestHelpers : NSObject

+ (NSString*)handshakeFromTXTFileName:(NSString*)fileName;
+ (NSString*)handshakeFromJSONFileName:(NSString*)fileName;
+ (id)JSONhandshakeFromTXTFileName:(NSString*)fileName;
+ (id)JSONhandshakeFromJSONFileName:(NSString*)fileName;
+ (void)makeAsyncLoopWithInterval:(NSTimeInterval)interval;
+ (void)stubEnqueueBatchOfHTTPRequestOperationsforClientMock:(id)clientMock
                                           withHandshakeDict:(NSDictionary*)JSONhandshakeDict;
+ (void)stubGetPath:(NSString*)path 
      forClientMock:(id)clientMock
          andParams:(NSDictionary*)params 
  withHandshakeFile:(NSString*)handshakeFile;

@end
