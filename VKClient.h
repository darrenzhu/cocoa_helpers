//
//  VKClient.h
//  cska
//
//  Created by Arthur Evstifeev on 2/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SNClient.h"

@interface VKClient : SNClient {
    
}

+ (VKClient*)sharedClient;
+ (NSString*)redirecUrl;

@end
