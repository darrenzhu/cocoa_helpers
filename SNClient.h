//
//  SNClient.h
//  cska
//
//  Created by Arthur Evstifeev on 2/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NetworkIndicatorManager.h"

@protocol SNClientDelegate;
@interface SNClient : NSObject <UIWebViewDelegate> {
    NSString* _accessToken;
    NSDate* _expirationDate;
    
    id<SNClientDelegate> _delegate;
}

@property(strong, readonly) NSString* accessToken;
@property(strong) id<SNClientDelegate> delegate;

- (BOOL)isSessionValid;
- (void)login;
- (void)shareLink:(NSString*)link withTitle:(NSString*)title andMessage:(NSString*)message;
@end

@interface SNClient (Private)
- (void)doLoginWorkflow;
- (void)regainToken:(NSDictionary*)savedKeysAndValues;
- (void)saveToken:(NSDictionary*)tokensToSave;
- (BOOL)processWebViewResult:(NSURL*)processUrl;
@end

@protocol SNClientDelegate <NSObject>

- (void)client:(SNClient*)client showAuthPage:(NSString*)url;
- (void)clientDidLogin:(SNClient*)client ;

@end