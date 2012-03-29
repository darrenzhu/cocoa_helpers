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
#import "AFHTTPRequestOperation.h"
#import "NSString+Additions.h"
#import "NSData+Base64.h"

@implementation TWClient

static NSString* serverUrl = @"https://api.twitter.com/oauth/authorize?oauth_token=";
static NSString* redirectUrl = @"rstwitterengine://auth_token";

static NSString* consumerKey = @"fVprggQkOYWNGZNmnu6bjA";
static NSString* consumerSecret = @"r4unocIWkFtHzFM9tKFVmY2nKoC4ssabTD1bfpNk";

static NSString* oauthVersion = @"1.0";
static NSString* oauthSignatureMethodName = @"HMAC-SHA1";

+ (TWClient*)sharedClient {
    static TWClient* _sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] init];                                               
    });
    
    return _sharedClient;
}

+ (NSString*)redirecUrl {
    return redirectUrl;
}

- (void)requestWebView:(NSString*)urlString {
    if (self.delegate)
        [self.delegate client:self showAuthPage:urlString];
}

#pragma mark - Common Twitter methods

- (void)fillTokenWithResponseBody:(NSString *)body {
    NSArray *pairs = [body componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs)
    {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [elements objectAtIndex:0];
        NSString *value = [[elements objectAtIndex:1] urlDecodedString];
        
        if ([key isEqualToString:@"oauth_token"]) {
            _accessToken = value;
            [_oAuthValues setValue:value forKey:@"oauth_token"];
        } else if ([key isEqualToString:@"oauth_token_secret"]) {
            _accessTokenSecret = value;
        } else if ([key isEqualToString:@"oauth_verifier"]) {
            _verifier = value;
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

- (NSString *)signatureBaseStringForRequest:(NSMutableURLRequest *)request withBody:(NSMutableDictionary*)body {
    NSMutableArray *parameters = [NSMutableArray array];
    NSURL *url = request.URL;
    
    // Get the base URL String (with no parameters)
    NSArray *urlParts = [url.absoluteString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"?#"]];
    NSString *baseURL = [urlParts objectAtIndex:0];
    
    // Add parameters from the query string
    NSArray *pairs = [url.query componentsSeparatedByString:@"&"];
    [pairs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *elements = [obj componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] urlEncodedString];
        NSString *value = (elements.count > 1) ? [[elements objectAtIndex:1] urlEncodedString] : @"";
        
        [parameters addObject:[NSDictionary dictionaryWithObjectsAndKeys:key, @"key", value, @"value", nil]];
    }];        
    
    // Add parameters from the request body
    [body enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [parameters addObject:[NSDictionary dictionaryWithObjectsAndKeys:[key urlEncodedString], @"key", [obj urlEncodedString], @"value", nil]];
    }];
    
    // Add parameters from the OAuth header
    [_oAuthValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key hasPrefix:@"oauth_"]  && ![key isEqualToString:@"oauth_signature"] && obj && ![obj isEqualToString:@""]) {
            [parameters addObject:[NSDictionary dictionaryWithObjectsAndKeys:[key urlEncodedString], @"key", [obj urlEncodedString], @"value", nil]];
        }
    }];
    
    // Sort by name and value
    [parameters sortUsingComparator:^(id obj1, id obj2) {
        NSDictionary *val1 = obj1, *val2 = obj2;
        NSComparisonResult result = [[val1 objectForKey:@"key"] compare:[val2 objectForKey:@"key"] options:NSLiteralSearch];
        if (result != NSOrderedSame) return result;
        return [[val1 objectForKey:@"value"] compare:[val2 objectForKey:@"value"] options:NSLiteralSearch];
    }];
    
    // Join sorted components
    NSMutableArray *normalizedParameters = [NSMutableArray array];
    [parameters enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [normalizedParameters addObject:[NSString stringWithFormat:@"%@=%@", [obj objectForKey:@"key"], [obj objectForKey:@"value"]]];
    }];
    
    // Create the signature base string
    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",
                                     [[request HTTPMethod] uppercaseString],
                                     [baseURL urlEncodedString],
                                     [[normalizedParameters componentsJoinedByString:@"&"] urlEncodedString]];
    
    return signatureBaseString;
}

