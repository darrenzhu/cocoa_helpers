//
//  CSKAClient.h
//  cska
//
//  Created by Arthur Evstifeev on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AFHTTPClient.h"
#import "CommonEntity.h"
#import "CoreDataHelper.h"

#define kTTBaseURLString @"http://test.goguruz.com/"
#define kTTBaseURLShortString @"test.goguruz.com"
//#define kTTBaseURLString @"http://goguruz.com/"

@interface CommonClient : AFHTTPClient {
    void (^_success)();
}

+ (CommonClient*)sharedClient;

- (NSEntityDescription *)enityDescriptionInContext:(NSManagedObjectContext *)context;

- (CommonEntity*)createOrUpdate:(id)jsonString inManagedObjectContext:(NSManagedObjectContext*)context;

- (void)values:(NSString*)valueCategory
    withParams:(NSDictionary*)params
       success:(void (^)(NSArray* entities))success        
       failure:(void (^)(NSError *error))failure;

- (void)photosForCardId:(NSNumber*)cardId            
                success:(void (^)(NSArray* entities))success        
                failure:(void (^)(NSError *error))failure;

- (void)commentsForCardId:(NSNumber*)cardId            
                  success:(void (^)(NSArray* entities))success        
                  failure:(void (^)(NSError *error))failure;

- (void)getCitiesWithMask:(NSString*)mask success:(void (^)(NSArray* cities))success;

- (void)addTip:(NSString*)message forProfile:(NSString*)profileID response:(void (^)(NSString* response))response;
- (void)shareOnFbForProfile:(NSString*)profileID response:(void (^)(NSString* response))response;
- (void)addFavoriteForProfile:(NSString*)profileID response:(void (^)(NSString* response))response;
- (void)setRate:(int)rate ForProfile:(NSString*)profileID response:(void (^)(NSString* response))response;
- (void)sendFBMessage:(NSString*)message toUser:(NSString*)userId withToken:(NSString*)token response:(void (^)(NSString* response))response;
- (void)doLoginWithToken:(NSString*)token reponse:(void (^)(NSString* response))response;
- (void)uploadImage:(UIImage*)image forProfile:(NSString*)profileID success:(void (^)())success ;

@end
