//
// AEXingClient.m
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

#import "AEXingClient.h"

@implementation AEXingClient

static NSString * const baseUrl = @"https://api.xing.com";

static AEXingClient *currentClient;
+ (AEXingClient *)currentClient {
    return currentClient;
}

- (id)initWithKey:(NSString *)consumerKey
           secret:(NSString *)consumerSecret
      andRedirect:(NSString *)redirectString {
    
    self = [super initWithBaseUrl:[NSURL URLWithString:baseUrl]
                              key:consumerKey
                           secret:consumerSecret
                      permissions:nil
                         redirect:redirectString
                 requestTokenPath:@"v1/request_token"
                    authorizePath:@"v1/authorize"
                  accessTokenPath:@"v1/access_token"];
    if (self) {
        currentClient = self;
    }
    
    return self;
}

#pragma mark - token saving
- (NSString *)accessTokenKey {
    return @"XingAccessTokenKey";
}

- (NSString *)accessTokenSecretKey {
    return @"XingAccessTokenKeySecret";
}

#pragma mark - Public methods
- (void)profileInformationWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    [self profileInformationWithFields:nil success:success failure:failure];
}

- (void)profileInformationWithFields:(NSArray *)fields
                             success:(void (^)(NSDictionary *))success
                             failure:(void (^)(NSError *))failure {
    
    NSDictionary *params = nil;
    if (fields) {
        params = @{ @"fields": [fields componentsJoinedByString:@","] };
    }
    
    [self signedGetPath:@"/v1/users/me.json"
             parameters:params
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    
                    NSArray *users = [responseObject objectForKey:@"users"];
                    if (!users || [users count] <= 0) return;
                    
                    if (success) success([users objectAtIndex:0]);
                    
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    
                    if (failure) failure(error);                    
                }];
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
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"json",     @"format",
                                   @(offset),   @"offset",
                                   nil];
    if (limit > 0) {
        [params setValue:@(limit) forKey:@"limit"];
    }
    if (fields) {
        [params setValue:[fields componentsJoinedByString:@","] forKey:@"user_fields"];
    }
    
    [self signedGetPath:@"/v1/users/me/contacts.json"
             parameters:params
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    
                    if(success) success([responseObject objectForKey:@"values"]);
                    
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   
                    if (failure) failure(error);                    
                }];
}

@end
