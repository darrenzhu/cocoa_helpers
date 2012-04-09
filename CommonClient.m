//
//  CSKAClient.m
//  cska
//
//  Created by Arthur Evstifeev on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CommonClient.h"
#import "AFJSONRequestOperation.h"

@implementation CommonClient

- (NSDateFormatter *)dateFormatter {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSEntityDescription *)enityDescriptionInContext:(NSManagedObjectContext *)context {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSMutableDictionary*)formBody:(int)start 
                           count:(int)limit 
                        dateFrom:(NSDate*)date {
    
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    
    [params setValue:[NSNumber numberWithInt:start] forKey:@"from"];
    
    if (limit > 0)
        [params setValue:[NSNumber numberWithInt:limit] forKey:@"count"];
    
    if (date) {
        [params setValue:[self.dateFormatter stringFromDate:date] forKey:@"dateFrom"];    
    }
    
    return params;
}

- (void)postprocessJSON:(id)json withEntity:(CommonEntity*)entity {}

- (CommonEntity*)createOrUpdate:(id)jsonString inManagedObjectContext:(NSManagedObjectContext*)context {
    
    NSNumber* curId = [jsonString valueForKeyPath:@"id"];
    
    NSPredicate* idPredicate = [NSPredicate predicateWithFormat:@"id = %@", curId];    
    NSFetchRequest *fetchRequest = [CoreDataHelper requestEntityWithDesctiption:[self enityDescriptionInContext:context] 
                                                                  withPredicate:idPredicate 
                                                          andSortingDescriptors:nil 
                                                         inManagedObjectContext:context];
    
    CommonEntity* entity = [CoreDataHelper requestFirstResult:fetchRequest managedObjectContext:context];
    if (entity) {
        [entity updateFromJSON:jsonString];  
    }
    else {
        Class class = NSClassFromString([self enityDescriptionInContext:context].managedObjectClassName);
        
        if (class)
            entity = [[[class alloc] initFromJSON: jsonString 
                                       withEntity:[self enityDescriptionInContext:context] 
                           inManagedObjectContext:context] autorelease]; 
    }
    
    [entity postprocessJSON:jsonString withClient:self]; 
    
    return entity;
}

- (void)formatJson:(NSArray*)items 
             byOne:(BOOL)byOne
           success:(void (^)(NSArray* entities))success {    

    [[NetworkIndicatorManager defaultManager] setNetworkIndicatorState:YES];
    NSManagedObjectContext* context = [CoreDataHelper createManagedObjectContext];
    NSMutableArray* result = [NSMutableArray array];        
    
    for (id jsonString in items) {                                
        
        CommonEntity* entity = [self createOrUpdate:jsonString inManagedObjectContext:context];                            
        [result addObject:entity];                     
    }     
    
    [CoreDataHelper save:context];
    
    if (!byOne) {
        dispatch_async(dispatch_get_main_queue(), ^{
            success(nil);
        }); 
    }
    [[NetworkIndicatorManager defaultManager] setNetworkIndicatorState:NO];
}

- (void)getPath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    
    [[NetworkIndicatorManager defaultManager] setNetworkIndicatorState:YES];
    [super getPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[NetworkIndicatorManager defaultManager] setNetworkIndicatorState:NO];
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[NetworkIndicatorManager defaultManager] setNetworkIndicatorState:NO];
        failure(operation, error);
    }];
}

- (void)entitiesFromPath:(NSString *)path 
              parameters:(NSDictionary *)parameters
                   byOne:(BOOL)byOne
                 success:(void (^)(NSArray* entities))success 
                 failure:(void (^)(NSError *error))failure {
        
    [self getPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (responseObject && [responseObject respondsToSelector:@selector(valueForKey:)]) {
            NSArray* items = [responseObject valueForKeyPath:@"data"];
            
            if ([items isKindOfClass:NSArray.class] && items.count > 0) {  
                
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    [self formatJson:items byOne:byOne success:success];
                });                
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {        
        failure(error);
    }];
}

- (NSArray*)all:(NSManagedObjectContext*)context {
    NSFetchRequest *fetchRequest = [CoreDataHelper requestEntityWithDesctiption:[self enityDescriptionInContext:context] 
                                                                  withPredicate:nil 
                                                          andSortingDescriptors:nil
                                                         inManagedObjectContext:context];
    
    return [CoreDataHelper requestResult:fetchRequest managedObjectContext:context];
}

