//
//  CommonEntity.m
//  cska
//
//  Created by Arthur Evstifeev on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CommonEntity.h"
#import <objc/runtime.h>

#import "CommonClient.h"

@implementation CommonEntity
@dynamic syncDate;

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

- (id)initFromJSON:(id)json withEntity:(NSEntityDescription*)entityDescription inManagedObjectContext:(NSManagedObjectContext*)context {
    self = [super initWithEntity:entityDescription insertIntoManagedObjectContext:context];
    if (self) {
        [self updateFromJSON:json];
    }
    return self;    
}

- (NSString*)toJSON {
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

- (void)formatCell:(UIView *)cell {}

@end