//
//  TWClient.h
//  cska
//
//  Created by Arthur Evstifeev on 2/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SNClient.h"

@interface TWClient : SNClient {
    
    NSMutableDictionary *_oAuthValues;

    NSString *_verifier;
}

+ (TWClient*)sharedClient;
+ (NSString*)redirecUrl;

@end