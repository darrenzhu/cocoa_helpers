//
//  AELIClient.m
//  SNTests
//
//  Created by ap4y on 1/18/13.
//
//

#import "AELIClient.h"

@interface AELIClient ()

@end

@implementation AELIClient

static NSString * const baseUrl = @"https://api.linkedin.com";

- (id)initWithKey:(NSString *)consumerKey
           secret:(NSString *)consumerSecret
      permissions:(NSArray *)permissions
      andRedirect:(NSString *)redirectString {
    
    self = [super initWithBaseUrl:[NSURL URLWithString:baseUrl]
                              key:consumerKey
                           secret:consumerSecret
                      permissions:permissions
                         redirect:redirectString
                 requestTokenPath:@"uas/oauth/requestToken"
                    authorizePath:@"uas/oauth/authorize"
                  accessTokenPath:@"uas/oauth/accessToken"];
    if (self) {
        
    }
    
    return self;
}

#pragma mark - token saving
- (NSString *)accessTokenKey {
    return @"LIAccessTokenKey";
}

- (NSString *)accessTokenSecretKey {
    return @"LIAccessTokenKeySecret";
}

#pragma mark - Public methods
- (void)profileInformationWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    [self profileInformationWithFields:nil success:success failure:failure];
}

- (void)profileInformationWithFields:(NSArray *)fields
                             success:(void (^)(NSDictionary *))success
                             failure:(void (^)(NSError *))failure {

    NSString *requestString = [baseUrl stringByAppendingString:@"/v1/people/~"];
    if (fields) {
        requestString = [requestString stringByAppendingFormat:@":(%@)", [fields componentsJoinedByString:@","]];
    }
    requestString = [requestString stringByAppendingString:@"?format=json"];
    NSURL *url = [NSURL URLWithString:requestString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [self signRequest:request withBody:nil];

    [AESNClient processJsonRequest:request success:success failure:failure];
}

- (void)friendsInformationWithLimit:(NSInteger)limit
                             offset:(NSInteger)offset
                            success:(void (^)(NSArray *))success
                            failure:(void (^)(NSError *))failure {
    [self friendsInformationWithFields:nil limit:limit offset:offset success:success failure:failure];
}

- (void)friendsInformationWithFields:(NSArray *)fields
                               limit:(NSInteger)limit
                              offset:(NSInteger)offset
                             success:(void (^)(NSArray *))success
                             failure:(void (^)(NSError *))failure {

    NSString *requestString = [baseUrl stringByAppendingString:@"/v1/people/~/connections"];
    if (fields) {
        requestString = [requestString stringByAppendingFormat:@":(%@)", [fields componentsJoinedByString:@","]];
    }
    requestString = [requestString stringByAppendingFormat:@"?format=json&start=%i", offset];
    if (limit > 0) {
        requestString = [requestString stringByAppendingFormat:@"&count=%i", limit];
    }
    
    NSURL *url = [NSURL URLWithString:requestString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [self signRequest:request withBody:nil];
    
    [AESNClient processJsonRequest:request success:^(id json) {
        if(success) {
            success([json objectForKey:@"values"]);
        }
    } failure:failure];
}

@end
