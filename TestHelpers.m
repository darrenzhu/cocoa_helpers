//
//  TestHelpers.m
//  Goguruz
//
//  Created by Arthur Evstifeev on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TestHelpers.h"
#import "CoreDataHelper.h"

@implementation DataTestCase

- (void)setUp {
    [super setUp];
    
    _context = [[CoreDataHelper managedObjectContext] retain];    
    STAssertNotNil(_context, @"Unable to create management context");    
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

+ (id)JSONhandshakeFromTXTFileName:(NSString*)fileName {
    NSString *modelPath = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"txt"];
    return [[NSString stringWithContentsOfFile:modelPath encoding:NSUTF8StringEncoding error:nil] objectFromJSONString];
}

+ (void)makeAsyncLoopWithInterval:(NSTimeInterval)interval {
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:interval];
    while ([loopUntil timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }  
}

@end
