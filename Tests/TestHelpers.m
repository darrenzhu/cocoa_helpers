//
// TestHelpers.m
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

#import "TestHelpers.h"
#import "CoreDataHelper.h"

#import "AFJSONRequestOperation.h"
#import "AFHTTPClient.h"
#import <objc/runtime.h>

@implementation AsyncTestConditon
@synthesize trigger;
- (id)init {
    self = [super init];
    if (self) {
        trigger = NO;
    }
    return self;
}
@end

@implementation DataTestCase
- (void)setUp {
    [super setUp];
    
    _context = [[CoreDataHelper createManagedObjectContext] retain];    
    STAssertNotNil(_context, @"Unable to create management context");    
}

- (void)stubGetPath:(NSString *)path 
          andParams:(NSDictionary *)params 
  withHandshakeFile:(NSString *)handshakeFile {
        
    [TestHelpers stubGetPath:path 
               forClientMock:_clientMock 
                   andParams:params 
           withHandshakeFile:handshakeFile];
}

- (void)runAsyncTestUntil:(NSTimeInterval)interval
                     test:(void (^)())test {
    
    test();        
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:interval];
    while ([loopUntil timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }  
}

- (void)runAsyncTest:(void (^)(AsyncTestConditon *endCondition))test
        withInterval:(NSTimeInterval)interval {
    
    AsyncTestConditon *condition = [[AsyncTestConditon alloc] init];
    test(condition);
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:interval];
    while ([loopUntil timeIntervalSinceNow] > 0 && !condition.trigger) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate date]];
    }      
    STAssertTrue(condition.trigger, @"async test failed. trigger value is not YES.");
}

- (void)runAsyncTestWithBlock:(void (^)(BOOL *endCondition))test
                 withInterval:(NSTimeInterval)interval {
    
    BOOL condition;
    test(&condition);    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:interval];
    while ([loopUntil timeIntervalSinceNow] > 0 && !condition) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate date]];
    }    
    STAssertTrue(condition, @"async test failed. trigger value is not YES.");
}


- (void)runAsyncTest:(void (^)(AsyncTestConditon *endCondition))test {
    [self runAsyncTest:test withInterval:3.0];
}

- (void)tearDown {
    [_clientMock verify];
    [_context release];
    [super tearDown];
}

@end

@implementation TestHelpers

+ (NSString *)handshakeFromTXTFileName:(NSString *)fileName {
    NSString *modelPath = [[NSBundle bundleForClass:[self class]] pathForResource:fileName
                                                                           ofType:@"txt"];
    return [NSString stringWithContentsOfFile:modelPath
                                     encoding:NSUTF8StringEncoding
                                        error:nil];
}

+ (NSString *)handshakeFromJSONFileName:(NSString *)fileName {
    NSString *modelPath = [[NSBundle bundleForClass:[self class]] pathForResource:fileName
                                                                           ofType:@"json"];
    return [NSString stringWithContentsOfFile:modelPath
                                     encoding:NSUTF8StringEncoding
                                        error:nil];
}

+ (id)JSONhandshakeFromTXTFileName:(NSString *)fileName {
    return [[self handshakeFromTXTFileName:fileName] objectFromJSONString];
}

+ (id)JSONhandshakeFromJSONFileName:(NSString*)fileName {
    return [[self handshakeFromJSONFileName:fileName] objectFromJSONString];
}

+ (void)makeAsyncLoopWithInterval:(NSTimeInterval)interval {
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:interval];
    while ([loopUntil timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }  
}

+ (void)stubEnqueueBatchOfHTTPRequestOperationsforClientMock:(id)clientMock
                                           withHandshakeDict:(NSDictionary *)JSONhandshakeDict{
    
    __block NSArray *operations;
    __block void (^finishBlock)(NSArray *operations);
    BOOL (^operationsCheckBlock)(id value) = [^BOOL(id value) {
        operations = [value copy]; 
        return YES;
    } copy];
    
    BOOL (^checkBlock)(id value) = [^BOOL(id value) {
        
        for (AFHTTPRequestOperation *operation in operations) {
            NSString *jsonFileName =
                [JSONhandshakeDict objectForKey:operation.request.URL.absoluteString];
            if (jsonFileName) {
                id json = [[TestHelpers JSONhandshakeFromJSONFileName:jsonFileName] retain];
                object_setInstanceVariable(operation, "_responseJSON", json);
                
                void (^completionBlock)() = [operation completionBlock];
                completionBlock();
            }
        }

        finishBlock = [value copy];
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        finishBlock(operations);
        [operations release];
        [finishBlock release];
        [operationsCheckBlock release];
        
        return YES;
    } copy];        
    
    id check = [OCMArg checkWithBlock:operationsCheckBlock];
    [[clientMock stub] enqueueBatchOfHTTPRequestOperations:check
                                             progressBlock:[OCMArg any] 
                                           completionBlock:[OCMArg checkWithBlock:checkBlock]];    
}

+ (void)stubGetPath:(NSString *)path
      forClientMock:(id)clientMock
          andParams:(NSDictionary *)params 
  withHandshakeFile:(NSString *)handshakeFile {
    
    __block void (^success)(AFHTTPRequestOperation *operation, id responseObject);
    BOOL (^checkBlock)(id value) = [^BOOL(id value) {    
        success = [value copy]; 
        return YES;
    } copy];
    
    void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {     
        NSRange dotRange = [handshakeFile rangeOfString:@"."];
        if (dotRange.location != NSNotFound) {
            NSRange nameRange = NSMakeRange(dotRange.location + 1,
                                            handshakeFile.length - dotRange.location - 1);
            NSString *extension = [handshakeFile substringWithRange:nameRange];
            NSString *name =
                [handshakeFile substringWithRange:NSMakeRange(0, dotRange.location)];
            success(nil, [TestHelpers JSONhandshakeFromJSONFileName:name]);
        }
        else {
            success(nil, [TestHelpers JSONhandshakeFromTXTFileName:handshakeFile]);
        }        
    };                
        
    AFHTTPClient *mock = [[clientMock stub] andDo:theBlock];
    [mock getPath:path
       parameters:params
          success:[OCMArg checkWithBlock:checkBlock]
          failure:[OCMArg any]];
}

@end
