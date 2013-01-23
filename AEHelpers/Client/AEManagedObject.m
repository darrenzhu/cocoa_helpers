//
// AEManagedObject.m
//
// Copyright (c) 2012 ap4y (lod@pisem.net)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

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

+ (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *_rfc3339DateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLocale *enUSPOSIXLocale;
        
        _rfc3339DateFormatter   = [[[NSDateFormatter alloc] init] autorelease];
        enUSPOSIXLocale         = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
        
        [_rfc3339DateFormatter setLocale:enUSPOSIXLocale];
        [_rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        [_rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    });
    
    return _rfc3339DateFormatter;
}

#pragma mark - Serialization
+ (NSString *)mappedPropertyNameForPropertyName:(NSString *)propertyName {
    NSDictionary *mappingsDictionary = [[self class] propertyMappings];
    NSString *mappedProperty;
    if (mappingsDictionary && ( mappedProperty = [mappingsDictionary objectForKey:propertyName] )) {
        return mappedProperty;
    }

    return propertyName;
}

- (NSString *)propertyNameFromPropertyDescription:(objc_property_t)property {
    return [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
}

- (NSString *)propertyTypeFromPropertyDescription:(objc_property_t)property {
    NSString *propertyAtr, *typeAttribute, *propertyType;
    NSArray *attributes;
    
    propertyAtr     = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
    attributes      = [propertyAtr componentsSeparatedByString:@","];
    typeAttribute   = [attributes objectAtIndex:0];
    propertyType    = [typeAttribute substringFromIndex:2];
    propertyType    = [propertyType stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    
    return propertyType;
}

- (id)toJSONObject {
    return [self toJSONObjectWithRootObject:YES andRelations:YES];
}

/** 
 This method support serialization with 1 level depth, because reverse association can produce infinity loops.
 */
- (id)toJSONObjectWithRootObject:(BOOL)withRootObject andRelations:(BOOL)withRelations {
    unsigned int outCount;
    objc_property_t *properties     = class_copyPropertyList([self class], &outCount);            
    NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
    
    for(int i = 0; i < outCount; i++) {
        objc_property_t property    = properties[i];        
        NSString *propertyAtr       = [NSString stringWithCString:property_getAttributes(property)
                                                         encoding:NSUTF8StringEncoding];
        NSString *propertyName      = [NSString stringWithCString:property_getName(property)
                                                         encoding:NSUTF8StringEncoding];

        BOOL hasSupportedType       = [propertyAtr rangeOfString:@"NSString"].location        != NSNotFound ||
                                      [propertyAtr rangeOfString:@"NSNumber"].location        != NSNotFound ||
                                      [propertyAtr rangeOfString:@"NSArray"].location         != NSNotFound ||
                                      [propertyAtr rangeOfString:@"NSDictionary"].location    != NSNotFound;
        
        id propertyValue            = [self valueForKey:propertyName];
        NSString *mappedKey         = [[self class] mappedPropertyNameForPropertyName:propertyName];                
        
        if (hasSupportedType) {
            
            [jsonObject setValue:propertyValue forKey:mappedKey];
            
        } else if (!withRelations) {
          
            continue;
            
        } else if ([propertyValue respondsToSelector:@selector(toJSONObjectWithRootObject:andRelations:)]) {

            [jsonObject setValue:[propertyValue toJSONObjectWithRootObject:NO andRelations:NO] forKey:mappedKey];
            
        } else if ([propertyValue isKindOfClass:[NSSet class]] || [propertyValue isKindOfClass:[NSOrderedSet class]]) {
            
            /* NSOrderedSet is not a subclass of NSSet */
            NSSet *manyAssociations     = (NSSet *)propertyValue;
            NSMutableArray *accumulator = [NSMutableArray array];
            [manyAssociations enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                if ([obj respondsToSelector:@selector(toJSONObjectWithRootObject:andRelations:)]) {
                    [accumulator addObject:[obj toJSONObjectWithRootObject:NO andRelations:NO]];
                }
            }];
            
            if ([accumulator count] > 0) [jsonObject setValue:accumulator forKey:mappedKey];
        }
    }
    free(properties);    
    
    if (withRootObject && [[self class] jsonRoot]) {
        jsonObject = [NSDictionary dictionaryWithObject:jsonObject forKey:[[self class] jsonRoot]];
    }
    
    return jsonObject;
}

- (void)updateFromJSONObject:(id)jsonObject {
    [self updateFromJSONObject:jsonObject withRelations:YES];
}

- (void)updateFromJSONObject:(id)jsonObject withRelations:(BOOL)withRelations {
    if (!self || !jsonObject) return;
    
    unsigned int outCount;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);        
    
    for(int i = 0; i < outCount; i++) {
        objc_property_t property;
        NSString *propertyName, *propertyType, *mappedKey;
        id jsonValue;
        
        property        = properties[i];
        propertyName    = [self propertyNameFromPropertyDescription:property];
        
        mappedKey       = [[self class] mappedPropertyNameForPropertyName:propertyName];
        jsonValue       = [jsonObject valueForKey:mappedKey];
        
        if ([jsonValue isEqual:[NSNull null]] || !jsonValue) continue;
        
        propertyType    = [self propertyTypeFromPropertyDescription:property];            
        
        if ([propertyType isEqualToString:@"NSDate"] && [[self class] dateFormatter]) {
            
            [self setValue:[[[self class] dateFormatter] dateFromString:jsonValue] forKey:propertyName];
            
        } else if ([jsonValue isKindOfClass:NSClassFromString(propertyType)]) {
            
            [self setValue:jsonValue forKey:propertyName];
            
        } else if (!withRelations) {
            
            continue;
            
        } if ([propertyType isEqualToString:@"NSSet"] || [propertyType isEqualToString:@"NSOrderedSet"]) {
            
            /* NSOrderedSet is not a subclass of NSSet */
            if (![jsonValue isKindOfClass:[NSArray class]] || [jsonValue count] <= 0) continue;
            
            NSArray *relations                              = (NSArray *)jsonValue;
            NSMutableArray *accumulator                     = [NSMutableArray array];
            
            NSDictionary *relationsMetadata                 = [[self entity] relationshipsByName];
            NSRelationshipDescription *relationDescription  = [relationsMetadata objectForKey:propertyName];
            
            if (!relationDescription) continue;
            
            NSEntityDescription *relationEntity             = [relationDescription destinationEntity];
            
            [relations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                id propertyValue = [[AEManagedObject alloc] initWithEntity:relationEntity
                                            insertIntoManagedObjectContext:mainThreadContext()];
                [propertyValue updateFromJSONObject:obj withRelations:NO];
                [accumulator addObject:propertyValue];
                [propertyValue release];
            }];
            
            [self setValue:[NSSet setWithArray:accumulator] forKey:propertyName];
            
        } else if ([NSClassFromString(propertyType) isSubclassOfClass:[AEManagedObject class]]) {
                
            id propertyValue = [NSEntityDescription insertNewObjectForEntityForName:propertyType
                                                             inManagedObjectContext:self.managedObjectContext];
            [propertyValue updateFromJSONObject:jsonValue withRelations:NO];
            [self setValue:propertyValue forKey:propertyName];
        }
    }
    
    if ([self respondsToSelector:@selector(setSyncDate:)]) {
        self.syncDate = [NSDate date];
    }
    
    free(properties);
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
        AEManagedObject *entity = [[[class alloc] initFromJSONObject:json inManagedObjectContext:context] autorelease]; 
        return entity;
    }
    
    return nil;
}

