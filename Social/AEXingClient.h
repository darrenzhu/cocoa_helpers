//
//  AEXingClient.h
//  SNTests
//
//  Created by Arthur Evstifeev on 22/01/13.
//
//

#import "AEOAuthClient.h"

@interface AEXingClient : AEOAuthClient
+ (AEXingClient *)currentClient;

- (id)initWithKey:(NSString *)consumerKey
           secret:(NSString *)consumerSecret
      andRedirect:(NSString *)redirectString;

- (void)profileInformationWithFields:(NSArray *)fields
                             success:(void (^)(NSDictionary *))success
                             failure:(void (^)(NSError *))failure;

- (void)friendsInformationWithFields:(NSArray *)fields
                               limit:(NSInteger)limit
                              offset:(NSInteger)offset
                             success:(void (^)(NSArray *))success
                             failure:(void (^)(NSError *))failure;
@end
