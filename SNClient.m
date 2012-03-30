//
//  SNClient.m
//  cska
//
//  Created by Arthur Evstifeev on 2/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SNClient.h"

@implementation SNClient
@synthesize delegate = _delegate, accessToken = _accessToken;

- (BOOL)isSessionValid {
    return (_accessToken != nil && 
            (_expirationDate != nil && NSOrderedDescending == [_expirationDate compare:[NSDate date]]));
}

- (void)regainToken:(NSDictionary*)savedKeysAndValues {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You  must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)doLoginWorkflow {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You  must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (BOOL)processWebViewResult:(NSURL*)processUrl {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You  must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)login {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
    [self regainToken:[defaults dictionaryRepresentation]];    
    if (![self isSessionValid]) {
        [self doLoginWorkflow];
    }
    else {
        if (_delegate)
            [_delegate clientDidLogin:self];
    }
}

- (void)shareLink:(NSString*)link withTitle:(NSString*)title andMessage:(NSString *)message {}

- (void)saveToken:(NSDictionary*)tokensToSave {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValuesForKeysWithDictionary:tokensToSave];
    [defaults synchronize];
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType {    
        
    if ([self processWebViewResult:request.URL])
        [webView removeFromSuperview];
    
    return YES;
}

@end
