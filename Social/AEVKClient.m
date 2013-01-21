//
// VKClient.m
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

#import "AEVKClient.h"
#import "NSString+Additions.h"

@interface AEVKClient ()
@property (copy, nonatomic) NSString *clientId;
@property (copy, nonatomic) NSString *redirectString;
@property (copy, nonatomic) NSArray *scope;
@end

@implementation AEVKClient
static NSString * const baseUrl = @"http://api.vk.com";

static NSString * const accessTokenKey = @"VKAccessTokenKey";
static NSString * const expirationDateKey = @"VKExpirationDateKey";

- (id)initWithId:(NSString *)consumerKey scope:(NSArray *)scope redirectUrlString:(NSString *)redirectString {
    
    self = [super init];
    if (self) {
        self.clientId       = consumerKey;
        self.redirectString = redirectString;
        self.scope          = scope;
    }
    return self;
}

- (void)dealloc {
    [_clientId release];
    [_redirectString release];
    [_scope release];
    [super dealloc];
}

#pragma mark - overrides
- (void)regainToken:(NSDictionary *)savedKeysAndValues {
    self.accessToken = [savedKeysAndValues valueForKey:accessTokenKey];
    self.expirationDate = [savedKeysAndValues valueForKey:expirationDateKey];
}

- (void)doLoginWorkflow {    
    NSString *requestTokenPath = [NSString stringWithFormat:@"%@/oauth/authorize", baseUrl];
    requestTokenPath           = [requestTokenPath stringByAppendingFormat:@"?client_id=%@&scope=%@&redirect_uri=%@",
                                  _clientId, [_scope componentsJoinedByString:@","], _redirectString];
    requestTokenPath           = [requestTokenPath stringByAppendingString:@"&display=touch&response_type=token"];
    
    if (self.delegate) {
        [self.delegate client:self wantsPresentAuthPage:[NSURL URLWithString:requestTokenPath]];
    }
}

- (BOOL)processWebViewResult:(NSURL *)processUrl {    
    NSString *absoluteString    = processUrl.absoluteString;
    NSRange redirectStringRange = [absoluteString rangeOfString:[NSString stringWithFormat:@"%@#", _redirectString]];
    
    if (redirectStringRange.location != NSNotFound) {
        NSRegularExpression *regex;
        NSTextCheckingResult *checkingResult;
        NSString *token, *expires;
        
        regex               = [NSRegularExpression regularExpressionWithPattern:@"access_token=[^&?]+"
                                                                        options:0
                                                                          error:nil];
        checkingResult      = [regex firstMatchInString:absoluteString
                                                options:0
                                                  range:NSMakeRange(0, absoluteString.length)];
        
        token               = [absoluteString substringWithRange:checkingResult.range];
        self.accessToken    = [token stringByReplacingOccurrencesOfString:@"access_token="
                                                               withString:@""];
        
        regex               = [NSRegularExpression regularExpressionWithPattern:@"expires_in=[^&?]+"
                                                                        options:0
                                                                          error:nil];
        checkingResult      = [regex firstMatchInString:absoluteString
                                                options:0
                                                  range:NSMakeRange(0, absoluteString.length)];
        
        expires             = [absoluteString substringWithRange:checkingResult.range];
        expires             = [expires stringByReplacingOccurrencesOfString:@"expires_in=" withString:@""];
        
        NSNumberFormatter *f            = [[[NSNumberFormatter alloc] init] autorelease];
        NSInteger timeInterval          = [f numberFromString:expires].integerValue;
        self.expirationDate             = [[NSDate date] dateByAddingTimeInterval:timeInterval];
        
        NSMutableDictionary *tokens     = [NSMutableDictionary dictionary];
        [tokens setValue:self.accessToken forKey:accessTokenKey];
        [tokens setValue:self.expirationDate forKey:expirationDateKey];
        [self saveToken:tokens];
        
        if (self.delegate) {
            [self.delegate clientDidLogin:self];
        }
        
        return YES;
    }
    
    return NO;
}

- (void)shareLink:(NSString *)link
        withTitle:(NSString *)title
       andMessage:(NSString *)message
          success:(void (^)())success
          failure:(void (^)(NSError *))failure {

    NSString *sharePath = [NSString stringWithFormat:@"%@/method/wall.post", baseUrl];
    sharePath           = [sharePath stringByAppendingFormat:@"?attachments=%@&access_token=%@&message=%@",
                           link, self.accessToken, [message urlEncodedString]];
    
    NSURL *shareUrl                 = [NSURL URLWithString:sharePath];
    NSMutableURLRequest *request    = [NSMutableURLRequest requestWithURL:shareUrl];

    [AESNClient processJsonRequest:request success:success failure:failure];
}

@end
