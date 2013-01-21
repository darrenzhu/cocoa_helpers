//
// AETWClient.m
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

#import "AETWClient.h"

@interface AETWClient ()

@end

@implementation AETWClient
static NSString * const baseUrl = @"https://api.twitter.com";

static AETWClient *currentTWClient;
+ (AETWClient *)currentClient {
    return currentTWClient;
}

- (id)initWithKey:(NSString *)consumerKey
           secret:(NSString *)consumerSecret
      andRedirect:(NSString *)redirectString {
    self = [super initWithBaseUrl:[NSURL URLWithString:baseUrl]
                              key:consumerKey
                           secret:consumerSecret
                      permissions:nil
                         redirect:redirectString
                 requestTokenPath:@"oauth/request_token"
                    authorizePath:@"oauth/authorize"
                  accessTokenPath:@"oauth/access_token"];
    if (self) {
        currentTWClient = self;
    }
    return self;
}

#pragma mark - token saving
- (NSString *)accessTokenKey {
    return @"TWAccessTokenKey";
}

- (NSString *)accessTokenSecretKey {
    return @"TWAccessTokenKeySecret";
}

#pragma mark - Public methods
- (void)shareLink:(NSString *)link
        withTitle:(NSString *)title
       andMessage:(NSString *)message
          success:(void (^)())success
          failure:(void (^)(NSError *))failure {
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/1.1/statuses/update.json", baseUrl]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    NSString *status = [NSString stringWithFormat:@"%@ %@", message, link];
    [body setValue:status forKey:@"status"];             
    
    [self signRequest:request withBody:body];
    
    [AESNClient processRequest:request success:^(AFHTTPRequestOperation *operation) {
        if(success) {
            success();
        }
    } failure:failure];
}

- (void)profileInformationWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/1.1/account/verify_credentials.json", baseUrl]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [self signRequest:request withBody:nil];
    
    [AESNClient processJsonRequest:request success:success failure:failure];
}

- (void)friendsInformationWithLimit:(NSInteger)limit
                             offset:(NSInteger)offset
                            success:(void (^)(NSArray *))success
                            failure:(void (^)(NSError *))failure {
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/1.1/friends/list.json", baseUrl]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [self signRequest:request withBody:nil];
    
    [AESNClient processJsonRequest:request success:^(id json) {
        if (success) {
            success([json valueForKey:@"users"]);
        }
    } failure:failure];
}

@end
