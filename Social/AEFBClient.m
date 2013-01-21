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

#import "AEFBClient.h"

@interface AEFBClient () <FBSessionDelegate, FBRequestDelegate>
@property (retain, nonatomic) Facebook *facebook;
@property (retain, nonatomic) NSMutableDictionary *requestsSuccessCallbacks;
@property (retain, nonatomic) NSMutableDictionary *requestsFailureCallbacks;
@property (retain, nonatomic) NSArray *permissions;
@end

@implementation AEFBClient

NSString * const fbAccessTokenKey = @"FBAccessTokenKey";
NSString * const fbExpirationDateKey = @"FBExpirationDateKey";

static AEFBClient *currentClient;
+ (AEFBClient *)currentClient {
    return currentClient;
}

- (id)initWithId:(NSString *)appId permissions:(NSArray *)permissions {
    self = [super init];
    if (self) {
        _facebook                       = [[Facebook alloc] initWithAppId:appId andDelegate:self];
        currentClient                   = self;

        self.requestsSuccessCallbacks   = [NSMutableDictionary dictionary];
        self.requestsFailureCallbacks   = [NSMutableDictionary dictionary];
        
        self.permissions                = permissions;
    }
    return self;
}

- (void)dealloc {
    [_facebook release];
    [_requestsSuccessCallbacks release];
    [_requestsFailureCallbacks release];
    [_permissions release];
    [super dealloc];
}

#pragma mark - overriden

- (void)regainToken:(NSDictionary *)savedKeysAndValues {
    if ([savedKeysAndValues objectForKey:fbAccessTokenKey] &&
        [savedKeysAndValues objectForKey:fbExpirationDateKey]) {
        
        _facebook.accessToken       = [savedKeysAndValues objectForKey:fbAccessTokenKey];
        _facebook.expirationDate    = [savedKeysAndValues objectForKey:fbExpirationDateKey];
    }
}

- (void)doLoginWorkflow {
    [_facebook authorize:_permissions];
}

- (BOOL)isSessionValid {
    return [_facebook isSessionValid];
}

- (void)shareLink:(NSString *)link
        withTitle:(NSString *)title
       andMessage:(NSString *)message
          success:(void (^)())success
          failure:(void (^)(NSError *error))failure {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:link forKey:@"link"];
    [params setObject:title forKey:@"name"];
    [params setObject:message forKey:@"message"];
    
    FBRequest *request = [_facebook requestWithGraphPath:@"me/links"
                                               andParams:params
                                           andHttpMethod:@"POST"
                                             andDelegate:self];
    
    [self setRequestCallbacksForPath:[request graphPath] success:success failure:failure];
}

- (void)profileInformationWithSuccess:(void (^)(NSDictionary *profile))success
                              failure:(void (^)(NSError *error))failure {
    
    FBRequest *request = [_facebook requestWithGraphPath:@"me" andDelegate:self];
    [self setRequestCallbacksForPath:[request graphPath] success:success failure:failure];
}

- (void)friendsInformationWithLimit:(NSInteger)limit
                             offset:(NSInteger)offset
                            success:(void (^)(NSArray *friends))success
                            failure:(void (^)(NSError *error))failure {
    
    NSString *path = [NSString stringWithFormat:@"me/friends?offset=%i", offset];
    if (limit > 0) {
        path = [path stringByAppendingFormat:@"&limit=%i", limit];
    }
    
    FBRequest *request = [_facebook requestWithGraphPath:path andDelegate:self];
    [self setRequestCallbacksForPath:[request graphPath] success:success failure:failure];
}


#pragma mark - FBSessionDelegate
- (void)fbDidLogin {
    NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
    [tokens setValue:[_facebook accessToken] forKey:fbAccessTokenKey];
    [tokens setValue:[_facebook expirationDate] forKey:fbExpirationDateKey];
    [self saveToken:tokens];
    
    if (self.delegate) {
        [self.delegate clientDidLogin:self];
    }
}

- (void)fbDidNotLogin:(BOOL)cancelled {}

- (void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt {}

- (void)fbDidLogout {}

- (void)fbSessionInvalidated {}

#pragma mark - FBRequestDelegate
- (void)request:(FBRequest *)request didLoad:(id)result {
    void (^success)(id profile) = [_requestsSuccessCallbacks valueForKey:request.graphPath];
    if (success) {
        success(result && [result valueForKey:@"data"] ? [result valueForKey:@"data"] : result);
    }
    
    [self setRequestCallbacksForPath:[request graphPath] success:nil failure:nil];
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    void (^failure)(NSError *error) = [_requestsFailureCallbacks valueForKey:request.graphPath];
    if (failure) {
        failure(error);
    }
    
    [self setRequestCallbacksForPath:[request graphPath] success:nil failure:nil];
}

#pragma mark - private
- (void)setRequestCallbacksForPath:(NSString *)graphPath
                           success:(void (^)(id profile))success
                           failure:(void (^)(NSError *error))failure {
    
    if (success) {
        [_requestsSuccessCallbacks setValue:success forKey:graphPath];
    } else {        
        [_requestsSuccessCallbacks removeObjectForKey:graphPath];
    }
    
    if (failure) {
        [_requestsFailureCallbacks setValue:failure forKey:graphPath];
    } else {
        [_requestsFailureCallbacks removeObjectForKey:graphPath];
    }
}

@end
