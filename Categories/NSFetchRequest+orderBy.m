//
//  NSFetchRequest+orderBy.m
//  Goguruz
//
//  Created by Arthur Evstifeev on 6/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSFetchRequest+orderBy.h"

@implementation NSFetchRequest (orderBy)

- (NSFetchRequest*)orderBy:(NSString*)firstSortingParam, ... {
    
    va_list argumentList;    
    va_start(argumentList, firstSortingParam);
    
    NSMutableArray* descriptorsArray = [NSMutableArray array];  
    for (NSString *arg = firstSortingParam; arg != nil; arg = va_arg(argumentList, NSString*))
    {
        [descriptorsArray addObject:[NSSortDescriptor sortDescriptorWithKey:firstSortingParam ascending:YES]];
    }
    va_end(argumentList);
    
    [self setSortDescriptors:descriptorsArray];    
    return self;
}

- (NSFetchRequest*)orderByDescriptors:(NSSortDescriptor*)firstDescriptor, ... {
    
    va_list argumentList;    
    va_start(argumentList, firstDescriptor);
    
    NSMutableArray* descriptorsArray = [NSMutableArray array];  
    for (NSSortDescriptor *arg = firstDescriptor; arg != nil; arg = va_arg(argumentList, NSSortDescriptor*))
    {
        [descriptorsArray addObject:arg];
    }
    va_end(argumentList);
    
    [self setSortDescriptors:descriptorsArray];    
    return self;
}


@end
