//
//  SNClient.h
//  cska
//
//  Created by Arthur Evstifeev on 2/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CCNews.h"

@protocol SNClientDelegate;
@interface SNClient : NSObject {
    NSString* _accessToken;
    NSString* _accessTokenSecret;
    NSDate* _expirationDate;
    
    id<SNClientDelegate> _delegate;
}

@property(strong, readonly) NSString* accessToken;
@property(strong) id<SNClientDelegate> delegate;

- (NSString*)accessTokenKey;
- (NSString*)accessTokenKeySecretKey;
- (NSString*)expirationDateKey;
- (BOOL)isSessionValid;
- (void)login;
- (void)parseUrl:(NSString*)url;
- (void)share:(CCNews*)_news andMessage:(NSString*)message;
- (void)saveToken;

@end

@protocol SNClientDelegate <NSObject>

- (void)client:(SNClient*)client showAuthPage:(NSString*)url;

- (void)clientDidLogin:(SNClient*)client ;

@end