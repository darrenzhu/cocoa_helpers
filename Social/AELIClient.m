//
// AELIClient.m
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

#import "AELIClient.h"

@implementation AELIClient

static NSString * const baseUrl = @"https://api.linkedin.com";

static AELIClient *currentLIClient;
+ (AELIClient *)currentClient {
    return currentLIClient;
}

- (id)initWithKey:(NSString *)consumerKey
           secret:(NSString *)consumerSecret
      permissions:(NSArray *)permissions
      andRedirect:(NSString *)redirectString {
    
    self = [super initWithBaseUrl:[NSURL URLWithString:baseUrl]
                              key:consumerKey
                           secret:consumerSecret
                      permissions:permissions
                         redirect:redirectString
                 requestTokenPath:@"uas/oauth/requestToken"
                    authorizePath:@"uas/oauth/authorize"
                  accessTokenPath:@"uas/oauth/accessToken"];
    if (self) {
        currentLIClient = self;
    }
    
    return self;
}

#pragma mark - token saving
- (NSString *)accessTokenKey {
    return @"LIAccessTokenKey";
}

- (NSString *)accessTokenSecretKey {
    return @"LIAccessTokenKeySecret";
}

#pragma mark - Public methods
- (void)profileInformationWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    [self profileInformationWithFields:nil success:success failure:failure];
}

- (void)profileInformationWithFields:(NSArray *)fields
                             success:(void (^)(NSDictionary *))success
                             failure:(void (^)(NSError *))failure {

    NSString *profilePath   = [baseUrl stringByAppendingString:@"/v1/people/~"];
    if (fields) {
        profilePath         = [profilePath stringByAppendingFormat:@":(%@)", [fields componentsJoinedByString:@","]];
    }
    profilePath             = [profilePath stringByAppendingString:@"?format=json"];
    
    NSURL *profileUrl                   = [NSURL URLWithString:profilePath];    
    NSMutableURLRequest *profileRequest = [NSMutableURLRequest requestWithURL:profileUrl];
    [self signRequest:profileRequest withBody:nil];

    [AESNClient processJsonRequest:profileRequest success:success failure:failure];
}

- (void)friendsInformationWithLimit:(NSInteger)limit
                             offset:(NSInteger)offset
                            success:(void (^)(NSArray *))success
                            failure:(void (^)(NSError *))failure {
    [self friendsInformationWithFields:nil limit:limit offset:offset success:success failure:failure];
}

- (void)friendsInformationWithFields:(NSArray *)fields
                               limit:(NSInteger)limit
                              offset:(NSInteger)offset
                             success:(void (^)(NSArray *))success
                             failure:(void (^)(NSError *))failure {

    NSString *friendsPath   = [baseUrl stringByAppendingString:@"/v1/people/~/connections"];
    if (fields) {
        friendsPath         = [friendsPath stringByAppendingFormat:@":(%@)", [fields componentsJoinedByString:@","]];
    }
    friendsPath             = [friendsPath stringByAppendingFormat:@"?format=json&start=%i", offset];
    if (limit > 0) {
        friendsPath         = [friendsPath stringByAppendingFormat:@"&count=%i", limit];
    }
    
    NSURL *friendsUrl                   = [NSURL URLWithString:friendsPath];
    NSMutableURLRequest *friendsRequest = [NSMutableURLRequest requestWithURL:friendsUrl];
    [self signRequest:friendsRequest withBody:nil];
    
    [AESNClient processJsonRequest:friendsRequest success:^(id json) {
        if(success) {
            success([json objectForKey:@"values"]);
        }
    } failure:failure];
}

@end
