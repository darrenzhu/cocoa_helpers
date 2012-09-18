//
//  FBClient.h
//  cska
//
//  Created by Arthur Evstifeev on 2/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SNClient.h"
#import "FBConnect.h"

@interface FBClient : SNClient
@property(retain, readonly) Facebook *facebook;

+ (Facebook *)currentFacebook;
- (id)initWithId:(NSString *)id;
@end