//
//  AELIClient.m
//  SNTests
//
//  Created by ap4y on 1/18/13.
//
//

#import "AELIClient.h"

@implementation AELIClient

static NSString * const baseUrl = @"https://api.linkedin.com";

static AELIClient *currentLIClient;
+ (AELIClient *)currentLIClient {
    return currentLIClient;
}

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
        currentLIClient = self;
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

    NSString *profilePath   = [baseUrl stringByAppendingString:@"/v1/people/~"];
    if (fields) {
        profilePath         = [profilePath stringByAppendingFormat:@":(%@)", [fields componentsJoinedByString:@","]];
    }
    profilePath             = [profilePath stringByAppendingString:@"?format=json"];
    
    NSURL *profileUrl                   = [NSURL URLWithString:profilePath];    
    NSMutableURLRequest *profileRequest = [NSMutableURLRequest requestWithURL:profileUrl];
    [self signRequest:profileRequest withBody:nil];

    [AESNClient processJsonRequest:profileRequest success:success failure:failure];
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

    NSString *friendsPath   = [baseUrl stringByAppendingString:@"/v1/people/~/connections"];
    if (fields) {
        friendsPath         = [friendsPath stringByAppendingFormat:@":(%@)", [fields componentsJoinedByString:@","]];
    }
    friendsPath             = [friendsPath stringByAppendingFormat:@"?format=json&start=%i", offset];
    if (limit > 0) {
        friendsPath         = [friendsPath stringByAppendingFormat:@"&count=%i", limit];
    }
    
    NSURL *friendsUrl                   = [NSURL URLWithString:friendsPath];
    NSMutableURLRequest *friendsRequest = [NSMutableURLRequest requestWithURL:friendsUrl];
    [self signRequest:friendsRequest withBody:nil];
    
    [AESNClient processJsonRequest:friendsRequest success:^(id json) {
        if(success) {
            success([json objectForKey:@"values"]);
        }
    } failure:failure];
}

@end
