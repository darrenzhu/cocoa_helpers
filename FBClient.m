//
//  FBClient.m
//  cska
//
//  Created by Arthur Evstifeev on 2/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FBClient.h"

#import "TTAlert.h"

@implementation FBClient
@synthesize facebook = _facebook;

- (void)setFacebook:(Facebook*)facebook {
    _facebook = facebook;
}

+ (FBClient*)sharedClient {
    static FBClient* _sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] init];
        Facebook* facebook = [[Facebook alloc] initWithAppId:@"271988946184429" andDelegate:_sharedClient];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults objectForKey:@"FBAccessTokenKey"] 
            && [defaults objectForKey:@"FBExpirationDateKey"]) {
            facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
            facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
        }
        
        if (![facebook isSessionValid]) {
            NSArray *permissions = [[NSArray alloc] initWithObjects: @"share_item", nil];
            [facebook authorize:permissions];
        }                        
        
        [_sharedClient setFacebook:facebook];
    });
    
    return _sharedClient;
}

- (BOOL)isSessionValid {
    return [_facebook isSessionValid];
}

- (void)share:(CCNews*) _news andMessage:(NSString *)message {
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    [params setObject:[NSString stringWithFormat:@"http://www.cskabasket.com/news/?id=%i", _news.id.intValue] forKey:@"link"];
    [params setObject:_news.title forKey:@"name"];
    [params setObject:message forKey:@"message"];
    [params setObject:[NSString stringWithFormat:@"http://www.cskabasket.com/images/iphotos/main-%@", _news.photo] forKey:@"picture"];    
    
    [_facebook requestWithGraphPath:@"me/links" andParams:params andHttpMethod:@"POST"  andDelegate:self];        
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

#pragma mark - FBSessionDelegate

- (void)fbDidLogin {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[_facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[_facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];  
    
    [_delegate clientDidLogin:self];
}

- (void)fbDidNotLogin:(BOOL)cancelled {
    
}

- (void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt {
    
}

- (void)fbDidLogout {
    
}

- (void)fbSessionInvalidated {
    
}

#pragma mark - FBRequestDelegate

- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response {
    [TTAlert composeAlertViewWithTitle:@"" andMessage:@"Ссылка успешно добавлена"];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    [TTAlert composeAlertViewWithTitle:@"" andMessage:@"К сожалению произошла ошибка"];
    NSLog(@"Error %@", error);
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
