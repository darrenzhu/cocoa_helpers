//
//  FBClient.m
//  cska
//
//  Created by Arthur Evstifeev on 2/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FBClient.h"
#import "TTAlert.h"

@interface FBClient () <FBSessionDelegate, FBRequestDelegate> {
    Facebook* _facebook;
}
@end

@implementation FBClient
@synthesize facebook = _facebook;

static Facebook *currentFacebook;
+ (Facebook *)currentFacebook {
    return currentFacebook;
}

- (id)initWithId:(NSString *)id {
    self = [super init];
    if (self) {
        _facebook = [[Facebook alloc] initWithAppId:id andDelegate:self];     
        currentFacebook = _facebook;
    }
    return self;
}

- (void)regainToken:(NSDictionary *)savedKeysAndValues {
    if ([savedKeysAndValues objectForKey:@"FBAccessTokenKey"] 
        && [savedKeysAndValues objectForKey:@"FBExpirationDateKey"]) {
        _facebook.accessToken = [savedKeysAndValues objectForKey:@"FBAccessTokenKey"];
        _facebook.expirationDate = [savedKeysAndValues objectForKey:@"FBExpirationDateKey"];
    }
}

- (void)doLoginWorkflow {
    NSArray *permissions = [NSArray arrayWithObjects: @"share_item", nil];
    [_facebook authorize:permissions];
}

- (BOOL)isSessionValid {
    return [_facebook isSessionValid];
}

- (void)shareLink:(NSString *)link withTitle:(NSString *)title andMessage:(NSString *)message {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:link forKey:@"link"];
    [params setObject:title forKey:@"name"];
    [params setObject:message forKey:@"message"];
    
    [_facebook requestWithGraphPath:@"me/links"
                          andParams:params
                      andHttpMethod:@"POST"
                        andDelegate:self];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

#pragma mark - FBSessionDelegate
- (void)fbDidLogin {
    NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
    [tokens setValue:[_facebook accessToken] forKey:@"FBAccessTokenKey"];
    [tokens setValue:[_facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [self saveToken:tokens];
    
    [self.delegate clientDidLogin:self];
}

- (void)fbDidNotLogin:(BOOL)cancelled {
    NSLog(@"fbDidNotLogin");
}

- (void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt {}

- (void)fbDidLogout {
    NSLog(@"fbDidLogout");
}

- (void)fbSessionInvalidated {
    NSLog(@"fbSessionInvalidated");
}

#pragma mark - FBRequestDelegate
- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response {
    [TTAlert composeAlertViewWithTitle:@""
                            andMessage:NSLocalizedString(@"Ссылка успешно добавлена", nil)];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    NSString *message = NSLocalizedString(@"К сожалению произошла ошибка", nil);
    [TTAlert composeAlertViewWithTitle:@""
                            andMessage:message];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    NSLog(@"Error %@", error);
}

@end
