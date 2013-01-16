//
//  NSArray+NSArray_orderBy.h
//  cska
//
//  Created by Arthur Evstifeev on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (orderBy)

- (NSArray *)orderBy:(NSString *)firstSortingParam, ... NS_REQUIRES_NIL_TERMINATION;
- (NSArray *)orderByDescriptors:(NSSortDescriptor *)firstDescriptor, ... NS_REQUIRES_NIL_TERMINATION;
- (id)first;

@end
