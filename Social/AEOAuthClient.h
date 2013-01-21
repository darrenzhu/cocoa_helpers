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

@end
