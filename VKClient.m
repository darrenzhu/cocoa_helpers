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
static NSString* scope = @"wall";

static NSString* accessTokenKey = @"VKAccessTokenKey";
static NSString* expirationDateKey = @"VKExpirationDateKey";

static NSString* shareLinkMethodUrl = @"https://api.vk.com/method/wall.post?attachments=%@i&access_token=%@&message=%@";

@implementation VKClient

- (id)initWithId:(NSString*)consumerKey            
     andRedirect:(NSString*)redirectString {
    self = [super init];
    if (self) {
        _clientId = consumerKey;
        _redirectString = redirectString;
    }
    return self;
}

- (void)regainToken:(NSDictionary *)savedKeysAndValues {
    _accessToken = [savedKeysAndValues valueForKey:accessTokenKey];
    _expirationDate = [savedKeysAndValues valueForKey:expirationDateKey];
}

- (void)doLoginWorkflow {
    NSString* urlString = [NSString stringWithFormat:@"%@client_id=%@&scope=%@&redirect_uri=%@&display=touch&response_type=token", serverUrl, _clientId, scope, _redirectString];
    
    if (self.delegate)
        [self.delegate client:self showAuthPage:urlString];
}

- (void)shareLink:(NSString *)link withTitle:(NSString *)title andMessage:(NSString *)message {

    NSString* urlString = 
        [NSString stringWithFormat:shareLinkMethodUrl, link, self.accessToken, [message urlEncodedString]];
    
    NSURL* url = [NSURL URLWithString:urlString];    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    
    [[NetworkIndicatorManager defaultManager] setNetworkIndicatorState:YES];
    AFJSONRequestOperation* operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        if ([JSON valueForKeyPath:@"response"]) {
            [TTAlert composeAlertViewWithTitle:@"" andMessage:@"Ссылка успешно добавлена"];
        }
        else {
            [TTAlert composeAlertViewWithTitle:@"" andMessage:@"К сожалению произошла ошибка"];
            NSLog(@"response %@", JSON);
        }
        
        [[NetworkIndicatorManager defaultManager] setNetworkIndicatorState:NO];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        [TTAlert composeAlertViewWithTitle:@"" andMessage:@"К сожалению произошла ошибка"];
        NSLog(@"Error %@", error);
        [[NetworkIndicatorManager defaultManager] setNetworkIndicatorState:NO];        
    }];
    
    [operation start];
}

- (BOOL)processWebViewResult:(NSURL *)processUrl {
    NSString* url = processUrl.absoluteString;
    
    if ([url rangeOfString:[NSString stringWithFormat:@"%@#", _redirectString]].location != NSNotFound) {
        NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"access_token=[^&?]+" options:0 error:nil];
        NSString* token = [url substringWithRange:[regex firstMatchInString:url options:0 range:NSMakeRange(0, url.length)].range];
        _accessToken = [token stringByReplacingOccurrencesOfString:@"access_token=" withString:@""];
        
        regex = [NSRegularExpression regularExpressionWithPattern:@"expires_in=[^&?]+" options:0 error:nil];
        NSString* expires = [url substringWithRange:[regex firstMatchInString:url options:0 range:NSMakeRange(0, url.length)].range];
        expires = [expires stringByReplacingOccurrencesOfString:@"expires_in=" withString:@""];
        NSNumberFormatter* f = [[[NSNumberFormatter alloc] init] autorelease];    
        _expirationDate = [[NSDate date] dateByAddingTimeInterval:[f numberFromString:expires].integerValue];
        
        NSMutableDictionary* tokens = [NSMutableDictionary dictionary];
        [tokens setValue:_accessToken forKey:accessTokenKey];
        [tokens setValue:_expirationDate forKey:expirationDateKey];
        [self saveToken:tokens];    
        
        if (_delegate)
            [_delegate clientDidLogin:self];
        
        return YES;
    }
    
    return NO;
}


@end
