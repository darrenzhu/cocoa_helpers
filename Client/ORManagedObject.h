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
#import "ORHTTPClient.h"
#import "CoreDataHelper.h"

@interface ORManagedObject : NSManagedObject

@property(nonatomic, strong) NSDate* syncDate;

- (id)initFromJSON:(id)json inManagedObjectContext:(NSManagedObjectContext*)context;
- (id)initFromJSON:(id)json withEntity:(NSEntityDescription*)entityDescription inManagedObjectContext:(NSManagedObjectContext*)context;

- (NSDateFormatter *)dateFormatter;

- (void)updateFromJSON:(id)json;
- (NSString*)toJSONString;

+ (ORManagedObject*)createOrUpdate:(id)json inManagedObjectContext:(NSManagedObjectContext*)context;
+ (NSEntityDescription*)enityDescriptionInContext:(NSManagedObjectContext*)context;

+ (void)fetchWithClient:(ORHTTPClient*)client
                   path:(NSString *)path 
             parameters:(NSDictionary *)parameters                
                success:(void (^)(NSArray* entities))success 
                failure:(void (^)(NSError *error))failure;
+ (void)fetchWithClient:(ORHTTPClient*)client
                   path:(NSString *)path 
             parameters:(NSDictionary *)parameters  
           jsonResponse:(void (^)(id json))jsonResponse
                success:(void (^)(NSArray* entities))success 
                failure:(void (^)(NSError *error))failure;

+ (NSFetchRequest*)all:(NSManagedObjectContext*)context;
+ (NSFetchRequest*)find:(NSManagedObjectContext*)context itemId:(id)itemId;
+ (NSFetchRequest*)where:(NSManagedObjectContext*)context wherePredicate:(NSPredicate*)wherePredicate;

@end

@interface ORManagedObject (Pivate)
@end
