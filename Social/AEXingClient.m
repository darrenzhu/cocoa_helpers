//
//  AEXingClient.m
//  SNTests
//
//  Created by Arthur Evstifeev on 22/01/13.
//
//

#import "AEXingClient.h"

@implementation AEXingClient

static NSString * const baseUrl = @"https://api.xing.com";

static AEXingClient *currentClient;
+ (AEXingClient *)currentClient {
    return currentClient;
}

- (id)initWithKey:(NSString *)consumerKey
           secret:(NSString *)consumerSecret
      andRedirect:(NSString *)redirectString {
    
    self = [super initWithBaseUrl:[NSURL URLWithString:baseUrl]
                              key:consumerKey
                           secret:consumerSecret
                      permissions:nil
                         redirect:redirectString
                 requestTokenPath:@"v1/request_token"
                    authorizePath:@"v1/authorize"
                  accessTokenPath:@"v1/access_token"];
    if (self) {
        currentClient = self;
    }
    
    return self;
}

#pragma mark - token saving
- (NSString *)accessTokenKey {
    return @"XingAccessTokenKey";
}

- (NSString *)accessTokenSecretKey {
    return @"XingAccessTokenKeySecret";
}

#pragma mark - Public methods
- (void)profileInformationWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    [self profileInformationWithFields:nil success:success failure:failure];
}

- (void)profileInformationWithFields:(NSArray *)fields
                             success:(void (^)(NSDictionary *))success
                             failure:(void (^)(NSError *))failure {
    
    NSString *profilePath   = [baseUrl stringByAppendingString:@"/v1/users/me.json"];
    if (fields) {
        profilePath         = [profilePath stringByAppendingFormat:@"?fields=%@",
                               [fields componentsJoinedByString:@","]];
    }
    
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
    
    NSString *friendsPath   = [baseUrl stringByAppendingString:@"/v1/users/me/contacts.json"];
    friendsPath             = [friendsPath stringByAppendingFormat:@"?format=json&offset=%i", offset];
    if (limit > 0) {
        friendsPath         = [friendsPath stringByAppendingFormat:@"&limit=%i", limit];
    }
    if (fields) {
        friendsPath         = [friendsPath stringByAppendingFormat:@"&user_fields=%@",
                               [fields componentsJoinedByString:@","]];
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
