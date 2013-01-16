//
//  TWClient.m
//  cska
//
//  Created by Arthur Evstifeev on 2/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TWClient.h"

#import <CommonCrypto/CommonHMAC.h>

#import "TTAlert.h"
#import "NSString+Additions.h"
#import "NSData+Base64.h"

@interface TWClient () {    
    NSMutableDictionary *_oAuthValues;
    NSString *_accessTokenSecret;
    NSString *_verifier;
    
    NSString *_consumerKey;
    NSString *_consumerSecret;
    NSString *_redirectString;
}
@end

@implementation TWClient
static NSString *serverUrl = @"https://api.twitter.com/oauth/authorize?oauth_token=";

static NSString *oauthVersion = @"1.0";
static NSString *oauthSignatureMethodName = @"HMAC-SHA1";

static NSString *accessTokenKey = @"TWAccessTokenKey";
static NSString *accessTokenSecretKey = @"TWAccessTokenKeySecret";
static NSString *expirationDateKey = @"TWExpirationDateKey";

- (id)initWithKey:(NSString *)consumerKey
           secret:(NSString *)consumerSecret
      andRedirect:(NSString *)redirectString {
    self = [super init];
    if (self) {
        _consumerKey = consumerKey;
        _consumerSecret = consumerSecret;
        _redirectString = redirectString;
        
        _accessTokenSecret = nil;
    }
    return self;
}

- (void)dealloc {
    [_oAuthValues release];
    [super dealloc];
}

#pragma mark - Common Twitter methods

- (void)fillTokenWithResponseBody:(NSString *)body {
    NSArray *pairs = [body componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [elements objectAtIndex:0];
        NSString *value = [[elements objectAtIndex:1] urlDecodedString];
        
        if ([key isEqualToString:@"oauth_token"]) {
            self.accessToken = value;
            [_oAuthValues setValue:value forKey:@"oauth_token"];
        } else if ([key isEqualToString:@"oauth_token_secret"]) {
            _accessTokenSecret = [value copy];
        } else if ([key isEqualToString:@"oauth_verifier"]) {
            _verifier = [value copy];
        }
    }    
}

- (void)setOAuthValue:(NSString *)value forKey:(NSString *)key {
    if (value) {
        [_oAuthValues setObject:value forKey:key];
    } else {
        [_oAuthValues setObject:@"" forKey:key];
    }
}

- (NSString *)signatureBaseStringForRequest:(NSMutableURLRequest *)request
                                   withBody:(NSMutableDictionary *)body {
    NSMutableArray *parameters = [NSMutableArray array];
    NSURL *url = request.URL;
    
    // Get the base URL String (with no parameters)
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"?#"];
    NSArray *urlParts = [url.absoluteString componentsSeparatedByCharactersInSet:characterSet];
    NSString *baseURL = [urlParts objectAtIndex:0];
    
    // Add parameters from the query string
    NSArray *pairs = [url.query componentsSeparatedByString:@"&"];
    [pairs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *elements = [obj componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] urlEncodedString];
        NSString *value = (elements.count > 1 ?
                           [[elements objectAtIndex:1] urlEncodedString] : @"");
        
        [parameters addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                               key, @"key",
                               value, @"value",
                               nil]];
    }];        
    
    // Add parameters from the request body
    [body enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [parameters addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                               [key urlEncodedString], @"key",
                               [obj urlEncodedString], @"value",
                               nil]];
    }];
    
    // Add parameters from the OAuth header
    [_oAuthValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key hasPrefix:@"oauth_"]  &&
            ![key isEqualToString:@"oauth_signature"] &&
            obj && ![obj isEqualToString:@""]) {
            [parameters addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                   [key urlEncodedString], @"key",
                                   [obj urlEncodedString], @"value",
                                   nil]];
        }
    }];
    
    // Sort by name and value
    [parameters sortUsingComparator:^(id obj1, id obj2) {
        NSDictionary *val1 = obj1, *val2 = obj2;
        NSComparisonResult result =
            [[val1 objectForKey:@"key"]compare:[val2 objectForKey:@"key"]
                                       options:NSLiteralSearch];
        if (result != NSOrderedSame) return result;
        return [[val1 objectForKey:@"value"] compare:[val2 objectForKey:@"value"]
                                             options:NSLiteralSearch];
    }];
    
    // Join sorted components
    NSMutableArray *normalizedParameters = [NSMutableArray array];
    [parameters enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [normalizedParameters addObject:[NSString stringWithFormat:@"%@=%@",
                                         [obj objectForKey:@"key"],
                                         [obj objectForKey:@"value"]]];
    }];
    
    // Create the signature base string
    NSString *normParams =
        [[normalizedParameters componentsJoinedByString:@"&"] urlEncodedString];
    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",
                                     [[request HTTPMethod] uppercaseString],
                                     [baseURL urlEncodedString],
                                     normParams];    
    return signatureBaseString;
}

