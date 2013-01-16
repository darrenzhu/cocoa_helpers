//
//  NSFetchRequest+orderBy.h
//
//  Created by Arthur Evstifeev on 6/14/12.
//

#import <CoreData/CoreData.h>

@interface NSFetchRequest (orderBy)

- (NSFetchRequest *)orderBy:(NSString *)firstSortingParam, ... NS_REQUIRES_NIL_TERMINATION;
- (NSFetchRequest *)orderByDescriptors:(NSSortDescriptor *)firstDescriptor, ... NS_REQUIRES_NIL_TERMINATION;

@end
