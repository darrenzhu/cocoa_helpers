//
// FBClient.m
//
// Copyright (c) 2012 ap4y (lod@pisem.net)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

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

- (void)fbDidNotLogin:(BOOL)cancelled {}

- (void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt {}

- (void)fbDidLogout {}

- (void)fbSessionInvalidated {}

#pragma mark - FBRequestDelegate
- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response {
    [TTAlert composeAlertViewWithTitle:@"" andMessage:NSLocalizedString(@"Ссылка успешно добавлена", nil)];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    NSString *message = NSLocalizedString(@"К сожалению произошла ошибка", nil);
    [TTAlert composeAlertViewWithTitle:@"" andMessage:message];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
