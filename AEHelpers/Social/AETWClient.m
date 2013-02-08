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
    
    NSString *status = [NSString stringWithFormat:@"%@ %@", message, link];
    NSDictionary *params = [NSDictionary dictionaryWithObject:status forKey:@"status"];
    
    [self signedPostPath:@"/1.1/statuses/update.json"
              parameters:params
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     
                     if (success) success();
                     
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     
                     if (failure) failure(error);
                 }];
}

- (void)profileInformationWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    
    [self signedGetPath:@"/1.1/account/verify_credentials.json"
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    
                    if(success) success(responseObject);
                    
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    
                    if (failure) failure(error);
                }];
}

- (void)friendsInformationWithLimit:(NSInteger)limit
                             offset:(NSInteger)offset
                            success:(void (^)(NSArray *))success
                            failure:(void (^)(NSError *))failure {
    
    [self signedGetPath:@"/1.1/friends/list.json"
             parameters:nil
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    
                    if (success) success([responseObject valueForKey:@"users"]);
                    
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    
                    if (failure) failure(error);
                }];
}

@end
