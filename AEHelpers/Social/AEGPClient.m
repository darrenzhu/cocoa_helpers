//
// AEGPClient.m
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

#import "AEGPClient.h"

@interface AEGPClient ()
@property (copy, nonatomic) NSString *clientID;
@property (copy, nonatomic) NSString *languageCode;
@property (copy, nonatomic) NSArray *scope;

@property (retain, nonatomic) NSString *redirectUrlString;
@end

@implementation AEGPClient

static NSString * const baseUrl                = @"https://accounts.google.com/o/oauth2";
static NSString * const plusBaseUrl            = @"https://www.googleapis.com/plus/v1";
static NSString * const gpAccessTokenSaveKey   = @"GPAccessTokenKey";
static NSString * const gpExpireDateSaveKey    = @"GPExpirationDateKey";

static AEGPClient *currentGPClient;
+ (AEGPClient *)currentClient {
    return currentGPClient;
}

- (id)initWithClientID:(NSString *)clientID
              language:(NSString *)language
                 scope:(NSArray *)scope
            bundleName:(NSString *)bundleName {
    self = [super initWithBaseURL:[NSURL URLWithString:plusBaseUrl]];
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
    
    [self getPath:@"people/me"
       parameters:@{ @"access_token": self.accessToken }
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              
              if (success) success(responseObject);
              
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              
              if (failure) failure(error);
          }];
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
    
    AFJSONRequestOperation *operation =
        [AFJSONRequestOperation
         JSONRequestOperationWithRequest:authorizationRequest
         success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
             [self clientDidLoginWithJsonData:JSON];
         } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
             NSLog(@"%@", error);
         }];
    [operation start];
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
