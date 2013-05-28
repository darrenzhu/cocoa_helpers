//
// AEManagedObject.h
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

#import "NSFetchRequest+orderBy.h"
#import "AECoreDataHelper.h"

/**
 Common base class for all REST-based managed objects. Solves general REST-consuming tasks:
 
 - JSON serialization and desirialization. Fast serialization process with type-checking and mappings.
 - Fetching remote items. All actions performed in background (using GCD), main thread active only when synthesizing saved entites from objectID
 - Simplified fetch requests. ActiveRecord-like behaviour.
 - Handles json root objects, dates and allow to create temporary requested entities.
 
 Tasks are separated by categories, so you can use only neccessary modules.
 
 @discussion Some methods use property `entityId` (server side id of the entity). You should create this property with dynamic accessors.
 */
@interface AEManagedObject : NSManagedObject

#pragma mark - Local fetch (new syntax)
/**
 Returns current class `NSEntityDescription` object.
 
 @param context An entity context.
 
 @return An entity description for current class.
 */
+ (NSEntityDescription *)enityDescriptionInContext:(NSManagedObjectContext *)context;

/**
 Creates fetch request for all objects of the current class.
 
 @return A fetch request object without predefinitions.
 */
+ (NSFetchRequest *)all;

/**
 Creates fetch request for an object with provided `id`.
 
 @discussion Respects mapping dictionary.
 
 @return A fetch request object with predicate in format `id == itemId`.
 */
+ (NSFetchRequest *)find:(id)itemId;

/**
 Creates fetch request for an objects that satisfies predicate.
 
 @return A fetch request object with provided predicate.
 */
+ (NSFetchRequest *)where:(NSPredicate *)wherePredicate;

/**
 Performs request in provided context.
 
 @discussion This methods will define entity description for the request as current class name.
 
 @param request A request to perform.
 @param managedObjectContext A context for request.
 
 @return An array with requested objects.
 */
+ (NSArray *)requestResult:(NSFetchRequest *)request
      managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/**
 Performs request in provided context.
 
 @discussion This methods will define entity description for the request as current class name and sets fetchLimit to 1.
 
 @param request A request to perform.
 @param managedObjectContext A context for request.
 
 @return A requested object.
 */
+ (id)requestFirstResult:(NSFetchRequest *)request
    managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end


@interface AEManagedObject (EntityId)

/**
 Objects property name that holds server-side entity id.
 
 @discussion By overriding this method you can configure actual entity id of your objects. By default this methods returns `id`.
 
 @return A property name that represents server-side entity id.
 */
+ (NSString *)entityIdPropertyName;

#pragma mark - threading helper

/**
 Returns managed objects with provided managed object ids in main thread context
 
 @param objectIds An array of managed object ids.
 */
+ (NSArray *)managedObjectsInMainThreadWithObjectIds:(NSArray *)objectIds;
    
@end
