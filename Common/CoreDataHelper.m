//
//  CoreDataHelper.m
//  KageClient
//
//  Created by Arthur Evstifeev on 02.09.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CoreDataHelper.h"

@implementation CoreDataHelper
static NSString* scheme = @"DataModel";

+ (NSManagedObjectContext *)mainThreadContext {
    static NSManagedObjectContext *_managedObjectContext = nil;                
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSPersistentStoreCoordinator *coorditantor =
            [CoreDataHelper persistentStoreCoordinator];
        if (coorditantor) {
            _managedObjectContext = [[NSManagedObjectContext alloc] init];
            [_managedObjectContext setPersistentStoreCoordinator:coorditantor];
            [_managedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
        }
    });        
    
    return _managedObjectContext;
}

+ (void)addMergeNotificationForMainContext:(NSManagedObjectContext *)context {
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mergeChangesFromNotification:)
												 name:NSManagedObjectContextDidSaveNotification
											   object:context];
}

+ (void)mergeChangesFromNotification:(NSNotification *)notification {
    SEL action = @selector(mergeChangesFromContextDidSaveNotification:);
	[mainThreadContext() performSelectorOnMainThread:action
                                          withObject:notification 
                                       waitUntilDone:NO];
}

+ (NSManagedObjectModel *)managedObjectModel {
    static NSManagedObjectModel *_managedObjectModel;    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *modelURL = [[NSBundle bundleForClass:self.class] URLForResource:scheme
                                                                 withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];  
    });
    return _managedObjectModel;
}

+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    static NSPersistentStoreCoordinator *_persistentStoreCoordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *options =
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        
        NSError *error = nil;
        NSManagedObjectModel *model = [self managedObjectModel];
        _persistentStoreCoordinator =
            [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
#if OCUNIT
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                                                      configuration:nil
                                                                URL:nil
                                                            options:options
                                                              error:&error])
#else
        NSString *fileName = [NSString stringWithFormat:@"%@.sqlite", scheme];
        NSArray *pathes =
            NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *appPath = [pathes lastObject];
        appPath = [appPath stringByAppendingPathComponent:fileName];
        NSURL *storeURL = [NSURL fileURLWithPath:appPath isDirectory:NO];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                      configuration:nil 
                                                                URL:storeURL 
                                                            options:options 
                                                              error:&error])
#endif                            
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    });
    return _persistentStoreCoordinator;
}

+ (NSManagedObjectContext *)createManagedObjectContext {
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[[NSManagedObjectContext alloc] init] autorelease];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];  
        return managedObjectContext;
    }
    return nil;
}

+ (NSArray *)requestResult:(NSFetchRequest *)request
      managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSError *err = nil;
    NSArray *result = [managedObjectContext executeFetchRequest:request error:&err];
    
    if (err) {
        NSLog(@"error occuried %@", err);
        return nil;
    }
    
    return result;
}

+ (id)requestFirstResult:(NSFetchRequest *)request
    managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    [request setFetchLimit:1];
    NSArray *result = [self requestResult:request managedObjectContext:managedObjectContext];
    
    if (!result || result.count == 0) {
        return nil;
    }
    
    return [result objectAtIndex:0];
}

+ (BOOL)save:(NSManagedObjectContext *)managedObjectContext {
    if (managedObjectContext.hasChanges) {        
        NSError *error = nil;
        if (![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@", error.localizedDescription);
            return NO;
        }        
        
        return YES;
    }
        
    return NO;
}

+ (NSFetchRequest *)requestEntityWithName:(NSString *)entityName
                            withPredicate:(NSPredicate *)predicate
                    andSortingDescriptors:(NSArray *)sortingDescriptors
                   inManagedObjectContext:(NSManagedObjectContext *)context {
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:entityName
                                                  inManagedObjectContext:context];
    return [self requestEntityWithDesctiption:entityDesc 
                                withPredicate:predicate 
                        andSortingDescriptors:sortingDescriptors];
}

+ (NSFetchRequest *)requestEntityWithDesctiption:(NSEntityDescription *)entityDescription 
                                   withPredicate:(NSPredicate *)predicate
                           andSortingDescriptors:(NSArray *)sortingDescriptors {
    
    NSFetchRequest *fetchRequest = [self requestWithPredicate:predicate 
                                        andSortingDescriptors:sortingDescriptors];
    [fetchRequest setEntity:entityDescription];     
    return fetchRequest;
}

+ (NSFetchRequest *)requestWithPredicate:(NSPredicate *)predicate
                   andSortingDescriptors:(NSArray *)sortingDescriptors {
    
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];        
    
    if (predicate)
        [fetchRequest setPredicate:predicate];
    
    if (sortingDescriptors)
        [fetchRequest setSortDescriptors:sortingDescriptors];
    
    return fetchRequest;
}

@end
