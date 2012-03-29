//
//  TestHelpers.h
//  Goguruz
//
//  Created by Arthur Evstifeev on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <Foundation/Foundation.h>

#import "JSONKit.h"
#import <OCMock.h>

@interface DataTestCase : SenTestCase {
    NSManagedObjectContext* _context;
    
    id _clientMock;
}

@end

@interface TestHelpers : NSObject

+ (NSString*)handshakeFromTXTFileName:(NSString*)fileName;
+ (id)JSONhandshakeFromTXTFileName:(NSString*)fileName;
+ (void)makeAsyncLoopWithInterval:(NSTimeInterval)interval;

@end