- (NSArray*)all:(NSManagedObjectContext*)context orderBy:(NSString*)firstSortingParam, ... {
    
    va_list argumentList;    
    va_start(argumentList, firstSortingParam);
    
    NSMutableArray* descriptorsArray = [NSMutableArray array];  
    for (NSString *arg = firstSortingParam; arg != nil; arg = va_arg(argumentList, NSString*))
    {
        [descriptorsArray addObject:[NSSortDescriptor sortDescriptorWithKey:firstSortingParam ascending:YES]];
    }
    va_end(argumentList);
    
    NSFetchRequest *fetchRequest = [CoreDataHelper requestEntityWithDesctiption:[self enityDescriptionInContext:context] 
                                                                  withPredicate:nil 
                                                          andSortingDescriptors:descriptorsArray
                                                         inManagedObjectContext:context];
    
    return [CoreDataHelper requestResult:fetchRequest managedObjectContext:context];
}

- (NSArray*)all:(NSManagedObjectContext*)context orderByDescriptors:(NSSortDescriptor*)firstDescriptor, ... {
    
    va_list argumentList;    
    va_start(argumentList, firstDescriptor);
    
    NSMutableArray* descriptorsArray = [NSMutableArray array];  
    for (NSSortDescriptor *arg = firstDescriptor; arg != nil; arg = va_arg(argumentList, NSSortDescriptor*))
    {
        [descriptorsArray addObject:arg];
    }
    va_end(argumentList);
    
    NSFetchRequest *fetchRequest = [CoreDataHelper requestEntityWithDesctiption:[self enityDescriptionInContext:context] 
                                                                  withPredicate:nil 
                                                          andSortingDescriptors:descriptorsArray
                                                         inManagedObjectContext:context];
    
    return [CoreDataHelper requestResult:fetchRequest managedObjectContext:context];
}

- (id)find:(NSManagedObjectContext*)context itemId:(id)itemId {
    NSFetchRequest *fetchRequest = [CoreDataHelper requestEntityWithDesctiption:[self enityDescriptionInContext:context] 
                                                                  withPredicate:[NSPredicate predicateWithFormat:@"id = %@", itemId] 
                                                          andSortingDescriptors:nil
                                                         inManagedObjectContext:context];
    
    return [CoreDataHelper requestFirstResult:fetchRequest managedObjectContext:context];
}

- (NSArray*)where:(NSManagedObjectContext*)context wherePredicate:(NSPredicate*)wherePredicate {
    NSFetchRequest *fetchRequest = [CoreDataHelper requestEntityWithDesctiption:[self enityDescriptionInContext:context] 
                                                                  withPredicate:wherePredicate 
                                                          andSortingDescriptors:nil
                                                         inManagedObjectContext:context];
    
    return [CoreDataHelper requestResult:fetchRequest managedObjectContext:context];
}

- (NSArray*)where:(NSManagedObjectContext*)context wherePredicate:(NSPredicate*)wherePredicate orderBy:(NSString*)firstSortingParam, ... {
    
    va_list argumentList;    
    va_start(argumentList, firstSortingParam);
    
    NSMutableArray* descriptorsArray = [NSMutableArray array];  
    for (NSString *arg = firstSortingParam; arg != nil; arg = va_arg(argumentList, NSString*))
    {
        [descriptorsArray addObject:[NSSortDescriptor sortDescriptorWithKey:firstSortingParam ascending:YES]];
    }
    va_end(argumentList);
    
    NSFetchRequest *fetchRequest = [CoreDataHelper requestEntityWithDesctiption:[self enityDescriptionInContext:context] 
                                                                  withPredicate:wherePredicate 
                                                          andSortingDescriptors:descriptorsArray
                                                         inManagedObjectContext:context];
    
    return [CoreDataHelper requestResult:fetchRequest managedObjectContext:context];
}

- (NSArray*)where:(NSManagedObjectContext*)context wherePredicate:(NSPredicate*)wherePredicate orderByDescriptors:(NSSortDescriptor*)firstDescriptor, ... {
    
    va_list argumentList;    
    va_start(argumentList, firstDescriptor);
    
    NSMutableArray* descriptorsArray = [NSMutableArray array];  
    for (NSSortDescriptor *arg = firstDescriptor; arg != nil; arg = va_arg(argumentList, NSSortDescriptor*))
    {
        [descriptorsArray addObject:arg];
    }
    va_end(argumentList);
    
    NSFetchRequest *fetchRequest = [CoreDataHelper requestEntityWithDesctiption:[self enityDescriptionInContext:context] 
                                                                  withPredicate:wherePredicate 
                                                          andSortingDescriptors:descriptorsArray
                                                         inManagedObjectContext:context];
    
    return [CoreDataHelper requestResult:fetchRequest managedObjectContext:context];
}

@end
