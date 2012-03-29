//
//  VKClient.m
//  cska
//
//  Created by Arthur Evstifeev on 2/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VKClient.h"

#import "TTAlert.h"
#import "AFJSONRequestOperation.h"
#import "NSString+Additions.h"

static NSString* serverUrl = @"http://api.vk.com/oauth/authorize?";
static NSString* clientId = @"2783129";
static NSString* scope = @"wall";
static NSString* redirectUrl = @"http://api.vkontakte.ru/blank.html";

@implementation VKClient

+ (VKClient*)sharedClient {
    static VKClient* _sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] init];                                               
    });
    
    return _sharedClient;
}

+ (NSString*)redirecUrl {
    return redirectUrl;
}

- (NSString *)accessTokenKey {
    return @"VKAccessTokenKey";
}

- (NSString *)expirationDateKey {
    return @"VKExpirationDateKey";
}

- (void)login {
    [super login];
    
    if (![self isSessionValid]) {
        NSString* urlString = [NSString stringWithFormat:@"%@client_id=%@&scope=%@&redirect_uri=%@&display=touch&response_type=token", serverUrl, clientId, scope, redirectUrl];
        
        if (self.delegate)
            [self.delegate client:self showAuthPage:urlString];
    } 
}

- (void)parseUrl:(NSString*)url {
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"access_token=[^&?]+" options:0 error:nil];
    NSString* token = [url substringWithRange:[regex firstMatchInString:url options:0 range:NSMakeRange(0, url.length)].range];
    _accessToken = [token stringByReplacingOccurrencesOfString:@"access_token=" withString:@""];
    
    regex = [NSRegularExpression regularExpressionWithPattern:@"expires_in=[^&?]+" options:0 error:nil];
    NSString* expires = [url substringWithRange:[regex firstMatchInString:url options:0 range:NSMakeRange(0, url.length)].range];
    expires = [expires stringByReplacingOccurrencesOfString:@"expires_in=" withString:@""];
    NSNumberFormatter* f = [[NSNumberFormatter alloc] init];    
    _expirationDate = [[NSDate date] dateByAddingTimeInterval:[f numberFromString:expires].integerValue];
    
    [self saveToken];
    
    if (_delegate)
        [_delegate clientDidLogin:self];
}

- (void)share:(CCNews*)_news andMessage:(NSString *)message {
    
    NSString* urlString = [NSString stringWithFormat:@"https://api.vk.com/method/wall.post?attachments=http://www.cskabasket.com/news/?id=%i&access_token=%@&message=%@", _news.id.intValue, self.accessToken, [message urlEncodedString]];
    NSLog(@"%@", urlString);
    NSURL* url = [NSURL URLWithString:urlString];    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    AFJSONRequestOperation* operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        if ([JSON valueForKeyPath:@"response"]) {
            [TTAlert composeAlertViewWithTitle:@"" andMessage:@"Ссылка успешно добавлена"];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        else {
            [TTAlert composeAlertViewWithTitle:@"" andMessage:@"К сожалению произошла ошибка"];
            NSLog(@"response %@", JSON);
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
        
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        [TTAlert composeAlertViewWithTitle:@"" andMessage:@"К сожалению произошла ошибка"];
        NSLog(@"Error %@", error);
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
    }];
    
    [operation start];
}

@end
