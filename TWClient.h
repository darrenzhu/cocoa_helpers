//
//  TWClient.h
//  cska
//
//  Created by Arthur Evstifeev on 2/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SNClient.h"

@interface TWClient : SNClient <UIWebViewDelegate> {
    
    NSMutableDictionary *_oAuthValues;
    NSString* _accessTokenSecret;
    NSString *_verifier;
    
    NSString* _consumerKey;
    NSString* _consumerSecret;
    NSString* _redirectString;
}

- (id)initWithKey:(NSString*)consumerKey 
           secret:(NSString*)consumerSecret 
      andRedirect:(NSString*)redirectString;

@end