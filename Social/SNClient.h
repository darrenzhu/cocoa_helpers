//
//  SNClient.h
//  cska
//
//  Created by Arthur Evstifeev on 2/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperation.h"

@protocol SNClientDelegate;
@interface SNClient : NSObject <UIWebViewDelegate>
@property(retain, nonatomic, readonly) NSString *accessToken;
@property(retain, nonatomic, readonly) NSDate *expirationDate;
@property(unsafe_unretained, nonatomic) id<SNClientDelegate> delegate;

- (BOOL)isSessionValid;
- (void)login;
- (void)shareLink:(NSString *)link withTitle:(NSString *)title andMessage:(NSString *)message;
@end

@interface SNClient (Private)
+ (void)processRequest:(NSURLRequest *)request
               success:(void (^)(AFHTTPRequestOperation *operation))success
                failed:(void (^)(NSError *error))failed;
- (void)doLoginWorkflow;
- (void)regainToken:(NSDictionary *)savedKeysAndValues;
- (void)saveToken:(NSDictionary *)tokensToSave;
- (BOOL)processWebViewResult:(NSURL *)processUrl;
- (void)setExpirationDate:(NSDate *)expirationDate;
- (void)setAccessToken:(NSString *)accessToken;
@end

@protocol SNClientDelegate <NSObject>
- (void)client:(SNClient *)client showAuthPage:(NSString *)url;
- (void)clientDidLogin:(SNClient *)client ;
@end