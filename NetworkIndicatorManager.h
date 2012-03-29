//
//  NetworkIndicatorManager.h
//  cska
//
//  Created by Arthur Evstifeev on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkIndicatorManager : NSObject {
    int networkStateCounter;
}

+ (NetworkIndicatorManager*)defaultManager;
- (void)setNetworkIndicatorState:(BOOL)state;

@end
