//
// AEManagedObject+AEJSONSerialization.m
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

#import "AEManagedObject+AEJSONSerialization.h"
#import "NSJSONSerializationCategories.h"

@implementation AEManagedObject (AEJSONSerialization)

+ (dispatch_queue_t)jsonQueue {
    static dispatch_queue_t _jsonQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _jsonQueue = dispatch_queue_create("com.ae.json_proccess", DISPATCH_QUEUE_SERIAL);
    });
    
    return _jsonQueue;
}

#pragma mark - entity settings

+ (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *_rfc3339DateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLocale *enUSPOSIXLocale;
        
        _rfc3339DateFormatter   = [[NSDateFormatter alloc] init];
        enUSPOSIXLocale         = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        
        [_rfc3339DateFormatter setLocale:enUSPOSIXLocale];
        [_rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"];
        [_rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    });
    
    return _rfc3339DateFormatter;
}

+ (NSString *)jsonRoot {
    return nil;
}

+ (BOOL)requiresPersistence {
    return YES;
}

+ (NSDictionary *)propertyMappings {
    return nil;
}

#pragma mark - Initialization

- (id)initFromJSONObject:(id)jsonObject inManagedObjectContext:(NSManagedObjectContext *)context {
    NSEntityDescription *description = [self.class enityDescriptionInContext:context];
    self = [self initWithEntity:description insertIntoManagedObjectContext:context];
    if (self) {
        [self updateFromJSONObject:jsonObject];
    }
    return self;
}

+ (instancetype)createOrUpdateFromJsonObject:(id)json inManagedObjectContext:(NSManagedObjectContext *)context {
    
    return [self createOrUpdateFromJsonObject:json withRelations:YES inManagedObjectContext:context];
}

+ (instancetype)createOrUpdateFromJsonObject:(id)json
                               withRelations:(BOOL)withRelations
                      inManagedObjectContext:(NSManagedObjectContext *)context {
    
    id curId = [json valueForKeyPath:[self mappedPropertyNameForPropertyName:[self entityIdPropertyName]]];
    if (!curId) {
        return [self createFromJsonObject:json inManagedObjectContext:context];;
    }
    
    NSFetchRequest *findRequest = [self find:curId];
    [findRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([self class])
                                       inManagedObjectContext:context]];
    AEManagedObject *entity     = [AECoreDataHelper requestFirstResult:findRequest managedObjectContext:context];
    
    if (!entity) {
        return [self createFromJsonObject:json inManagedObjectContext:context];
    }
    
    [entity updateFromJSONObject:json withRelations:withRelations];
    return entity;
}

+ (NSArray *)managedObjectsFromJson:(NSArray *)jsonObjects inContext:(NSManagedObjectContext *)context {
    
    [AECoreDataHelper addMergeNotificationForMainContext:context];
    NSMutableArray *result = [NSMutableArray array];
    
    for (id jsonObject in jsonObjects) {
        AEManagedObject *entity = [self createOrUpdateFromJsonObject:jsonObject inManagedObjectContext:context];
        [result addObject:entity];
    }
    
    if ([self requiresPersistence]) {
        [AECoreDataHelper save:context];
    }
    
    return result;
}

+ (void)managedObjectsFromJson:(NSArray *)jsonObjects block:(void (^)(NSArray *managedObjects))block {
    
    dispatch_async([self jsonQueue], ^{
        
        NSManagedObjectContext *context = [AECoreDataHelper createManagedObjectContext];
        NSArray *managedObjects         = [self managedObjectsFromJson:jsonObjects inContext:context];
        
        NSArray *objectIds = [managedObjects valueForKeyPath:@"objectID"];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            block([self managedObjectsInMainThreadWithObjectIds:objectIds]);
        });
    });
}

#pragma mark - serialization

- (id)toJSONObject {
    return [self toJSONObjectWithRootObject:YES andRelations:YES];
}

/**
 This method support serialization with 1 level depth, because reverse association can produce infinity loops.
 */
- (NSDictionary *)toJSONObjectWithRootObject:(BOOL)withRootObject andRelations:(BOOL)withRelations {
    
    NSArray *attributes, *relations;
    NSMutableDictionary *jsonObject;
    
    attributes  = [[[self entity] attributesByName] allKeys];
    jsonObject  = [NSMutableDictionary dictionary];
    [attributes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSString *mappedKey = [[self class] mappedPropertyNameForPropertyName:obj];
        id propertyValue    = [self valueForKey:obj];
        if ([propertyValue isKindOfClass:[NSDate class]]) {
            
            [jsonObject setObject:[[[self class] dateFormatter] stringFromDate:propertyValue] forKey:mappedKey];
            return;
        }
        
        if (propertyValue) [jsonObject setObject:propertyValue forKey:mappedKey];
    }];
    
    if (withRelations) {
        
        relations = [[[self entity] relationshipsByName] allKeys];
        [relations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            id propertyValue    = [self valueForKey:obj];
            NSString *mappedKey = [[self class] mappedPropertyNameForPropertyName:obj];
            
            if ([propertyValue isKindOfClass:[NSSet class]] || [propertyValue isKindOfClass:[NSOrderedSet class]]) {
                
                /* NSOrderedSet is not a subclass of NSSet */
                NSSet *manyAssociations     = (NSSet *)propertyValue;
                NSMutableArray *accumulator = [NSMutableArray array];
                [manyAssociations enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                    
                    if ([obj respondsToSelector:@selector(toJSONObjectWithRootObject:andRelations:)]) {
                        [accumulator addObject:[obj toJSONObjectWithRootObject:NO andRelations:NO]];
                    }
                }];
                
                if ([accumulator count] > 0) [jsonObject setValue:accumulator forKey:mappedKey];
                
            } else if ([propertyValue respondsToSelector:@selector(toJSONObjectWithRootObject:andRelations:)]) {
                
                id relationValue = [propertyValue toJSONObjectWithRootObject:NO andRelations:NO];
                if (relationValue) [jsonObject setValue:relationValue forKey:mappedKey];
            }
        }];
    }
    
    if (withRootObject && [[self class] jsonRoot]) {
        
        return @{ [[self class] jsonRoot]: jsonObject };
    }
    
    return jsonObject;
}

