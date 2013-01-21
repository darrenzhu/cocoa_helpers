//
//  AELIClient.h
//  SNTests
//
//  Created by ap4y on 1/18/13.
//
//

#import "AEOAuthClient.h"

@interface AELIClient : AEOAuthClient
+ (AELIClient *)currentLIClient;
- (id)initWithKey:(NSString *)consumerKey
           secret:(NSString *)consumerSecret
      permissions:(NSArray *)permissions
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
