//
// TestHelpers.h
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

#import <SenTestingKit/SenTestingKit.h>
#import <Foundation/Foundation.h>

#import "AFHTTPRequestOperation.h"
#import "JSONKit.h"
#import <OCMock.h>

@interface AsyncTestConditon : NSObject
@property(nonatomic) BOOL trigger;
@end

@interface DataTestCase : SenTestCase {
    NSManagedObjectContext *_context;
    id _clientMock;
}

- (void)stubGetPath:(NSString *)path
          andParams:(NSDictionary *)params
  withHandshakeFile:(NSString *)handshakeFile;

- (void)runAsyncTestWithBlock:(void (^)(BOOL *endCondition))test
                 withInterval:(NSTimeInterval)interval;
- (void)runAsyncTestUntil:(NSTimeInterval)interval
                     test:(void (^)())test;
- (void)runAsyncTest:(void (^)(AsyncTestConditon *endCondition))test
        withInterval:(NSTimeInterval)interval;
- (void)runAsyncTest:(void (^)(AsyncTestConditon *endCondition))test;
@end

@interface TestHelpers : NSObject
+ (NSString *)handshakeFromTXTFileName:(NSString *)fileName;
+ (NSString *)handshakeFromJSONFileName:(NSString *)fileName;
+ (id)JSONhandshakeFromTXTFileName:(NSString *)fileName;
+ (id)JSONhandshakeFromJSONFileName:(NSString *)fileName;
+ (void)makeAsyncLoopWithInterval:(NSTimeInterval)interval;
+ (void)stubEnqueueBatchOfHTTPRequestOperationsforClientMock:(id)clientMock
                                           withHandshakeDict:(NSDictionary *)JSONhandshakeDict;
+ (void)stubGetPath:(NSString *)path 
      forClientMock:(id)clientMock
          andParams:(NSDictionary *)params 
  withHandshakeFile:(NSString *)handshakeFile;
@end
