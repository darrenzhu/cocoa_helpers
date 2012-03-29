//
//  CommonEntity.m
//  cska
//
//  Created by Arthur Evstifeev on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CommonEntity.h"
#import <objc/runtime.h>
#import "JSONKit.h"

@implementation CommonEntity

- (void)postprocessJSON:(id)json InContext:(NSManagedObjectContext*)context {}

- (void)updateFromJSON:(id)json {
    
    if (self) {
        
        unsigned int outCount;
        objc_property_t *properties = class_copyPropertyList([self class], &outCount);        
        
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];    
        
        for(int i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            
            NSString* propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
            id jsonValue = [json valueForKeyPath:propertyName];
            
            if (jsonValue != [NSNull null] && jsonValue != nil) {
                if ([propertyName isEqualToString:@"date_updated"]) {  
                    [self setValue:[dateFormatter dateFromString:jsonValue] forKey:propertyName];
                }
                else {
                    NSString* propertyAtr = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
                    if ([propertyAtr rangeOfString:@"NSString"].location != NSNotFound ||
                        [propertyAtr rangeOfString:@"NSNumber"].location != NSNotFound ||
                        [propertyAtr rangeOfString:@"NSArray"].location != NSNotFound ||
                        [propertyAtr rangeOfString:@"NSDictionary"].location != NSNotFound) {
                     
                        //if ([propertyAtr rangeOfString:NSStringFromClass([jsonValue class])].location != NSNotFound)
                            [self setValue:jsonValue forKey:propertyName];   
                    }
                }
            }
        }
        
        
        NSNumber* jsonValue = [json valueForKeyPath:@"id"];
        if (jsonValue != nil) {
            [self setValue:jsonValue forKey:@"id"];
        }
        
        free(properties);
    }
}

- (id)initFromJSON:(id)json withEntity:(NSEntityDescription*)entityDescription inManagedObjectContext:(NSManagedObjectContext*)context {
    self = [super initWithEntity:entityDescription insertIntoManagedObjectContext:context];
    [self updateFromJSON:json];
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
