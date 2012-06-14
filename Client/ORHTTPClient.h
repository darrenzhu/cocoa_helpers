//
//  CSKAClient.h
//  cska
//
//  Created by Arthur Evstifeev on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AFHTTPClient.h"

@interface ORHTTPClient : AFHTTPClient

- (id)getPathSync:(NSString*)path;

@end
