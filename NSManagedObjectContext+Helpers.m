//
//  NSManagedObjectContext+Helpers.m
//  cska
//
//  Created by Arthur Evstifeev on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSManagedObjectContext+Helpers.h"

@implementation NSManagedObjectContext (Helpers)

- (NSEntityDescription*)descriptionForName:(NSString*)entityName {
    return [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
}

@end
