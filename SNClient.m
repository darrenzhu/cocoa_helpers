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

- (NSString*)accessTokenKey {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You  must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString*)accessTokenKeySecretKey {
    return [NSString stringWithFormat:@"%@Secret", [self accessTokenKey]];
}

- (NSString*)expirationDateKey {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You  must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (BOOL)isSessionValid {
    return (_accessToken != nil && 
            ( (_expirationDate != nil && NSOrderedDescending == [_expirationDate compare:[NSDate date]]) ||
             _accessTokenSecret != nil) );
}

- (void)login {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
    if ([defaults objectForKey:[self accessTokenKey]] 
        && ([defaults objectForKey:[self expirationDateKey]] || [defaults objectForKey:[self accessTokenKeySecretKey]])) {
        
        _accessToken = [defaults objectForKey:[self accessTokenKey]];
        _accessTokenSecret = [defaults objectForKey:[self accessTokenKeySecretKey]];
        _expirationDate = [defaults objectForKey:[self expirationDateKey]];
    }
}

- (void)parseUrl:(NSString*)url {

}

- (void)share:(CCNews*)_news andMessage:(NSString *)message {
    
}

- (void)saveToken {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_accessToken forKey:[self accessTokenKey]];
    [defaults setObject:_accessTokenSecret forKey:[self accessTokenKeySecretKey]];
    [defaults setObject:_expirationDate forKey:[self expirationDateKey]];
    [defaults synchronize];
}

@end
