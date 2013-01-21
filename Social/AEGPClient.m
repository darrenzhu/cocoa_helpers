//
//  AEGPClient.m
//  SNTests
//
//  Created by ap4y on 1/18/13.
//
//

#import "AEGPClient.h"

@interface AEGPClient ()
@property (copy, nonatomic) NSString *clientID;
@property (copy, nonatomic) NSString *languageCode;
@property (copy, nonatomic) NSArray *scope;

@property (retain, nonatomic) NSString *redirectUrlString;
@end

@implementation AEGPClient

NSString * const baseUrl                = @"https://accounts.google.com/o/oauth2";
NSString * const plusBaseUrl            = @"https://www.googleapis.com/plus/v1";
NSString * const gpAccessTokenSaveKey   = @"GPAccessTokenKey";
NSString * const gpExpireDateSaveKey    = @"GPExpirationDateKey";

static AEGPClient *currentGPClient;
+ (AEGPClient *)currentClient {
    return currentGPClient;
}

- (id)initWithClientID:(NSString *)clientID
              language:(NSString *)language
                 scope:(NSArray *)scope
            bundleName:(NSString *)bundleName {
    self = [super init];
    if (self) {
        
        self.clientID           = clientID;
        self.languageCode       = language;
        self.scope              = scope;
        self.redirectUrlString  = [NSString stringWithFormat:@"%@:/oauth2callback", bundleName];
        
        currentGPClient = self;
    }
    return self;
}

- (void)dealloc {
    [_clientID release];
    [_languageCode release];
    [_scope release];
    
    [super dealloc];
}

- (void)profileInformationWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    NSString *profilePath           = [NSString stringWithFormat:@"%@/people/me?access_token=%@",
                                       plusBaseUrl, self.accessToken];
    NSURL *profileUrl               = [NSURL URLWithString:profilePath];
    NSURLRequest *profileRequest    = [NSURLRequest requestWithURL:profileUrl];
    
    [AESNClient processJsonRequest:profileRequest success:success failure:failure];
}

#pragma mark - overrides

- (void)doLoginWorkflow {
    if (!self.delegate) {
        return;
    }
    
    NSString *codeRequestPath = [NSString stringWithFormat:@"%@/auth?", baseUrl];
    codeRequestPath           = [codeRequestPath stringByAppendingFormat:@"hl=%@&client_id=%@&redirect_uri=%@&scope=%@",
                                 _languageCode,
                                 _clientID,
                                 _redirectUrlString,
                                 [_scope componentsJoinedByString:@","]];
    codeRequestPath           = [codeRequestPath stringByAppendingString:@"&response_type=code"];

    NSURL *codeRequestUrl     = [NSURL URLWithString:codeRequestPath];
    [self.delegate client:self wantsPresentAuthPage:codeRequestUrl];
}

- (BOOL)processWebViewResult:(NSURL *)processUrl {
    NSString *replaced  = [NSString stringWithFormat:@"%@?code=", _redirectUrlString];
    NSString *code      = [[processUrl absoluteString] stringByReplacingOccurrencesOfString:[replaced lowercaseString]
                                                                                 withString:@""];
    [self authorizeRequestedCode:code];
    
    return YES;
}

- (void)regainToken:(NSDictionary *)savedKeysAndValues {
    if ([savedKeysAndValues objectForKey:gpAccessTokenSaveKey] &&
        [savedKeysAndValues objectForKey:gpExpireDateSaveKey]) {
        
        self.accessToken    = [savedKeysAndValues objectForKey:gpAccessTokenSaveKey];
        self.expirationDate = [savedKeysAndValues objectForKey:gpExpireDateSaveKey];
    }
}

#pragma mark - private
- (void)authorizeRequestedCode:(NSString *)code {
    NSString *authorizationPath, *requestBody;
    NSURL *authorizationUrl;
    NSMutableURLRequest *authorizationRequest;
    
    authorizationPath       = [NSString stringWithFormat:@"%@/token", baseUrl];
    authorizationUrl        = [NSURL URLWithString:authorizationPath];
    authorizationRequest    = [NSMutableURLRequest requestWithURL:authorizationUrl];
    requestBody             = [NSString stringWithFormat:@"client_id=%@&code=%@&redirect_uri=%@&scope=%@",
                               _clientID,
                               code,
                               _redirectUrlString,
                               [_scope componentsJoinedByString:@","]];
    requestBody             = [requestBody stringByAppendingString:@"&grant_type=authorization_code"];
    
    [authorizationRequest setHTTPMethod:@"POST"];
    [authorizationRequest setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    [AESNClient processJsonRequest:authorizationRequest success:^(id json) {        
        [self clientDidLoginWithJsonData:json];
    } failure:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (void)clientDidLoginWithJsonData:(id)jsonData {
    NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
    NSNumber *expiresIn         = [jsonData valueForKey:@"expires_in"];
    
    self.accessToken            = [jsonData valueForKey:@"access_token"];
    self.expirationDate         = [NSDate dateWithTimeIntervalSinceNow:[expiresIn doubleValue]];
    
    [tokens setValue:self.accessToken forKey:gpAccessTokenSaveKey];
    [tokens setValue:self.expirationDate forKey:gpExpireDateSaveKey];
    [self saveToken:tokens];
    
    if (self.delegate) {
        [self.delegate clientDidLogin:self];
    }
}

@end
