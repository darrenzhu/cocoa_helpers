//
//  NSManagedObjectContext+Helpers.h
//  cska
//
//  Created by Arthur Evstifeev on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (Helpers)

- (NSEntityDescription*)descriptionForName:(NSString*)entityName;

@end
