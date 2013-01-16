//
//  SNClient.m
//  cska
//
//  Created by Arthur Evstifeev on 2/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SNClient.h"

@interface SNClient () {
    NSString *_accessToken;
    NSDate *_expirationDate;
    
    id<SNClientDelegate> _delegate;
}
@end

@implementation SNClient
@synthesize delegate = _delegate;
@synthesize accessToken = _accessToken;
@synthesize expirationDate = _expirationDate;

- (BOOL)isSessionValid {
    return ( _accessToken != nil &&
            ( _expirationDate != nil &&
              [_expirationDate compare:[NSDate date]] == NSOrderedDescending ));
}

- (void)login {    
    if (![self isSessionValid]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [self regainToken:[defaults dictionaryRepresentation]];
    }
    
    if (![self isSessionValid]) {
        [self doLoginWorkflow];
    } else {
        if (_delegate) {
            [_delegate clientDidLogin:self];
        }
    }
}

- (void)shareLink:(NSString *)link
        withTitle:(NSString *)title
       andMessage:(NSString *)message {}

#pragma mark - private category
+ (void)processRequest:(NSURLRequest *)request
               success:(void (^)(AFHTTPRequestOperation *operation))success
                failed:(void (^)(NSError *error))failed {
    
    AFHTTPRequestOperation *operation =
        [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.completionBlock = ^{
        if ([operation hasAcceptableStatusCode]) {
            success(operation);
        } else {
            if (failed) {
                failed(operation.error);
            }
        }
    };
    [operation start];
}

- (void)doLoginWorkflow {
    @throw [SNClient overrideExceptionForSelector:_cmd];
}

- (void)regainToken:(NSDictionary*)savedKeysAndValues {
    @throw [SNClient overrideExceptionForSelector:_cmd];
}

- (void)saveToken:(NSDictionary*)tokensToSave {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValuesForKeysWithDictionary:tokensToSave];
    [defaults synchronize];
}

- (BOOL)processWebViewResult:(NSURL*)processUrl {
    @throw [SNClient overrideExceptionForSelector:_cmd];
}

- (void)setExpirationDate:(NSDate *)expirationDate {
    if (_expirationDate) {
        [_expirationDate release];
    }
    
    _expirationDate = [expirationDate retain];
}

- (void)setAccessToken:(NSString *)accessToken {
    if (_accessToken) {
        [_accessToken release];
    }
    
    _accessToken = [accessToken retain];
}

#pragma mark - private
+ (NSException *)overrideExceptionForSelector:(SEL)selector {
    NSString *message = [NSString stringWithFormat:@"You  must override %@ in a subclass",
                         NSStringFromSelector(selector)];
    return [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:message
                                 userInfo:nil];
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType {    
        
    if ([self processWebViewResult:request.URL])
        [webView removeFromSuperview];
    
    return YES;
}

@end
