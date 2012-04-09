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
        if ([CoreDataHelper persistentStoreCoordinator] != nil)
        {
            _managedObjectContext = [[NSManagedObjectContext alloc] init];
            [_managedObjectContext setPersistentStoreCoordinator:[CoreDataHelper persistentStoreCoordinator]];  
        }
    });        
    
    return _managedObjectContext;
}

+ (NSManagedObjectModel *)managedObjectModel {
    static NSManagedObjectModel *_managedObjectModel;    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:scheme withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];  
    });
    return _managedObjectModel;
}

#if TARGET_OS_IPHONE
+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    static NSPersistentStoreCoordinator *_persistentStoreCoordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* appPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        appPath = [appPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", scheme]];            
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
#if OCUNIT
        if (![_persistentStoreCoordinator addPersistentStoreWithType: NSInMemoryStoreType
                                                      configuration: nil
                                                                URL: nil
                                                            options: nil 
                                                              error: &error])
#else
            NSURL *storeURL = [NSURL fileURLWithPath:appPath isDirectory:NO];            
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
                                                      configuration:nil 
                                                                URL:storeURL 
                                                            options:nil 
                                                              error:&error])
#endif                            
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    });
    return _persistentStoreCoordinator;
}
#else
+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    static NSPersistentStoreCoordinator *persistentStoreCoordinator;
    
    @synchronized(self)
    {
        if (!persistentStoreCoordinator) {                        
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSURL *libraryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
            NSURL *applicationFilesDirectory = [libraryURL URLByAppendingPathComponent:scheme];
            NSError *error = nil;
            
            NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:&error];
            
            if (!properties) {
                BOOL ok = NO;
                if ([error code] == NSFileReadNoSuchFileError) {
                    ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
                }
                if (!ok) {
                    [[NSApplication sharedApplication] presentError:error];
                    return nil;
                }
            }
            else {
                if ([[properties objectForKey:NSURLIsDirectoryKey] boolValue] != YES) {
                    // Customize and localize this error.
                    NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]]; 
                    
                    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                    [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
                    error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
                    
                    [[NSApplication sharedApplication] presentError:error];
                    return nil;
                }
            }
            
            NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.storedata", scheme]];
            NSLog(@"store url %@", url.absoluteString);
            persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
            if (![persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
                [[NSApplication sharedApplication] presentError:error];
                [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                return nil;
            }
        }        
        return persistentStoreCoordinator;
    }
}
#endif

+ (NSManagedObjectContext *)createManagedObjectContext {

    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        managedObjectContext = [[[NSManagedObjectContext alloc] init] autorelease];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];  
        return managedObjectContext;
    }
    return nil;
}

+ (NSArray*)requestResult:(NSFetchRequest*)request managedObjectContext:(NSManagedObjectContext*)managedObjectContext {
    NSError* err = nil;
    NSArray* result = [managedObjectContext executeFetchRequest:request error:&err];
    
    if (err) {
        //NSLog(@"error occuried %@", err);
        return nil;
    }
    
    return result;
}

+ (id)requestFirstResult:(NSFetchRequest*)request managedObjectContext:(NSManagedObjectContext*)managedObjectContext {
    NSError* err = nil;
    
    NSArray* result = [managedObjectContext executeFetchRequest:request error:&err];
    
    if (err || result.count == 0) {
        //NSLog(@"error occuried %@ or empty result", err);
        return nil;
    }
    
    return [result objectAtIndex:0];
}

+ (void)managedObjectContextDidSave:(NSNotification*)notification {
    NSManagedObjectContext* context = [CoreDataHelper createManagedObjectContext];
    if (context) {
        [context performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:) 
                                  withObject:notification waitUntilDone:NO];
    }
}

+ (BOOL)save:(NSManagedObjectContext*)managedObjectContext {

    if (managedObjectContext.hasChanges) {
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
        
        NSError *error = nil;
        if (![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@", error.localizedDescription);
            return NO;
        }        
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
        return YES;
    }
        
    return NO;
}

+ (NSFetchRequest*)requestEntityWithName:(NSString*)entityName 
                           withPredicate:(NSPredicate*)predicate
                   andSortingDescriptors:(NSArray*)sortingDescriptors
                  inManagedObjectContext:(NSManagedObjectContext*)context {
    
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    
    NSEntityDescription* entityDesc = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    [fetchRequest setEntity:entityDesc]; 
    
    if (predicate)
        [fetchRequest setPredicate:predicate];
    
    if (sortingDescriptors)
        [fetchRequest setSortDescriptors:sortingDescriptors];
    
    return fetchRequest;
}

+ (NSFetchRequest*)requestEntityWithDesctiption:(NSEntityDescription*)entityDescription 
                           withPredicate:(NSPredicate*)predicate
                   andSortingDescriptors:(NSArray*)sortingDescriptors
                  inManagedObjectContext:(NSManagedObjectContext*)context {
    
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];        
    [fetchRequest setEntity:entityDescription]; 
    
    if (predicate)
        [fetchRequest setPredicate:predicate];
    
    if (sortingDescriptors)
        [fetchRequest setSortDescriptors:sortingDescriptors];
    
    return fetchRequest;
}

@end
