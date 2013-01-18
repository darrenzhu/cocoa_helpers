//
//  AEOAuthClient.h
//  SNTests
//
//  Created by ap4y on 1/18/13.
//
//

#import "AESNClient.h"

@interface AEOAuthClient : AESNClient

@property (retain, nonatomic, readonly) NSMutableDictionary *oAuthValues;
@property (retain, nonatomic, readonly) NSString *accessTokenSecret;
@property (retain, nonatomic, readonly) NSString *verifier;

- (id)initWithBaseUrl:(NSURL *)baseUrl
                  key:(NSString *)consumerKey
               secret:(NSString *)consumerSecret
          permissions:(NSArray *)permissions
             redirect:(NSString *)redirectAddress
     requestTokenPath:(NSString *)requestTokenPath
        authorizePath:(NSString *)authorizePath
      accessTokenPath:(NSString *)accessTokenPath;

- (void)fillTokenWithResponseBody:(NSString *)body;
- (void)setOAuthValue:(NSString *)value forKey:(NSString *)key;
- (void)signRequest:(NSMutableURLRequest *)request withBody:(NSMutableDictionary*)body;

@end
