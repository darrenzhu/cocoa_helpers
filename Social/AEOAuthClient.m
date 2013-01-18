//
//  AEOAuthClient.m
//  SNTests
//
//  Created by ap4y on 1/18/13.
//
//

#import "AEOAuthClient.h"
#import <CommonCrypto/CommonHMAC.h>

#import "NSString+Additions.h"
#import "NSData+Base64.h"

@interface AEOAuthClient ()

@property (retain, nonatomic) NSMutableDictionary *oAuthValues;
@property (retain, nonatomic) NSString *accessTokenSecret;
@property (retain, nonatomic) NSString *verifier;

@property (retain, nonatomic) NSString *consumerKey;
@property (retain, nonatomic) NSString *consumerSecret;

@property (retain, nonatomic) NSString *redirectString;

@property (retain, nonatomic) NSURL *baseUrl;
@property (retain, nonatomic) NSString *requestTokenPath;
@property (retain, nonatomic) NSString *authorizePath;
@property (retain, nonatomic) NSString *accessTokenPath;

@property (retain, nonatomic) NSArray *permissions;
@end

@implementation AEOAuthClient

static NSString * const oauthVersion = @"1.0";
static NSString * const oauthSignatureMethodName = @"HMAC-SHA1";

- (id)initWithBaseUrl:(NSURL *)baseUrl
                  key:(NSString *)consumerKey
               secret:(NSString *)consumerSecret
          permissions:(NSArray *)permissions
             redirect:(NSString *)redirectAddress
     requestTokenPath:(NSString *)requestTokenPath
        authorizePath:(NSString *)authorizePath
      accessTokenPath:(NSString *)accessTokenPath {
    
    self = [super init];
    if (self) {
        self.consumerKey = consumerKey;
        self.consumerSecret = consumerSecret;
        self.redirectString = redirectAddress;
        
        self.permissions = permissions;
        
        self.baseUrl = baseUrl;
        self.requestTokenPath = requestTokenPath;
        self.authorizePath = authorizePath;
        self.accessTokenPath = accessTokenPath;
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        _accessTokenSecret = nil;
    }
    return self;
}

- (void)dealloc {
    [_oAuthValues release];
    [_redirectString release];
    [_consumerKey release];
    [_consumerSecret release];
    [_verifier release];
    [_accessTokenSecret release];
    [_baseUrl release];
    [_requestTokenPath release];
    [_authorizePath release];
    [_accessTokenPath release];
    [_permissions release];
    [super dealloc];
}

#pragma mark - token saving
- (NSString *)accessTokenKey {
    return @"AEAccessTokenKey";
}

- (NSString *)accessTokenSecretKey {
    return @"AEAccessTokenKeySecret";
}

#pragma mark - overloading
- (BOOL)isSessionValid {
    return self.accessToken != nil && self.accessTokenSecret != nil;
}

- (void)regainToken:(NSDictionary *)savedKeysAndValues {
    self.accessToken = [savedKeysAndValues valueForKey:[self accessTokenKey]];
    self.accessTokenSecret = [savedKeysAndValues valueForKey:[self accessTokenSecretKey]];

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
    if (!_oAuthValues) {
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
    }
    
    [self getRequestToken];
}

- (BOOL)processWebViewResult:(NSURL *)processUrl {
    NSString *url = processUrl.absoluteString;
    NSLog(@"%@", url);
    
    NSString *searchedString = [NSString stringWithFormat:@"%@?", _redirectString];
    NSRange search = [url rangeOfString:searchedString];
    if (search.location != NSNotFound) {
        [self fillTokenWithResponseBody:[url stringByReplacingOccurrencesOfString:searchedString withString:@""]];
        [self getAccessToken];
        
        return YES;
    }
    
    return NO;
}

#pragma mark - Common OAuth methods
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

#pragma mark - OAuth implementation

- (void)getRequestToken {
    NSString *urlString = [[_baseUrl absoluteString] stringByAppendingString:@"/"];
    urlString = [urlString stringByAppendingString:_requestTokenPath];
    if (_permissions) {
        urlString = [urlString stringByAppendingFormat:@"?scope=%@", [_permissions componentsJoinedByString:@","]];
    }

    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    [self setOAuthValue:_redirectString forKey:@"oauth_callback"];
    [self signRequest:request withBody:nil];
    
    [AESNClient processRequest:request success:^(AFHTTPRequestOperation *operation) {
        [self fillTokenWithResponseBody:[operation responseString]];
        //open webview
        NSString *authorizePath = [NSString stringWithFormat:@"%@?oauth_token=%@", _authorizePath,
                                   [self.oAuthValues objectForKey:@"oauth_token"]];
        NSURL *authorizeUrl = [_baseUrl URLByAppendingPathComponent:authorizePath];
        
        if (self.delegate) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate client:self wantsPresentAuthPage:authorizeUrl];
            });
        }
    } failure:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (void)getAccessToken {
    NSURL *url = [_baseUrl URLByAppendingPathComponent:_accessTokenPath];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    [body setValue:self.verifier forKey:@"oauth_verifier"];
    
    [self setOAuthValue:nil forKey:@"oauth_callback"];
    [self signRequest:request withBody:body];
    
    [AESNClient processRequest:request success:^(AFHTTPRequestOperation *operation) {
        [self fillTokenWithResponseBody:[operation responseString]];
        
        NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
        [tokens setValue:self.accessToken forKey:[self accessTokenKey]];
        [tokens setValue:self.accessTokenSecret forKey:[self accessTokenSecretKey]];
        [self saveToken:tokens];
        
        if (self.delegate) {
            [self.delegate clientDidLogin:self];
        }
    } failure:nil];
}

@end
