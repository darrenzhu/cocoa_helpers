//
// AECoreDataHelper.m
//
// Copyright (c) 2012 ap4y (lod@pisem.net)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AECoreDataHelper.h"

@implementation AECoreDataHelper
static NSPersistentStoreCoordinator *defaultCoordinator;

+ (NSManagedObjectContext *)mainThreadContext {
    static NSManagedObjectContext *_managedObjectContext = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSPersistentStoreCoordinator *coorditantor = defaultCoordinator;
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

+ (NSManagedObjectModel *)managedObjectModelWithSchemeName:(NSString *)scheme {
    
    NSURL *modelURL = [[NSBundle bundleForClass:self.class] URLForResource:scheme withExtension:@"momd"];
    return [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] autorelease];
}

+ (void)registerDefaultPersistenceStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        defaultCoordinator = [coordinator retain];
    });
}

+ (NSPersistentStoreCoordinator *)defaultStoreCoordinator {
    
    return defaultCoordinator;
}

+ (BOOL)addInMemoryStorage:(NSError **)error {
    
    if (!defaultCoordinator) {
        
        if (error) {
            
            NSDictionary *errorInfo = @{
                                        NSLocalizedDescriptionKey: NSLocalizedString(@"Default coordinator is not registered.", nil)
                                        };
            *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:NSCoreDataError
                                     userInfo:errorInfo];
        }
        return NO;
    }
    
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption:   [NSNumber numberWithBool:YES],
                              NSInferMappingModelAutomaticallyOption:         [NSNumber numberWithBool:YES]
                              };
    
    return [defaultCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                                            configuration:nil
                                                      URL:nil
                                                  options:options
                                                    error:error];
}

+ (BOOL)addInSQLStorageWithName:(NSString *)dbFileName error:(NSError **)error {
    
    if (!defaultCoordinator) {
        
        if (error) {
            
            NSDictionary *errorInfo = @{
                                        NSLocalizedDescriptionKey: NSLocalizedString(@"Default coordinator is not registered.", nil)
                                        };
            *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:NSCoreDataError
                                     userInfo:errorInfo];
        }
        return NO;
    }
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption:   [NSNumber numberWithBool:YES],
                              NSInferMappingModelAutomaticallyOption:         [NSNumber numberWithBool:YES]
                              };
    
    NSString *fileName = [NSString stringWithFormat:@"%@.sqlite", dbFileName];
    NSArray *pathes = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *appPath = [pathes lastObject];
    appPath = [appPath stringByAppendingPathComponent:fileName];
    NSURL *storeURL = [NSURL fileURLWithPath:appPath isDirectory:NO];
    return [defaultCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                            configuration:nil
                                                      URL:storeURL
                                                  options:options
                                                    error:error];
}

+ (NSManagedObjectContext *)createManagedObjectContext {
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *coordinator = defaultCoordinator;
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
    
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
    
    if (sortingDescriptors) {
        [fetchRequest setSortDescriptors:sortingDescriptors];
    }
    
    return fetchRequest;
}

@end
