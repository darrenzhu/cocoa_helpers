//
// AESNClient.h
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

#import "AFHTTPRequestOperation.h"

/**
 Generic class for all auth client classes. Manages common behaviour:

 - Persistency of your tokens and other suitable information (in keychain or user defaults)
 - Notification via delegate about authorization stages
 - Exposes common actions for users
*/
@protocol AESNClientDelegate;
@interface AESNClient : NSObject <UIWebViewDelegate>

/**
 Current OAuth access token
 */
@property(retain, nonatomic, readonly) NSString *accessToken;

/**
 Access token expiration date. Not all services provide this information.
 */
@property(retain, nonatomic, readonly) NSDate *expirationDate;

/**
 Registered class delegate.
 */
@property(unsafe_unretained, nonatomic) id<AESNClientDelegate> delegate;

/**
 Checks current sessions. By default current session is valid if access token presents and it is not expired.
 
 @discussion If you need additional session validations, you should override this method.
 
 @return YES if session is valid, otherwise NO
 */
- (BOOL)isSessionValid;

/**
    Starts client login process. If possible client will restore previous session.
 
    @discussion You shouldn't override this method in your subclass. Watch private methods.
 */
- (void)login;

/**
 Posts sharing object to the user profile.
 
 @discussion You should override this method in your subclass and provide concrete implementation.
 
 @param link URL as string to share
 @param title Sharing message title
 @param message Sharing message
 @param success A Block, invoked for success response
 @param failure A Block, invoked for failed response
 */
- (void)shareLink:(NSString *)link
        withTitle:(NSString *)title
       andMessage:(NSString *)message
          success:(void (^)())success
          failure:(void (^)(NSError *error))failure;

/**
 Requests user profile. Format depends on the returned data from the service.
 
 @discussion You should override this method in your subclass and provide concrete implementation.
 
 @param success A Block, invoked for success response
 @param failure A Block, invoked for failed response
 */
- (void)profileInformationWithSuccess:(void (^)(NSDictionary *profile))success
                              failure:(void (^)(NSError *error))failure;

/**
 Requests user's friends list. Format depends on the returned data from the service.
 
 @discussion You should override this method in your subclass and provide concrete implementation.
 
 @param limit Number of items to return. Works only for services that support response pagination.
 @param offset Offset of items to return. Works only for services that support response pagination.
 @param success A Block, invoked for success response
 @param failure A Block, invoked for failed response
 */
- (void)friendsInformationWithLimit:(NSInteger)limit
                             offset:(NSInteger)offset
                            success:(void (^)(NSArray *friends))success
                            failure:(void (^)(NSError *error))failure;
@end

/**
 Private category, defines methods for subclasses.
 */
@interface AESNClient (Private)

/**
 Helper method for enqueuing requests with AFNetworking. Used for signed requests.
 
 @param request Request to enqueue
 @param success A Block, invoked for success response
 @param failure A Block, invoked for failed response
 */
+ (void)processRequest:(NSURLRequest *)request
               success:(void (^)(AFHTTPRequestOperation *operation))success
               failure:(void (^)(NSError *error))failure;

/**
  Helper method for enqueuing JSON requests with AFNetworking. Used for signed requests.
 
 @param request Request to enqueue
 @param success A Block, invoked for success response
 @param failure A Block, invoked for failed response
 */
+ (void)processJsonRequest:(NSURLRequest *)request
                   success:(void (^)(id json))success
                   failure:(void (^)(NSError *error))failure;

/**
 Starts auth process. This will restarts all process from the begining.
 
 @discussion You should override this method and provide idempotent starting point for your client.
 */
- (void)doLoginWorkflow;

/**
 Restores token and other necessary information.
 
 @param savedKeysAndValues Dictionary of previously saved values.
 */
- (void)regainToken:(NSDictionary *)savedKeysAndValues;

/**
 Saves token and other neccessary information into persistent storage.
 
 @param tokensToSave A dicstionary with information to save.
 */
- (void)saveToken:(NSDictionary *)tokensToSave;

/**
 Parses returned authorization information from URL. Used after `openURL` or `UIWebView` recieved neccessary redirect.
 
 @discussion You should override this method and extract auth token.
 
 @param processUrl A URL recieved after redirect.
 
 @return YES if token extraction successfull, otherwise NO.
 */
- (BOOL)processWebViewResult:(NSURL *)processUrl;

/**
 Setter for subclasses.
 
 @param expirationDate A date to set as token expiration date.
 */
- (void)setExpirationDate:(NSDate *)expirationDate;

/**
 Setter for subclasses.
 
 @param accessToken A string to set as access token.
 */
- (void)setAccessToken:(NSString *)accessToken;
@end

/**
 The delegate of a AESNClient object must adopt the `AESNClientDelegate` protocol. This protocol allows you to get state change notifications.
 */
@protocol AESNClientDelegate <NSObject>

/**
 Notifies the delegate that it is neccessary to present auth page to the user. 
 
 @discussion You can use `openURL` or `UIWebView`. Some services do not support redirects to custom URL, in that case you can't use openURL.
 
 @param client Client object posting this information.
 @param url A URL that should be opened. 
*/
- (void)client:(AESNClient *)client wantsPresentAuthPage:(NSURL *)url;

/**
 Notifies the delegate about successfull login attempt.
 
 @param client Client object posting this information.
 */
- (void)clientDidLogin:(AESNClient *)client;
@end
