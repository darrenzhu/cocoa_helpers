//
//  TestHelpers.m
//  Goguruz
//
//  Created by Arthur Evstifeev on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TestHelpers.h"
#import "CoreDataHelper.h"

#import "AFJSONRequestOperation.h"
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

- (void)stubGetPath:(NSString*)path 
          andParams:(NSDictionary*)params 
  withHandshakeFile:(NSString*)handshakeFile {
        
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

- (void)runAsyncTest:(void (^)(AsyncTestConditon* endCondition))test
        withInterval:(NSTimeInterval)interval {
    
    AsyncTestConditon* condition = [[AsyncTestConditon alloc] init];
    test(condition);    
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:interval];
    while ([loopUntil timeIntervalSinceNow] > 0 && !condition.trigger) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }  
    
    STAssertTrue(condition.trigger, @"async test failed. trigger value is not YES.");
}

- (void)runAsyncTest:(void (^)(AsyncTestConditon* endCondition))test {
    [self runAsyncTest:test withInterval:3.0];
}

- (void)tearDown {
    [_clientMock verify];
    [_context release];
    [super tearDown];
}

@end

@implementation TestHelpers

+ (NSString*)handshakeFromTXTFileName:(NSString*)fileName {
    NSString *modelPath = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"txt"];
    return [NSString stringWithContentsOfFile:modelPath encoding:NSUTF8StringEncoding error:nil];
}

+ (NSString*)handshakeFromJSONFileName:(NSString*)fileName {
    NSString *modelPath = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"json"];
    return [NSString stringWithContentsOfFile:modelPath encoding:NSUTF8StringEncoding error:nil];
}

+ (id)JSONhandshakeFromTXTFileName:(NSString*)fileName {
    NSString *modelPath = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"txt"];
    return [[NSString stringWithContentsOfFile:modelPath encoding:NSUTF8StringEncoding error:nil] objectFromJSONString];
}

+ (id)JSONhandshakeFromJSONFileName:(NSString*)fileName {
    NSString *modelPath = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"json"];
    return [[NSString stringWithContentsOfFile:modelPath encoding:NSUTF8StringEncoding error:nil] objectFromJSONString];
}

+ (void)makeAsyncLoopWithInterval:(NSTimeInterval)interval {
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:interval];
    while ([loopUntil timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }  
}

+ (void)stubEnqueueBatchOfHTTPRequestOperationsforClientMock:(id)clientMock
                                           withHandshakeDict:(NSDictionary*)JSONhandshakeDict {
    
    __block NSArray* operations;
    __block void (^finishBlock)(NSArray* operations);
    BOOL (^operationsCheckBlock)(id value) = [^BOOL(id value) {
        operations = [value copy]; 
        return YES;
    } copy];
    
    BOOL (^checkBlock)(id value) = [^BOOL(id value) {
        
        for (AFHTTPRequestOperation* operation in operations) {
            NSString* jsonFileName = [JSONhandshakeDict objectForKey:operation.request.URL.absoluteString];
            if (jsonFileName) {
                id json = [[TestHelpers JSONhandshakeFromJSONFileName:jsonFileName] retain];
                object_setInstanceVariable(operation, "_responseJSON", json);
                
                void (^completionBlock)() = [operation completionBlock];
                completionBlock();
            }
        }

        finishBlock = [value copy];
        
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_current_queue(), ^(void){
            finishBlock(operations);
            [operations release];
            [finishBlock release];
            [operationsCheckBlock release];
        });
        
        return YES;
    } copy];        
    
    [[clientMock stub] enqueueBatchOfHTTPRequestOperations:[OCMArg checkWithBlock:operationsCheckBlock] 
                                             progressBlock:[OCMArg any] 
                                           completionBlock:[OCMArg checkWithBlock:checkBlock]];    
}

+ (void)stubGetPath:(NSString*)path 
      forClientMock:(id)clientMock
          andParams:(NSDictionary*)params 
  withHandshakeFile:(NSString*)handshakeFile {
    
    __block void (^success)(AFHTTPRequestOperation *operation, id responseObject);
    BOOL (^checkBlock)(id value) = [^BOOL(id value) {    
        success = [value copy]; 
        return YES;
    } copy];
    
    void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {     
        NSRange dotRange = [handshakeFile rangeOfString:@"."];
        if (dotRange.location != NSNotFound) {
            NSString* extension = [handshakeFile substringWithRange:NSMakeRange(dotRange.location + 1, 
                                                                                handshakeFile.length - dotRange.location - 1)];
            NSString* name = [handshakeFile substringWithRange:NSMakeRange(0, dotRange.location)];
            if (extension == @"json") {
                success(nil, [TestHelpers JSONhandshakeFromJSONFileName:name]);
            }
            else {
                success(nil, [TestHelpers JSONhandshakeFromJSONFileName:name]);
            }
        }
        else {
            success(nil, [TestHelpers JSONhandshakeFromTXTFileName:handshakeFile]);
        }        
    };                
        
    [[[clientMock stub] andDo:theBlock] getPath:path 
                                     parameters:params
                                        success:[OCMArg checkWithBlock:checkBlock] 
                                        failure:[OCMArg any]];
}

@end