#pragma mark - deserialization

- (void)updateFromJSONObject:(id)jsonObject {
    [self updateFromJSONObject:jsonObject withRelations:YES];
}

- (void)updateFromJSONObject:(id)jsonObject withRelations:(BOOL)withRelations {
    if (!self || !jsonObject) return;
    
    NSDictionary *attributes, *relations;
    attributes  = [[self entity] attributesByName];
    [attributes enumerateKeysAndObjectsUsingBlock:^(id name, id attribute, BOOL *stop) {
        
        NSString *mappedKey     = [[self class] mappedPropertyNameForPropertyName:name];
        id jsonValue            = [jsonObject valueForKey:mappedKey];
        NSAttributeType type    = [attribute attributeType];
        
        if ([jsonValue isEqual:[NSNull null]] || !jsonValue) return;
        if (type == NSDateAttributeType && [[self class] dateFormatter] && [jsonValue isKindOfClass:[NSString class]]) {
            
            [self setValue:[[[self class] dateFormatter] dateFromString:jsonValue] forKey:name];
            return;
        }
        
        if ([[jsonValue class] isSubclassOfClass:NSClassFromString([attribute attributeValueClassName])]) {
            
            [self setValue:jsonValue forKey:name];
        }
    }];
    
    if (withRelations) {
        
        relations = [[self entity] relationshipsByName];
        [relations enumerateKeysAndObjectsUsingBlock:^(id name, NSRelationshipDescription *relation, BOOL *stop) {
            
            NSString *mappedKey     = [[self class] mappedPropertyNameForPropertyName:name];
            id jsonValue            = [jsonObject valueForKey:mappedKey];
            if ([jsonValue isEqual:[NSNull null]] || !jsonValue) return;
            
            if ([relation isToMany]) {
                
                if (![jsonValue isKindOfClass:[NSArray class]] || [jsonValue count] <= 0) return;
                
                NSSet *manyRelation = [self manyRelationsFromJson:jsonValue
                                                  forPropertyName:name
                                            inManagedObjectContet:self.managedObjectContext];
                if (!manyRelation) return;
                
                [self setValue:manyRelation forKey:name];
                
            } else {
                
                NSEntityDescription *entity = [relation destinationEntity];
                Class destinationClass      = NSClassFromString([entity managedObjectClassName]);
                if (!destinationClass || ![destinationClass isSubclassOfClass:[AEManagedObject class]]) return;
                
                id propertyValue = [destinationClass createOrUpdateFromJsonObject:jsonValue
                                                                    withRelations:NO
                                                           inManagedObjectContext:self.managedObjectContext];
                if (propertyValue) [self setValue:propertyValue forKey:name];
            }
        }];
    }
}

#pragma mark - private

+ (instancetype)createFromJsonObject:(id)json inManagedObjectContext:(NSManagedObjectContext *)context {
    Class class = self.class;
    
    if (class) {
        AEManagedObject *entity = [[class alloc] initFromJSONObject:json inManagedObjectContext:context];
        return entity;
    }
    
    return nil;
}

+ (NSString *)mappedPropertyNameForPropertyName:(NSString *)propertyName {
    NSDictionary *mappingsDictionary = [[self class] propertyMappings];
    NSString *mappedProperty;
    if (mappingsDictionary && (mappedProperty = [mappingsDictionary objectForKey:propertyName])) {
        return mappedProperty;
    }
    
    return propertyName;
}

- (NSSet *)manyRelationsFromJson:(id)jsonObject
                 forPropertyName:(NSString *)propertyName
           inManagedObjectContet:(NSManagedObjectContext *)context {
    
    NSArray *relations                              = (NSArray *)jsonObject;
    NSMutableArray *accumulator                     = [NSMutableArray array];
    
    NSDictionary *relationsMetadata                 = [[self entity] relationshipsByName];
    NSRelationshipDescription *relationDescription  = [relationsMetadata objectForKey:propertyName];
    
    if (!relationDescription) return nil;
    
    NSEntityDescription *relationEntity             = [relationDescription destinationEntity];
    Class managedObjectClass                        = NSClassFromString([relationEntity managedObjectClassName]);
    [relations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        id propertyValue = [managedObjectClass createOrUpdateFromJsonObject:obj
                                                              withRelations:NO
                                                     inManagedObjectContext:context];
        [accumulator addObject:propertyValue];
    }];
    
    return [NSSet setWithArray:accumulator];
}

@end
