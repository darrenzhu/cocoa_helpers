//
//  CommonEntity.m
//  cska
//
//  Created by Arthur Evstifeev on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AEManagedObject.h"
#import <objc/runtime.h>
#import "JSONKit.h"

@implementation AEManagedObject
@dynamic syncDate;

#pragma mark - Predefinitions
+ (dispatch_queue_t)jsonQueue {
    static dispatch_queue_t _jsonQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _jsonQueue = dispatch_queue_create("com.or.json_proccess", 0);
    });
    
    return _jsonQueue;
}

- (NSDateFormatter *)dateFormatter {
    NSDateFormatter *   rfc3339DateFormatter;
    NSLocale *          enUSPOSIXLocale;
    
    rfc3339DateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    enUSPOSIXLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
    
    [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    return rfc3339DateFormatter;
}

#pragma mark - Serialization
- (NSString *)toJSONString {
    unsigned int outCount;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);            
    NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
    
    for(int i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];        
        NSString *propertyAtr = [NSString stringWithCString:property_getAttributes(property)
                                                   encoding:NSUTF8StringEncoding];
        
        if ([propertyAtr rangeOfString:@"NSString"].location != NSNotFound ||
            [propertyAtr rangeOfString:@"NSNumber"].location != NSNotFound ||
            [propertyAtr rangeOfString:@"NSArray"].location != NSNotFound ||
            [propertyAtr rangeOfString:@"NSDictionary"].location != NSNotFound) {
            
            NSString *propertyName = [NSString stringWithCString:property_getName(property)
                                                        encoding:NSUTF8StringEncoding];
            id propertyValue = [self valueForKeyPath:propertyName];            
            [jsonObject setValue:propertyValue forKey:propertyName];
        }         
    }
    free(properties);    
    [jsonObject setValue:[self valueForKey:@"id"] forKey:@"id"];
    
    return [jsonObject JSONString];
}

- (void)updateFromJSONObject:(id)jsonObject {    
    if (self && jsonObject) {
        unsigned int outCount;
        objc_property_t *properties = class_copyPropertyList([self class], &outCount);        
        
        for(int i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];            
            NSString *propertyName = [NSString stringWithCString:property_getName(property)
                                                        encoding:NSUTF8StringEncoding];
            id jsonValue = [jsonObject valueForKeyPath:propertyName];
            if ([jsonValue isEqual:[NSNull null]] || jsonValue == nil) {
                continue;
            }            
            
            NSString *propertyAtr = [NSString stringWithCString:property_getAttributes(property)
                                                       encoding:NSUTF8StringEncoding];
            NSArray *attributes = [propertyAtr componentsSeparatedByString:@","];
            NSString *typeAttribute = [attributes objectAtIndex:0];
            NSString *propertyType = [typeAttribute substringFromIndex:2];
            propertyType = [propertyType stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            
            if ([propertyAtr rangeOfString:@"NSDate"].location != NSNotFound && [self dateFormatter]) {
                [self setValue:[[self dateFormatter] dateFromString:jsonValue]
                        forKey:propertyName];
            } else if ([jsonValue isKindOfClass:NSClassFromString(propertyType)]) {
                [self setValue:jsonValue forKey:propertyName];   
            }
        }
        
        NSNumber *jsonValue = [jsonObject valueForKeyPath:@"id"];
        if (jsonValue != nil) {
            [self setValue:jsonValue forKey:@"id"];
        }
        
        if ([self respondsToSelector:@selector(setSyncDate:)]) {
            self.syncDate = [NSDate date];
        }
        
        free(properties);    
    }
}

#pragma mark - Initialization
- (id)initFromJSONObject:(id)jsonObject inManagedObjectContext:(NSManagedObjectContext *)context {
    NSEntityDescription *description = [self.class enityDescriptionInContext:context];
    self = [super initWithEntity:description insertIntoManagedObjectContext:context];
    if (self) {
        [self updateFromJSONObject:jsonObject];
    }
    return self;    
}

+ (AEManagedObject *)createFromJsonObject:(id)json inManagedObjectContext:(NSManagedObjectContext *)context {    
    Class class = self.class;
    
    if (class) {
        AEManagedObject *entity = [[[class alloc] initFromJSONObject:json                                                     
                                        inManagedObjectContext:context] autorelease]; 
        return entity;
    }
    
    return nil;
}