- (NSString *)generatePlaintextSignatureFor:(NSString *)baseString {
    return [NSString stringWithFormat:@"%@&%@", 
            consumerSecret != nil ? [consumerSecret urlEncodedString] : @"", 
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
    [self setOAuthValue:[NSString stringWithFormat:@"%d", time(NULL)] forKey:@"oauth_timestamp"];
    [self setOAuthValue:[NSString uniqueString] forKey:@"oauth_nonce"];
    
    // Construct the signature base string
    NSString *baseString = [self signatureBaseStringForRequest:request withBody:body];
    
    // Generate the signature
    [self setOAuthValue:[self generateHMAC_SHA1SignatureFor:baseString] forKey:@"oauth_signature"];
    
    NSMutableArray *oauthHeaders = [NSMutableArray array];
    
    // Fill the authorization header array
    [_oAuthValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (obj && ![obj isEqualToString:@""]) {
            [oauthHeaders addObject:[NSString stringWithFormat:@"%@=\"%@\"", [key urlEncodedString], [obj urlEncodedString]]];
        }
    }];
    
    // Set the Authorization header
    NSString *oauthData = [NSString stringWithFormat:@"OAuth %@", [oauthHeaders componentsJoinedByString:@", "]];
    NSDictionary *oauthHeader = [NSDictionary dictionaryWithObjectsAndKeys:oauthData, @"Authorization", nil];    
    
    // Add the Authorization header to the request
    [oauthHeader enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [request addValue:obj forHTTPHeaderField:key];
    }];
        
    NSMutableArray *bodyFields = [NSMutableArray array];
    [body enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (obj && ![obj isEqualToString:@""]) {
            [bodyFields addObject:[NSString stringWithFormat:@"%@=%@", [key urlEncodedString], [obj urlEncodedString]]];
        }
    }];
    
    NSString* bodyString = [bodyFields componentsJoinedByString:@"&"];
    NSData *requestBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:requestBody];
}

#pragma mark - Twitter oauth flow

- (void)getRequestToken {
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
        
    [self setOAuthValue:redirectUrl forKey:@"oauth_callback"];
    [self signRequest:request withBody:nil];
        
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    AFHTTPRequestOperation *_operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    __unsafe_unretained AFHTTPRequestOperation *operation = _operation;
    operation.completionBlock = ^ {
        if ([operation hasAcceptableStatusCode]) {
            
            [self fillTokenWithResponseBody:[operation responseString]];
            //open webview
            NSString* urlString = [NSString stringWithFormat:@"%@%@", serverUrl, [_oAuthValues objectForKey:@"oauth_token"]];
             
            [self performSelectorOnMainThread:@selector(requestWebView:) withObject:urlString waitUntilDone:NO];
                        
        } else {
            NSLog(@"Error: %@, %@", operation.error, operation.responseString);
        }
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    };
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation]; 
}

- (void)getAccessToken {
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSMutableDictionary* body = [NSMutableDictionary dictionary];
    [body setValue:_verifier forKey:@"oauth_verifier"];     
    
    [self setOAuthValue:nil forKey:@"oauth_callback"];
    [self signRequest:request withBody:body];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    AFHTTPRequestOperation *_operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    __unsafe_unretained AFHTTPRequestOperation *operation = _operation;
    operation.completionBlock = ^ {
        if ([operation hasAcceptableStatusCode]) {
            
            [self fillTokenWithResponseBody:[operation responseString]];            
            [self saveToken];
            
            if (_delegate)
                [_delegate clientDidLogin:self];
            
        } else {
            NSLog(@"Error: %@, %@", operation.error, operation.responseString);
        }
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    };
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

#pragma mark - Public methods

- (NSString *)accessTokenKey {
    return @"TWAccessTokenKey";
}

- (NSString *)expirationDateKey {
    return @"TWExpirationDateKey";
}

- (void)login {
    [super login];
    
    
    if (![self isSessionValid]) {
        
        _oAuthValues = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        oauthVersion, @"oauth_version",
                        oauthSignatureMethodName, @"oauth_signature_method",
                        consumerKey, @"oauth_consumer_key",
                        @"", @"oauth_token",
                        @"", @"oauth_verifier",
                        @"", @"oauth_callback",
                        @"", @"oauth_signature",
                        @"", @"oauth_timestamp",
                        @"", @"oauth_nonce",
                        @"", @"realm",
                        nil];
        
        //get request token
        [self getRequestToken];        
    } 
    else {
        
        _oAuthValues = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        oauthVersion, @"oauth_version",
                        oauthSignatureMethodName, @"oauth_signature_method",
                        consumerKey, @"oauth_consumer_key",
                        _accessToken, @"oauth_token",
                        @"", @"oauth_verifier",
                        @"", @"oauth_callback",
                        @"", @"oauth_signature",
                        @"", @"oauth_timestamp",
                        @"", @"oauth_nonce",
                        @"", @"realm",
                        nil];
        
    }
}

- (void)parseUrl:(NSString *)url {
    [self fillTokenWithResponseBody:url];
    [self getAccessToken];
}

- (void)share:(CCNews *)_news andMessage:(NSString *)message {
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/update.json"];    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSMutableDictionary* body = [NSMutableDictionary dictionary];
    NSString* status = [NSString stringWithFormat:@"%@ %@", message, 
                        [NSString stringWithFormat:@"http://www.cskabasket.com/news/?id=%i", _news.id.intValue]];
    [body setValue:status forKey:@"status"];             
    
    [self signRequest:request withBody:body];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    AFHTTPRequestOperation *_operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    __unsafe_unretained AFHTTPRequestOperation *operation = _operation;
    operation.completionBlock = ^ {
        if ([operation hasAcceptableStatusCode]) {
            
            [TTAlert composeAlertViewWithTitle:@"" andMessage:@"Ссылка успешно добавлена"];       
            
        } else {
            [TTAlert composeAlertViewWithTitle:@"" andMessage:@"К сожалению произошла ошибка"];
            NSLog(@"Error: %@, %@", operation.error, operation.responseString);
        }
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    };
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

@end
