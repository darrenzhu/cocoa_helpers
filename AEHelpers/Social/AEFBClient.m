//
// AEFBClient.m
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

#import "AEFBClient.h"

@interface AEFBClient ()
@property (copy, nonatomic) NSArray *permissions;
@property (copy, nonatomic) NSString *appId;

@property (retain, nonatomic) NSString *redirectUrlString;
@end

@implementation AEFBClient

static NSString * const baseUrl         = @"https://m.facebook.com/dialog";
static NSString * const graphBaseUrl    = @"https://graph.facebook.com";
NSString * const fbAccessTokenKey       = @"FBAccessTokenKey";
NSString * const fbExpirationDateKey    = @"FBExpirationDateKey";

static AEFBClient *currentClient;
+ (AEFBClient *)currentClient {
    return currentClient;
}

- (id)initWithId:(NSString *)appId permissions:(NSArray *)permissions {
    self = [super initWithBaseURL:[NSURL URLWithString:graphBaseUrl]];
    if (self) {
        currentClient                   = self;

        self.permissions                = permissions;        
        self.redirectUrlString          = [NSString stringWithFormat:@"fb%@://authorize", appId];
        self.appId                      = appId;
    }
    return self;
}

- (void)dealloc {
    [_permissions release];
    [_appId release];
    [_redirectUrlString release];
    [super dealloc];
}

- (void)shareLink:(NSString *)link
        withTitle:(NSString *)title
       andMessage:(NSString *)message
          success:(void (^)())success
          failure:(void (^)(NSError *error))failure {

    NSString *sharePath                 = [NSString stringWithFormat:@"%@/me/links", graphBaseUrl];
    NSURL *shareUrl                     = [NSURL URLWithString:sharePath];
    NSMutableURLRequest *shareRequest   = [NSMutableURLRequest requestWithURL:shareUrl];
    [shareRequest setHTTPMethod:@"POST"];
    
    NSMutableDictionary *params         = [NSMutableDictionary dictionary];
    [params setValue:link forKey:@"link"];
    [params setValue:title forKey:@"name"];
    [params setValue:message forKey:@"message"];
    [params setValue:self.accessToken forKey:@"access_token"];            
    
    [self postPath:@"/me/links"
        parameters:params
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               
               if (success) success();
               
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
               if (failure) failure(error);
           }];
}

- (void)profileInformationWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    
    [self getPath:@"/me"
       parameters:@{ @"access_token": self.accessToken }
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              
              if (success) success(responseObject);
              
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              
              if (failure) failure(error);
          }];    
}

- (void)friendsInformationWithLimit:(NSInteger)limit
                             offset:(NSInteger)offset
                            success:(void (^)(NSArray *))success
                            failure:(void (^)(NSError *))failure {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   self.accessToken,    @"access_token",
                                   @(offset),           @"offset",
                                   nil];
    if (limit > 0) {
        [params setValue:@(limit) forKey:@"limit"];
    }
    
    [self getPath:@"/me/friends"
       parameters:params
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              
              if (success) success([responseObject valueForKey:@"data"]);
              
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              
              if (failure) failure(error);
          }];
}

#pragma mark - overriden

- (void)regainToken:(NSDictionary *)savedKeysAndValues {
    if ([savedKeysAndValues objectForKey:fbAccessTokenKey] &&
        [savedKeysAndValues objectForKey:fbExpirationDateKey]) {
        
        self.accessToken       = [savedKeysAndValues objectForKey:fbAccessTokenKey];
        self.expirationDate    = [savedKeysAndValues objectForKey:fbExpirationDateKey];
    }
}

- (void)doLoginWorkflow {
    if (!self.delegate) {
        return;
    }
    
    NSString *codeRequestPath = [NSString stringWithFormat:@"%@/oauth?type=user_agent&display=touch&sdk=ios", baseUrl];
    codeRequestPath           = [codeRequestPath stringByAppendingFormat:@"&client_id=%@&redirect_uri=%@&scope=%@",
                                 _appId,
                                 _redirectUrlString,
                                 [_permissions componentsJoinedByString:@","]];
    
    NSURL *codeRequestUrl     = [NSURL URLWithString:codeRequestPath];
    [self.delegate client:self wantsPresentAuthPage:codeRequestUrl];

}

- (BOOL)processWebViewResult:(NSURL *)processUrl {
    if (![[processUrl absoluteString] hasPrefix:_redirectUrlString]) {
        return NO;
    }

    NSString *query             = [processUrl fragment];
    NSArray *components         = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [components enumerateObjectsUsingBlock:^(NSString *pairs, NSUInteger idx, BOOL *stop) {
        
        NSArray *pairsComponents = [pairs componentsSeparatedByString:@"="];
        if ([pairsComponents count] < 2) return;
        
        [params setValue:[pairsComponents objectAtIndex:1]
                  forKey:[pairsComponents objectAtIndex:0]];
    }];    
    
    [self clientDidLoginWithParams:params];
    
    return YES;
}

#pragma mark - private
- (void)clientDidLoginWithParams:(NSDictionary *)params {
    NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
    NSNumber *expiresIn         = [params valueForKey:@"expires_in"];
    
    self.accessToken            = [params valueForKey:@"access_token"];
    self.expirationDate         = [NSDate dateWithTimeIntervalSinceNow:[expiresIn doubleValue]];
    
    [tokens setValue:self.accessToken forKey:fbAccessTokenKey];
    [tokens setValue:self.expirationDate forKey:fbExpirationDateKey];
    [self saveToken:tokens];

    if (self.delegate) {
        [self.delegate clientDidLogin:self];
    }
}

@end
