//
//  VKClient.m
//  cska
//
//  Created by Arthur Evstifeev on 2/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKClient.h"
#import "TTAlert.h"
#import "NSString+Additions.h"
#import "AFJSONRequestOperation.h"

@interface VKClient () {
    NSString *_clientId;
    NSString *_redirectString;
}
@end

@implementation VKClient
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
    
    if (self.delegate)
        [self.delegate client:self showAuthPage:urlString];
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
        if ([JSON valueForKeyPath:@"response"]) {
            NSString *message = NSLocalizedString(@"Ссылка успешно добавлена", nil);
            [TTAlert composeAlertViewWithTitle:@""
                                    andMessage:message];
        }
        else {
            NSString *message = NSLocalizedString(@"К сожалению произошла ошибка", nil);
            [TTAlert composeAlertViewWithTitle:@""
                                    andMessage:message];
            NSLog(@"response %@", JSON);
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSString *message = NSLocalizedString(@"К сожалению произошла ошибка", nil);
        [TTAlert composeAlertViewWithTitle:@""
                                andMessage:message];
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
