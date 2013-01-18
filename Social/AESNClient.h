//
// SNClient.h
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

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperation.h"

@protocol AESNClientDelegate;
@interface AESNClient : NSObject <UIWebViewDelegate>
@property(retain, nonatomic, readonly) NSString *accessToken;
@property(retain, nonatomic, readonly) NSDate *expirationDate;
@property(unsafe_unretained, nonatomic) id<AESNClientDelegate> delegate;

- (BOOL)isSessionValid;
- (void)login;
- (void)shareLink:(NSString *)link
        withTitle:(NSString *)title
       andMessage:(NSString *)message
          success:(void (^)())success
          failure:(void (^)(NSError *error))failure;
- (void)profileInformationWithSuccess:(void (^)(NSDictionary *profile))success failure:(void (^)(NSError *error))failure;
- (void)friendsInformationWithLimit:(NSInteger)limit
                             offset:(NSInteger)offset
                            success:(void (^)(NSArray *friends))success
                            failure:(void (^)(NSError *error))failure;
@end

@interface AESNClient (Private)
+ (void)processRequest:(NSURLRequest *)request
               success:(void (^)(AFHTTPRequestOperation *operation))success
               failure:(void (^)(NSError *error))failure;
- (void)doLoginWorkflow;
- (void)regainToken:(NSDictionary *)savedKeysAndValues;
- (void)saveToken:(NSDictionary *)tokensToSave;
- (BOOL)processWebViewResult:(NSURL *)processUrl;
- (void)setExpirationDate:(NSDate *)expirationDate;
- (void)setAccessToken:(NSString *)accessToken;
@end

@protocol AESNClientDelegate <NSObject>
- (void)client:(AESNClient *)client wantsPresentAuthPage:(NSURL *)url;
- (void)clientDidLogin:(AESNClient *)client ;
@end
