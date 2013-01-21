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
#import "AFJSONRequestOperation.h"

@interface AEVKClient () {
    NSString *_clientId;
    NSString *_redirectString;
}
@end

@implementation AEVKClient
static NSString *serverUrl = @"http://api.vk.com/oauth/authorize?";
static NSString *scope = @"wall";

static NSString *accessTokenKey = @"VKAccessTokenKey";
static NSString *expirationDateKey = @"VKExpirationDateKey";

static NSString *shareLinkMethodUrl =
    @"https://api.vk.com/method/wall.post?attachments=%@&access_token=%@&message=%@";


- (id)initWithId:(NSString *)consumerKey
     andRedirect:(NSString *)redirectString {
    self = [super init];
    if (self) {
        _clientId = consumerKey;
        _redirectString = redirectString;
    }
    return self;
}

- (void)regainToken:(NSDictionary *)savedKeysAndValues {
    self.accessToken = [savedKeysAndValues valueForKey:accessTokenKey];
    self.expirationDate = [savedKeysAndValues valueForKey:expirationDateKey];
}

- (void)doLoginWorkflow {
    NSString* urlString = [NSString stringWithFormat:@"%@client_id=%@&scope=%@&redirect_uri=%@&display=touch&response_type=token", serverUrl, _clientId, scope, _redirectString];
    
    if (self.delegate) {
        [self.delegate client:self wantsPresentAuthPage:[NSURL URLWithString:urlString]];
    }
}

- (void)shareLink:(NSString *)link withTitle:(NSString *)title andMessage:(NSString *)message {

    NSString *urlString =  [NSString stringWithFormat:shareLinkMethodUrl,
                            link, self.accessToken, [message urlEncodedString]];
    
    NSURL *url = [NSURL URLWithString:urlString];    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    AFJSONRequestOperation *operation =
        [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                        success:^(NSURLRequest *request,
                                                                  NSHTTPURLResponse *response,
                                                                  id JSON) {
        NSLog(@"response %@", JSON);
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Error %@", error);
    }];
    
    [operation start];
}

- (BOOL)processWebViewResult:(NSURL *)processUrl {
    NSString *url = processUrl.absoluteString;
    
    NSRange search = [url rangeOfString:[NSString stringWithFormat:@"%@#", _redirectString]];
    if (search.location != NSNotFound) {
        NSRegularExpression *regex =
            [NSRegularExpression regularExpressionWithPattern:@"access_token=[^&?]+"
                                                      options:0
                                                        error:nil];
        NSTextCheckingResult *result = [regex firstMatchInString:url
                                                         options:0
                                                           range:NSMakeRange(0, url.length)];
        NSString *token = [url substringWithRange:result.range];
        self.accessToken = [token stringByReplacingOccurrencesOfString:@"access_token="
                                                            withString:@""];
        
        regex = [NSRegularExpression regularExpressionWithPattern:@"expires_in=[^&?]+"
                                                          options:0
                                                            error:nil];
        result = [regex firstMatchInString:url options:0 range:NSMakeRange(0, url.length)];
        NSString *expires = [url substringWithRange:result.range];
        expires = [expires stringByReplacingOccurrencesOfString:@"expires_in=" withString:@""];
        NSNumberFormatter *f = [[[NSNumberFormatter alloc] init] autorelease];
        NSInteger timeInterval = [f numberFromString:expires].integerValue;
        self.expirationDate = [[NSDate date] dateByAddingTimeInterval:timeInterval];
        
        NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
        [tokens setValue:self.accessToken forKey:accessTokenKey];
        [tokens setValue:self.expirationDate forKey:expirationDateKey];
        [self saveToken:tokens];    
        
        if (self.delegate)
            [self.delegate clientDidLogin:self];
        
        return YES;
    }
    
    return NO;
}


@end