+ (AEManagedObject *)createOrUpdateFromJsonObject:(id)json inManagedObjectContext:(NSManagedObjectContext *)context {
    id curId = [json valueForKeyPath:[self mappedPropertyNameForPropertyName:@"id"]];
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

+ (BOOL)requiresPersistence {
    return YES;
}

+ (NSDictionary *)propertyMappings {
    return nil;
}

+ (void)formatJson:(NSArray *)items success:(void (^)(NSArray *entities))success {    

    NSManagedObjectContext *context = [[AECoreDataHelper createManagedObjectContext] retain];
    [AECoreDataHelper addMergeNotificationForMainContext:context];
    NSMutableArray *result = [NSMutableArray array];
    
    for (id jsonString in items) {                                        
        AEManagedObject *entity = [self createOrUpdateFromJsonObject:jsonString
                                              inManagedObjectContext:context];
        [result addObject:entity];                     
    }
    
    if ([self requiresPersistence]) {
        [AECoreDataHelper save:context];
    }

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
                items = [responseObject valueForKey:[self jsonRoot]];
            }
            
            if ([items isKindOfClass:NSArray.class] &&
                [items count] > 0 &&
                ![[items objectAtIndex:0] isKindOfClass:[NSNull class]]) { //JSONKit returns sometimes array with NSNull
                
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
