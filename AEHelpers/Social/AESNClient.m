//
// AESNClient.m
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

#import "AESNClient.h"
#import "AFJSONRequestOperation.h"
#import "SSKeychain.h"

@interface AESNClient ()
@property (retain, nonatomic) NSString *accessToken;
@property (retain, nonatomic) NSDate *expirationDate;
@end

@implementation AESNClient

static NSString * const keychainAccount = @"access_token";

- (void)dealloc {
    [_accessToken release];
    [_expirationDate release];
    [super dealloc];
}

- (BOOL)isSessionValid {
    return ( _accessToken != nil &&
            ( _expirationDate != nil &&
              [_expirationDate compare:[NSDate date]] == NSOrderedDescending ));
}

- (void)login {    
    if (![self isSessionValid]) {
        NSData *encodedData = [SSKeychain passwordDataForService:NSStringFromClass([self class])
                                                         account:keychainAccount];
        
        if (encodedData) {
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:encodedData];
            NSDictionary *restoredTokens = [unarchiver decodeObject];
            
            [self regainToken:restoredTokens];
            [unarchiver release];
        }
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
       andMessage:(NSString *)message
          success:(void (^)())success
          failure:(void (^)(NSError *error))failure {}

- (void)profileInformationWithSuccess:(void (^)(NSDictionary *profile))success
                              failure:(void (^)(NSError *error))failure {}

- (void)friendsInformationWithLimit:(NSInteger)limit
                             offset:(NSInteger)offset
                            success:(void (^)(NSArray *friends))success
                            failure:(void (^)(NSError *error))failure {}

#pragma mark - private category
+ (void)processRequest:(NSURLRequest *)request
               success:(void (^)(AFHTTPRequestOperation *operation))success
               failure:(void (^)(NSError *error))failure {
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.completionBlock = ^{
        if ([operation hasAcceptableStatusCode]) {
            success(operation);
        } else {
            if (failure) {
                failure(operation.error);
            }
        }
    };
    [operation start];
}

+ (void)processJsonRequest:(NSURLRequest *)request
                   success:(void (^)(id json))success
                   failure:(void (^)(NSError *error))failure {
    AFJSONRequestOperation *operation =
        [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                        success:^(NSURLRequest *request,
                                                                  NSHTTPURLResponse *response,
                                                                  id JSON) {
                                                            if(success) {
                                                                success(JSON);
                                                            }
                                                        } failure:^(NSURLRequest *request,
                                                                    NSHTTPURLResponse *response,
                                                                    NSError *error,
                                                                    id JSON) {
                                                            if (failure) {
                                                                failure(error);
                                                            }
                                                        }];
    [operation start];
}

- (void)doLoginWorkflow {
    @throw [AESNClient overrideExceptionForSelector:_cmd];
}

- (void)regainToken:(NSDictionary*)savedKeysAndValues {
    @throw [AESNClient overrideExceptionForSelector:_cmd];
}

- (void)saveToken:(NSDictionary*)tokensToSave {    
    NSMutableData *archivedData = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archivedData];
    [archiver setOutputFormat:NSPropertyListXMLFormat_v1_0];
    [archiver encodeObject:tokensToSave];
    [archiver finishEncoding];
    
    [SSKeychain setPasswordData:archivedData forService:NSStringFromClass([self class]) account:keychainAccount];
    [archiver release];
}

- (BOOL)processWebViewResult:(NSURL*)processUrl {
    @throw [AESNClient overrideExceptionForSelector:_cmd];
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
        
    if ([self processWebViewResult:request.URL]) {
        [webView removeFromSuperview];
    }
    
    return YES;
}

@end
