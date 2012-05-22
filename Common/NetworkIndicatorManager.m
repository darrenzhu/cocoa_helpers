//
//  NetworkIndicatorManager.m
//  cska
//
//  Created by Arthur Evstifeev on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NetworkIndicatorManager.h"

@implementation NetworkIndicatorManager

+ (NetworkIndicatorManager*)defaultManager {
    static NetworkIndicatorManager* defaultManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultManager = [[NetworkIndicatorManager alloc] init];
    });
    
    return defaultManager;    
}

- (id)init {
    self = [super init];
    if (self) {
        networkStateCounter = 0;
    }
    return self;
}

- (void)setNetworkIndicatorState:(BOOL)state {
    
    state ? networkStateCounter++ : networkStateCounter--;    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = (networkStateCounter > 0);        
}

@end
