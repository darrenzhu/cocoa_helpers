//
//  NSString+NSJSONSerialization.m
//  AEHelpers
//
//  Created by Arthur Evstifeev on 15/02/13.
//
//

#import "NSJSONSerializationCategories.h"

@implementation NSString (NSJSONSerialization)

- (id)objectFromJSONString {
    return [NSJSONSerialization JSONObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding]
                                           options:0
                                             error:nil];
}

@end

@implementation NSObject (NSJSONSerialization)

- (NSString *)JSONString {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                       options:0
                                                         error:nil];
    return [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease];
}

@end