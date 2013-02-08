//
// AEOAuthClient.h
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

/**
 `AESNClient` subclass, implements OAuth 1.x authorization algorithm. Generic client for all OAuth 1.x client classes.
 */
@interface AEOAuthClient : AESNClient

/**
 Designated initializer for all OAuth 1.x clients. 
 
 @return Initialized instance of the OAuth client class
*/
- (id)initWithBaseUrl:(NSURL *)baseUrl
                  key:(NSString *)consumerKey
               secret:(NSString *)consumerSecret
          permissions:(NSArray *)permissions
             redirect:(NSString *)redirectAddress
     requestTokenPath:(NSString *)requestTokenPath
        authorizePath:(NSString *)authorizePath
      accessTokenPath:(NSString *)accessTokenPath;

/**
 Adds necessary auth headers for the request and signs requests body
 
 @param request Request to sign
 @param body POST/PUT requests body to sign
 */
- (void)signRequest:(NSMutableURLRequest *)request withBody:(NSMutableDictionary*)body;

/**
 Creates OAuth 1.x signed `AFHTTPRequestOperation` with a `GET` request, and enqueues it to the HTTP client's operation queue.
 
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded and appended as the query string for the request URL.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 */
- (void)signedGetPath:(NSString *)path
           parameters:(NSDictionary *)parameters
              success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates OAuth 1.x `AFHTTPRequestOperation` with a `POST` request, and enqueues it to the HTTP client's operation queue.
 
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 */
- (void)signedPostPath:(NSString *)path
            parameters:(NSDictionary *)parameters
               success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end
