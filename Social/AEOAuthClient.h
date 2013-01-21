//
//  AEOAuthClient.h
//  SNTests
//
//  Created by ap4y on 1/18/13.
//
//

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