+ (AEManagedObject *)createOrUpdateFromJsonObject:(id)json inManagedObjectContext:(NSManagedObjectContext *)context {
    NSNumber *curId = [json valueForKeyPath:@"id"];        
    if (curId == nil) {
        return nil;
    }

    AEManagedObject *entity = [self requestFirstResult:[self find:curId] managedObjectContext:context];
    if (entity) {
        [entity updateFromJSONObject:json];
        return entity;
    }
    
    return [self createFromJsonObject:json inManagedObjectContext:context];
}

+ (NSEntityDescription *)enityDescriptionInContext:(NSManagedObjectContext *)context {
    return [NSEntityDescription entityForName:NSStringFromClass(self.class)
                       inManagedObjectContext:context];
}

#pragma mark - Private
+ (NSString *)jsonRoot {
    return @"data";
}

+ (void)formatJson:(NSArray *)items 
           success:(void (^)(NSArray *entities))success {    

    NSManagedObjectContext *context = [[AECoreDataHelper createManagedObjectContext] retain];
    [AECoreDataHelper addMergeNotificationForMainContext:context];
    NSMutableArray *result = [NSMutableArray array];
    
    for (id jsonString in items) {                                        
        AEManagedObject *entity = [self createOrUpdateFromJsonObject:jsonString
                                inManagedObjectContext:context];
        [result addObject:entity];                     
    }
    [AECoreDataHelper save:context];            

    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *resultInMainThread = [NSMutableArray array];
        for (AEManagedObject *entity in result) {
            AEManagedObject *entityInMainThread = (AEManagedObject *)[mainThreadContext() objectWithID:entity.objectID];
            [resultInMainThread addObject:entityInMainThread];
        }
        success(resultInMainThread);
        [context release];
    });
}

#pragma mark - Remote fetch
+ (void)fetchWithClient:(AFHTTPClient *)client
                   path:(NSString *)path 
             parameters:(NSDictionary *)parameters  
                success:(void (^)(NSArray *entities))success 
                failure:(void (^)(NSError *error))failure {
    [self fetchWithClient:client 
                     path:path 
               parameters:parameters 
             jsonResponse:nil 
                  success:success 
                  failure:failure];
}

+ (void)fetchWithClient:(AFHTTPClient *)client
                   path:(NSString *)path 
             parameters:(NSDictionary *)parameters  
           jsonResponse:(void (^)(id json))jsonResponse
                success:(void (^)(NSArray *entities))success
                failure:(void (^)(NSError *error))failure {
    
    [client getPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {        
        if (!responseObject) {
            return;
        }
        
        if (jsonResponse) {
            jsonResponse(responseObject);
        }
        
        if (success) {
            NSArray *items = responseObject;
            if ([self jsonRoot]) {
                items = [responseObject valueForKeyPath:[self jsonRoot]];
            }
            
            if ([items isKindOfClass:NSArray.class]) {
                dispatch_async([self jsonQueue], ^{
                    [self formatJson:items success:success];
                });
            }
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark - Local fetch (new syntax)
+ (NSFetchRequest *)all {
    return [AECoreDataHelper requestWithPredicate:nil andSortingDescriptors:nil];;
}

+ (NSFetchRequest *)find:(id)itemId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id = %@", itemId];
    return [AECoreDataHelper requestWithPredicate:predicate andSortingDescriptors:nil];
}

+ (NSFetchRequest *)where:(NSPredicate *)wherePredicate {
    return [AECoreDataHelper requestWithPredicate:wherePredicate andSortingDescriptors:nil];
}

+ (NSArray *)requestResult:(NSFetchRequest *)request
      managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    [request setEntity:[self enityDescriptionInContext:managedObjectContext]];
    return [AECoreDataHelper requestResult:request managedObjectContext:managedObjectContext];
}

+ (id)requestFirstResult:(NSFetchRequest *)request managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    [request setFetchLimit:1];
    NSArray *result = [self requestResult:request managedObjectContext:managedObjectContext];
    
    if (result && result.count == 0) {
        return nil;
    }
    
    return [result objectAtIndex:0];
}

@end
