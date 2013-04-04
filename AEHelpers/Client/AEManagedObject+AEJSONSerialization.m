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
#import <objc/runtime.h>
#import "NSJSONSerializationCategories.h"

@implementation NSManagedObject (AEJSONSerialization)

#pragma mark - Initialization
- (id)initFromJSONObject:(id)jsonObject inManagedObjectContext:(NSManagedObjectContext *)context {
    NSEntityDescription *description = [self.class enityDescriptionInContext:context];
    self = [self initWithEntity:description insertIntoManagedObjectContext:context];
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

+ (AEManagedObject *)createOrUpdateFromJsonObject:(id)json
                           inManagedObjectContext:(NSManagedObjectContext *)context {
    
    return [self createOrUpdateFromJsonObject:json withRelations:YES inManagedObjectContext:context];
}

+ (AEManagedObject *)createOrUpdateFromJsonObject:(id)json
                                    withRelations:(BOOL)withRelations
                           inManagedObjectContext:(NSManagedObjectContext *)context {
    
    id curId = [json valueForKeyPath:[self mappedPropertyNameForPropertyName:@"id"]];
    if (!curId) {
        return [self createFromJsonObject:json inManagedObjectContext:context];;
    }
    
    NSFetchRequest *findRequest = [AEManagedObject find:curId];
    [findRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([self class])
                                       inManagedObjectContext:context]];
    AEManagedObject *entity     = [AECoreDataHelper requestFirstResult:findRequest managedObjectContext:context];
    
    if (!entity) {
        return [self createFromJsonObject:json inManagedObjectContext:context];
    }
    
    [entity updateFromJSONObject:json withRelations:withRelations];
    return entity;
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
    
    unsigned int outCount;
    objc_property_t *properties = [self classPropertiesWithOutCount:&outCount];
    
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
            
            NSSet *manyRelation = [self manyRelationsFromJson:jsonValue
                                              forPropertyName:propertyName
                                        inManagedObjectContet:self.managedObjectContext];
            if (!manyRelation) continue;
            
            [self setValue:manyRelation forKey:propertyName];
            
        } else if ([NSClassFromString(propertyType) isSubclassOfClass:[AEManagedObject class]]) {
            
            id propertyValue = [NSClassFromString(propertyType) createOrUpdateFromJsonObject:jsonValue
                                                                               withRelations:NO
                                                                      inManagedObjectContext:self.managedObjectContext];
            [self setValue:propertyValue forKey:propertyName];
        }
    }
    
    free(properties);
}

#pragma mark - private
+ (NSString *)mappedPropertyNameForPropertyName:(NSString *)propertyName {
    NSDictionary *mappingsDictionary = [[self class] propertyMappings];
    NSString *mappedProperty;
    if (mappingsDictionary && ( mappedProperty = [mappingsDictionary objectForKey:propertyName] )) {
        return mappedProperty;
    }
    
    return propertyName;
}

- (objc_property_t *)classPropertiesWithOutCount:(unsigned int *)outCount {
    
    unsigned int selfOutCount, superOutCount;
    objc_property_t *selfProperties, *superProperties, *properties;
    size_t selfPropertiesSize, superPropertiesSize;
    
    superProperties = NULL;
    superOutCount   = 0;
    
    selfProperties  = class_copyPropertyList([self class], &selfOutCount);
    
    if ( [self superclass] != [AEManagedObject class] ) {
        superProperties = class_copyPropertyList([self superclass], &superOutCount);
    }
    
    selfPropertiesSize   = sizeof(objc_property_t) * selfOutCount;
    superPropertiesSize  = sizeof(objc_property_t) * superOutCount;
    
    properties = malloc(selfPropertiesSize + superPropertiesSize);
    memcpy(properties, selfProperties, selfPropertiesSize);
    free(selfProperties);
    
    if (superProperties) {
        memcpy(properties + selfOutCount, superProperties, superPropertiesSize);
        free(superProperties);
    }
    
    if (outCount) {
        *outCount = selfOutCount + superOutCount;
    }
    
    return properties;
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
