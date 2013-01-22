//
// AECoreDataHelper.h
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define mainThreadContext() [AECoreDataHelper mainThreadContext]

/**
 Set of class methods for solving common `CoreData` tasks.
 */
@interface AECoreDataHelper : NSObject

/**
 Returns singleton instance of `NSManagedObjectContext`. By convention, this context is only for the main thread.
 
 @return An managed context instance.
 */
+ (NSManagedObjectContext *)mainThreadContext;

/**
 Subscribes main thread context to merge notifications from provided thread.
 
 @param context A context object which will emit merge notifications.
 */
+ (void)addMergeNotificationForMainContext:(NSManagedObjectContext *)context;

/**
 Returns singleton instance of application object model.
 
 @discussion By converntion, application data model should be called `DataModel`.
 
 @return An instance of managed object model.
 */
+ (NSManagedObjectModel *)managedObjectModel;

/**
 Returns singleton instance of application `NSPersistentStoreCoordinator`.
 
 @discussion When OCUNIT compiler flag is defined, this method uses `NSInMemoryStoreType` storage, otherwise it uses `NSSQLiteStoreType`
 
 @return An instance of the persistence storage coordinator.
 */
+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

/**
 Creates new `NSManagedObjectContext`
 
 @return An instance of the managed context.
 */
+ (NSManagedObjectContext *)createManagedObjectContext;

/**
 Performs request in provided context.
 
 @param request A request to perform
 @param managedObjectContext A context used for request
 
 @return An array of requested objects.
 */
+ (NSArray *)requestResult:(NSFetchRequest *)request
      managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/**
 Performs request in provided context. Request will be limited by 1 object.
 
 @discussion This method will set fetchLimit to 1.
 
 @param request A request to perform
 @param managedObjectContext A context used for request
 
 @return Requested object.
 */
+ (id)requestFirstResult:(NSFetchRequest *)request
    managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/**
 Saves provided context.
 
 @param managedObjectContext A managed object context to save.
 
 @return `YES` if operation successfull, otherwise `NO`.
 */
+ (BOOL)save:(NSManagedObjectContext *)managedObjectContext;

/**
 Composes new fetch request.
 
 @param entityName Entity name to request.
 @param predicate Requests predicate
 @param sortingDescriptors An array of sorting descriptors
 @param managedObjectContext A context used for request
 
 @return A fetch request object.
 */
+ (NSFetchRequest *)requestEntityWithName:(NSString *)entityName
                            withPredicate:(NSPredicate *)predicate
                    andSortingDescriptors:(NSArray *)sortingDescriptors
                   inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 Composes new fetch request.
 
 @param entityDescription Entity description to request.
 @param predicate Requests predicate
 @param sortingDescriptors An array of sorting descriptors
 
 @discussion This method do not setup context for the request.
 
 @return A fetch request object.
 */
+ (NSFetchRequest *)requestEntityWithDesctiption:(NSEntityDescription *)entityDescription
                                   withPredicate:(NSPredicate *)predicate
                           andSortingDescriptors:(NSArray *)sortingDescriptors;

/**
 Composes new fetch request.
 
 @param predicate Requests predicate
 @param sortingDescriptors An array of sorting descriptors
 
 @discussion This method do not setup context and entity description for the request.
 
 @return A fetch request object.
 */
+ (NSFetchRequest *)requestWithPredicate:(NSPredicate *)predicate
                   andSortingDescriptors:(NSArray *)sortingDescriptors;
@end
