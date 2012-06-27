//
//  TestHelpers.m
//  Goguruz
//
//  Created by Arthur Evstifeev on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TestHelpers.h"
#import "CoreDataHelper.h"

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
