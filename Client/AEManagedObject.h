//
//  CommonEntity.h
//  cska
//
//  Created by Arthur Evstifeev on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "NSFetchRequest+orderBy.h"
#import "AFHTTPClient.h"
#import "AECoreDataHelper.h"

@interface AEManagedObject : NSManagedObject
@property(retain, nonatomic) NSDate *syncDate;

#pragma mark - Initialization
- (id)initFromJSONObject:(id)jsonObject inManagedObjectContext:(NSManagedObjectContext *)context;
+ (AEManagedObject *)createOrUpdateFromJsonObject:(id)json inManagedObjectContext:(NSManagedObjectContext *)context;
+ (NSEntityDescription *)enityDescriptionInContext:(NSManagedObjectContext *)context;

#pragma mark - JSON serializaiton
- (void)updateFromJSONObject:(id)jsonObject;
- (NSString *)toJSONString;

#pragma mark - Remote fetch
+ (void)fetchWithClient:(AFHTTPClient *)client
                   path:(NSString *)path 
             parameters:(NSDictionary *)parameters                
                success:(void (^)(NSArray *entities))success 
                failure:(void (^)(NSError *error))failure;
+ (void)fetchWithClient:(AFHTTPClient *)client
                   path:(NSString *)path 
             parameters:(NSDictionary *)parameters  
           jsonResponse:(void (^)(id json))jsonResponse
                success:(void (^)(NSArray *entities))success 
                failure:(void (^)(NSError *error))failure;

#pragma mark - Local fetch (new syntax)
+ (NSFetchRequest *)all;
+ (NSFetchRequest *)find:(id)itemId;
+ (NSFetchRequest *)where:(NSPredicate *)wherePredicate;
+ (NSArray *)requestResult:(NSFetchRequest *)request
      managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (id)requestFirstResult:(NSFetchRequest *)request
    managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end

@interface AEManagedObject (Pivate)
- (NSDateFormatter *)dateFormatter;
+ (NSString *)jsonRoot;
+ (BOOL)requiresPersistence;
@end
