//
//  NSArray+NSArray_orderBy.m
//  cska
//
//  Created by Arthur Evstifeev on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSArray+orderBy.h"

@implementation NSArray (orderBy)

- (id)first {
    if (self && self.count > 0)
        return [self objectAtIndex:0];
    
    return nil;
}

- (NSArray*)orderBy:(NSString*)firstSortingParam, ... {
    
    va_list argumentList;    
    va_start(argumentList, firstSortingParam);
    
    NSMutableArray* descriptorsArray = [NSMutableArray array];  
    for (NSString *arg = firstSortingParam; arg != nil; arg = va_arg(argumentList, NSString*))
    {
        [descriptorsArray addObject:[NSSortDescriptor sortDescriptorWithKey:firstSortingParam ascending:YES]];
    }
    va_end(argumentList);
    
    return [self sortedArrayUsingDescriptors:descriptorsArray];
}

- (NSArray*)orderByDescriptors:(NSSortDescriptor*)firstDescriptor, ... {
    
    va_list argumentList;    
    va_start(argumentList, firstDescriptor);
    
    NSMutableArray* descriptorsArray = [NSMutableArray array];  
    for (NSSortDescriptor *arg = firstDescriptor; arg != nil; arg = va_arg(argumentList, NSSortDescriptor*))
    {
        [descriptorsArray addObject:arg];
    }
    va_end(argumentList);
    
    return [self sortedArrayUsingDescriptors:descriptorsArray];
}

@end