- (NSString *)generatePlaintextSignatureFor:(NSString *)baseString {
    return [NSString stringWithFormat:@"%@&%@", 
            _consumerSecret != nil ? [_consumerSecret urlEncodedString] : @"", 
            _accessTokenSecret != nil ? [_accessTokenSecret urlEncodedString] : @""];
}

- (NSString *)generateHMAC_SHA1SignatureFor:(NSString *)baseString {
    NSString *key = [self generatePlaintextSignatureFor:baseString];
    
    const char *keyBytes = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *baseStringBytes = [baseString cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char digestBytes[CC_SHA1_DIGEST_LENGTH];
    
	CCHmacContext ctx;
    CCHmacInit(&ctx, kCCHmacAlgSHA1, keyBytes, strlen(keyBytes));
	CCHmacUpdate(&ctx, baseStringBytes, strlen(baseStringBytes));
	CCHmacFinal(&ctx, digestBytes);
    
	NSData *digestData = [NSData dataWithBytes:digestBytes length:CC_SHA1_DIGEST_LENGTH];
    return [digestData base64EncodedString];
}

- (void)signRequest:(NSMutableURLRequest *)request withBody:(NSMutableDictionary*)body {    
    // Generate timestamp and nonce values
    [self setOAuthValue:[NSString stringWithFormat:@"%ld", time(NULL)]
                 forKey:@"oauth_timestamp"];
    [self setOAuthValue:[NSString uniqueString] forKey:@"oauth_nonce"];
    
    // Construct the signature base string
    NSString *baseString = [self signatureBaseStringForRequest:request withBody:body];
    
    // Generate the signature
    [self setOAuthValue:[self generateHMAC_SHA1SignatureFor:baseString]
                 forKey:@"oauth_signature"];
    
    NSMutableArray *oauthHeaders = [NSMutableArray array];    
    // Fill the authorization header array
    [_oAuthValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (obj && ![obj isEqualToString:@""]) {
            [oauthHeaders addObject:[NSString stringWithFormat:@"%@=\"%@\"",
                                     [key urlEncodedString], [obj urlEncodedString]]];
        }
    }];
    
    // Set the Authorization header
    NSString *oauthData = [NSString stringWithFormat:@"OAuth %@",
                           [oauthHeaders componentsJoinedByString:@", "]];
    NSDictionary *oauthHeader = [NSDictionary dictionaryWithObjectsAndKeys:
                                 oauthData, @"Authorization", nil];
    
    // Add the Authorization header to the request
    [oauthHeader enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [request addValue:obj forHTTPHeaderField:key];
    }];
        
    NSMutableArray *bodyFields = [NSMutableArray array];
    [body enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (obj && ![obj isEqualToString:@""]) {
            [bodyFields addObject:[NSString stringWithFormat:@"%@=%@",
                                   [key urlEncodedString], [obj urlEncodedString]]];
        }
    }];
    
    NSString *bodyString = [bodyFields componentsJoinedByString:@"&"];
    NSData *requestBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:requestBody];
}

