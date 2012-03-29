//
//  CoreDataHelper.h
//  KageClient
//
//  Created by Arthur Evstifeev on 02.09.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataHelper : NSObject

+ (NSManagedObjectModel *)managedObjectModel;
+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
+ (NSManagedObjectContext *)createManagedObjectContext;

+ (NSArray*)requestResult:(NSFetchRequest*)request managedObjectContext:(NSManagedObjectContext*)managedObjectContext;
+ (id)requestFirstResult:(NSFetchRequest*)request managedObjectContext:(NSManagedObjectContext*)managedObjectContext;
+ (BOOL)save:(NSManagedObjectContext*)managedObjectContext;

+ (NSFetchRequest*)requestEntityWithName:(NSString*)entityName 
                           withPredicate:(NSPredicate*)predicate
                   andSortingDescriptors:(NSArray*)sortingDescriptors
                  inManagedObjectContext:(NSManagedObjectContext*)context;

+ (NSFetchRequest*)requestEntityWithDesctiption:(NSEntityDescription*)entityDescription 
                                  withPredicate:(NSPredicate*)predicate
                          andSortingDescriptors:(NSArray*)sortingDescriptors
                         inManagedObjectContext:(NSManagedObjectContext*)context;

@end
