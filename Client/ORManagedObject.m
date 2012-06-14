//
//  CommonEntity.m
//  cska
//
//  Created by Arthur Evstifeev on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ORManagedObject.h"
#import <objc/runtime.h>

#import "JSONKit.h"

@implementation ORManagedObject
@dynamic syncDate;

#pragma mark - Predefenitions
+ (dispatch_queue_t)jsonQueue {
    static dispatch_queue_t _jsonQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _jsonQueue = dispatch_queue_create("com.or.json_proccess", 0);
    });
    
    return _jsonQueue;
}

- (NSDate*)localeTime {
    NSDate* dateNow = [NSDate date];
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate:dateNow];
    dateNow = [NSDate dateWithTimeInterval:seconds sinceDate:dateNow];
    return dateNow;
}

- (NSDateFormatter *)dateFormatter {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

#pragma mark - Serialization
- (NSString*)toJSONString {
    unsigned int outCount;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);        
    
    NSMutableDictionary* jsonObject = [NSMutableDictionary dictionary];
    
    for(int i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        
        NSString* propertyAtr = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        if ([propertyAtr rangeOfString:@"NSString"].location != NSNotFound ||
            [propertyAtr rangeOfString:@"NSNumber"].location != NSNotFound ||
            [propertyAtr rangeOfString:@"NSArray"].location != NSNotFound ||
            [propertyAtr rangeOfString:@"NSDictionary"].location != NSNotFound) {
            
            NSString* propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
            id propertyValue = [self valueForKeyPath:propertyName];
            
            [jsonObject setValue:propertyValue forKey:propertyName];
        }         
    }
    free(properties);
    
    [jsonObject setValue:[self valueForKey:@"id"] forKey:@"id"];
    
    return [jsonObject JSONString];
}

