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
#import "JSONKit.h"

#import "NetworkIndicatorManager.h"

@interface CommonClient : AFHTTPClient

- (NSDateFormatter *)dateFormatter;
- (NSEntityDescription *)enityDescriptionInContext:(NSManagedObjectContext *)context;

- (NSMutableDictionary*)formBody:(int)start 
                           count:(int)limit 
                        dateFrom:(NSDate*)date;

- (CommonEntity*)createOrUpdate:(id)jsonString inManagedObjectContext:(NSManagedObjectContext*)context;
- (void)formatJson:(NSArray*)items 
             byOne:(BOOL)byOne
           success:(void (^)(NSArray* entities))success;

- (void)entitiesFromPath:(NSString *)path 
              parameters:(NSDictionary *)parameters
                   byOne:(BOOL)byOne
                 success:(void (^)(NSArray* entities))success 
                 failure:(void (^)(NSError *error))failure;

- (NSArray*)all:(NSManagedObjectContext*)context;
- (NSArray*)all:(NSManagedObjectContext*)context orderBy:(NSString*)firstSortingParam, ... NS_REQUIRES_NIL_TERMINATION;
- (NSArray*)all:(NSManagedObjectContext*)context orderByDescriptors:(NSSortDescriptor*)firstDescriptor, ... NS_REQUIRES_NIL_TERMINATION;

- (id)find:(NSManagedObjectContext*)context itemId:(id)itemId;

- (NSArray*)where:(NSManagedObjectContext*)context wherePredicate:(NSPredicate*)wherePredicate;
- (NSArray*)where:(NSManagedObjectContext*)context wherePredicate:(NSPredicate*)wherePredicate orderBy:(NSString*)firstSortingParam, ... NS_REQUIRES_NIL_TERMINATION;
- (NSArray*)where:(NSManagedObjectContext*)context wherePredicate:(NSPredicate*)wherePredicate orderByDescriptors:(NSSortDescriptor*)firstDescriptor, ... NS_REQUIRES_NIL_TERMINATION;

@end
