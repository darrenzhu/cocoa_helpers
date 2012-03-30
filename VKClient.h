//
//  VKClient.h
//  cska
//
//  Created by Arthur Evstifeev on 2/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SNClient.h"

@interface VKClient : SNClient {
    NSString* _clientId;
    NSString* _redirectString;
}

- (id)initWithId:(NSString*)consumerKey            
     andRedirect:(NSString*)redirectString;

@end