#pragma mark - Twitter oauth flow
- (void)getRequestToken {
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
        
    [self setOAuthValue:_redirectString forKey:@"oauth_callback"];
    [self signRequest:request withBody:nil];
        
    [SNClient processRequest:request success:^(AFHTTPRequestOperation *operation) {
        [self fillTokenWithResponseBody:[operation responseString]];
        //open webview
        NSString *urlString = [NSString stringWithFormat:@"%@%@", serverUrl,
                               [_oAuthValues objectForKey:@"oauth_token"]];
        
        if (self.delegate) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate client:self showAuthPage:urlString];
            });                
        }
    } failed:nil];
}

- (void)getAccessToken {
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    [body setValue:_verifier forKey:@"oauth_verifier"];     
    
    [self setOAuthValue:nil forKey:@"oauth_callback"];
    [self signRequest:request withBody:body];
    
    [SNClient processRequest:request success:^(AFHTTPRequestOperation *operation) {
        [self fillTokenWithResponseBody:[operation responseString]];            
        NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
        [tokens setValue:self.accessToken forKey:accessTokenKey];
        [tokens setValue:_accessTokenSecret forKey:accessTokenSecretKey];    
        [self saveToken:tokens];
        
        if (self.delegate)
            [self.delegate clientDidLogin:self];
    } failed:nil];
}

- (void)regainToken:(NSDictionary *)savedKeysAndValues {
    self.accessToken = [savedKeysAndValues valueForKey:accessTokenKey];
    _accessTokenSecret = [savedKeysAndValues valueForKey:accessTokenSecretKey];
    
    if (_oAuthValues) {
        [_oAuthValues release];
    }
    
    _oAuthValues = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                     oauthVersion, @"oauth_version",
                     oauthSignatureMethodName, @"oauth_signature_method",
                     _consumerKey, @"oauth_consumer_key",
                     self.accessToken, @"oauth_token",
                     @"", @"oauth_verifier",
                     @"", @"oauth_callback",
                     @"", @"oauth_signature",
                     @"", @"oauth_timestamp",
                     @"", @"oauth_nonce",
                     @"", @"realm",
                     nil] retain];
}

- (void)doLoginWorkflow {    
    if (!_oAuthValues)
        _oAuthValues = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                        oauthVersion, @"oauth_version",
                        oauthSignatureMethodName, @"oauth_signature_method",
                        _consumerKey, @"oauth_consumer_key",
                        @"", @"oauth_token",
                        @"", @"oauth_verifier",
                        @"", @"oauth_callback",
                        @"", @"oauth_signature",
                        @"", @"oauth_timestamp",
                        @"", @"oauth_nonce",
                        @"", @"realm",
                        nil] retain];
    
    [self getRequestToken];
}

- (BOOL)processWebViewResult:(NSURL *)processUrl {
    NSString* url = processUrl.absoluteString;
    
    NSRange search = [url rangeOfString:[NSString stringWithFormat:@"%@?", _redirectString]];
    if (search.location != NSNotFound) {
        [self fillTokenWithResponseBody:url];
        [self getAccessToken];
        
        return YES;
    }
    
    return NO;
}

#pragma mark - Public methods
- (BOOL)isSessionValid {
    return self.accessToken != nil && _accessTokenSecret != nil;
}

- (void)shareLink:(NSString *)link withTitle:(NSString *)title andMessage:(NSString *)message {
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/update.json"];    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    NSString *status = [NSString stringWithFormat:@"%@ %@", message, link];
    [body setValue:status forKey:@"status"];             
    
    [self signRequest:request withBody:body];
    
    [SNClient processRequest:request success:^(AFHTTPRequestOperation *operation) {
        [TTAlert composeAlertViewWithTitle:@""
                                andMessage:NSLocalizedString(@"Ссылка успешно добавлена", nil)];
    } failed:^(NSError *error) {
        NSString *message = NSLocalizedString(@"К сожалению произошла ошибка", nil);
        [TTAlert composeAlertViewWithTitle:@""
                                andMessage:message];
    }];
}

@end