- (void)updateFromJSON:(id)json {
    
    if (self) {
        
        unsigned int outCount;
        objc_property_t *properties = class_copyPropertyList([self class], &outCount);        
        
        for(int i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            
            NSString* propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
            
            NSString* propertyAtr = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
            
            id jsonValue = [json valueForKeyPath:propertyName];
            
            NSArray * attributes = [propertyAtr componentsSeparatedByString:@","];
            NSString * typeAttribute = [attributes objectAtIndex:0];
            NSString * propertyType = [typeAttribute substringFromIndex:2];
            propertyType = [propertyType stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            
            if (jsonValue != [NSNull null] && jsonValue != nil) {
                if ([propertyAtr rangeOfString:@"NSDate"].location != NSNotFound) {                      
                    [self setValue:[[self dateFormatter] dateFromString:jsonValue] forKey:propertyName];                                       
                }
                else if ([jsonValue isKindOfClass:NSClassFromString(propertyType)]) {
                    [self setValue:jsonValue forKey:propertyName];   
                }
            }
        }
        
        NSNumber* jsonValue = [json valueForKeyPath:@"id"];
        if (jsonValue != nil) {
            [self setValue:jsonValue forKey:@"id"];
        }
        
        self.syncDate = [self localeTime];
        
        free(properties);    
    }
}

#pragma mark - Constructors

- (id)initFromJSON:(id)json withEntity:(NSEntityDescription*)entityDescription inManagedObjectContext:(NSManagedObjectContext*)context {
    self = [super initWithEntity:entityDescription insertIntoManagedObjectContext:context];
    if (self) {
        [self updateFromJSON:json];
    }
    return self;    
}

+ (ORManagedObject*)createOrUpdate:(id)json inManagedObjectContext:(NSManagedObjectContext*)context {
    
    NSNumber* curId = [json valueForKeyPath:@"id"];
    
    if (curId != nil) {
        NSFetchRequest *fetchRequest = [self find:context itemId:curId];
        ORManagedObject* entity = [CoreDataHelper requestFirstResult:fetchRequest managedObjectContext:context];
        
        if (entity ) {
            [entity updateFromJSON:json];  
            [entity didFinishedFetchJSON:json inManagedContext:context];
            return entity;
        }
    }
    
    Class class = NSClassFromString([self enityDescriptionInContext:context].managedObjectClassName);
    
    if (class) {
        ORManagedObject* entity = [[[class alloc] initFromJSON:json 
                                                    withEntity:[self enityDescriptionInContext:context] 
                                        inManagedObjectContext:context] autorelease]; 
        [entity didFinishedFetchJSON:json inManagedContext:context];        
        return entity;
    }
    
    return nil;
}

#pragma mark - Private

+ (NSEntityDescription*)enityDescriptionInContext:(NSManagedObjectContext*)context {
    return [NSEntityDescription entityForName:NSStringFromClass(self.class) inManagedObjectContext:context];
}

+ (void)formatJson:(NSArray*)items 
           success:(void (^)(NSArray* entities))success {    
    
    NSManagedObjectContext* context = [[CoreDataHelper createManagedObjectContext] retain];
    [CoreDataHelper addMergeNotificationForMainContext:context];
    NSMutableArray* result = [NSMutableArray array];        
    
    for (id jsonString in items) {                                
        
        ORManagedObject* entity = [self createOrUpdate:jsonString inManagedObjectContext:context];                            
        [result addObject:entity];                     
    }     
    
    [CoreDataHelper save:context];            
    
    dispatch_async(dispatch_get_main_queue(), ^{ 
        NSMutableArray* resultInMainThread = [NSMutableArray array];
        for (ORManagedObject* entity in result) {
            ORManagedObject* entityInMainThread = 
                (ORManagedObject*)[[CoreDataHelper mainThreadContext] objectWithID:entity.objectID];
            [resultInMainThread addObject:entityInMainThread];
        }
        success(resultInMainThread);
    }); 
    [context release];
}

#pragma mark - Remote fetch

+ (void)fetchWithClient:(ORHTTPClient*)client
                   path:(NSString *)path 
             parameters:(NSDictionary *)parameters                
                success:(void (^)(NSArray* entities))success 
                failure:(void (^)(NSError *error))failure {
    
    [client getPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (responseObject && [responseObject isKindOfClass:NSArray.class]) {
            NSArray* items = [responseObject valueForKeyPath:@"data"]; //TODO: decide how to select path
            
            if ([items isKindOfClass:NSArray.class] && items.count > 0) {  
                
                dispatch_async([self jsonQueue], ^{
                    [self formatJson:items success:success];
                });                
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {        
        failure(error);
    }];
}

#pragma mark - Local fetch

+ (NSFetchRequest*)all:(NSManagedObjectContext*)context {
    NSFetchRequest *fetchRequest = [CoreDataHelper requestEntityWithDesctiption:[self enityDescriptionInContext:context] 
                                                                  withPredicate:nil 
                                                          andSortingDescriptors:nil
                                                         inManagedObjectContext:context];
    
    return fetchRequest;
}

+ (NSFetchRequest*)find:(NSManagedObjectContext*)context itemId:(id)itemId {
    NSFetchRequest *fetchRequest = [CoreDataHelper requestEntityWithDesctiption:[self enityDescriptionInContext:context] 
                                                                  withPredicate:[NSPredicate predicateWithFormat:@"id = %@", itemId] 
                                                          andSortingDescriptors:nil
                                                         inManagedObjectContext:context];
    
    return fetchRequest;
}

+ (NSFetchRequest*)where:(NSManagedObjectContext*)context wherePredicate:(NSPredicate*)wherePredicate {
    NSFetchRequest *fetchRequest = [CoreDataHelper requestEntityWithDesctiption:[self enityDescriptionInContext:context] 
                                                                  withPredicate:wherePredicate 
                                                          andSortingDescriptors:nil
                                                         inManagedObjectContext:context];
    
    return fetchRequest;
}

@end
