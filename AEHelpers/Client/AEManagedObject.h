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
#import "AFHTTPClient.h"
#import "AECoreDataHelper.h"

/**
 Common base class for all REST-based managed objects. Solves general REST-consuming tasks:
 
 - JSON serialization and desirialization. Fast serialization process with type-checking and mappings.
 - Fetching remote items. All actions performed in background (using GCD), main thread active only when synthesizing saved entites from objectID
 - Simplified fetch requests. ActiveRecord-like behaviour.
 - Handles json root objects, dates and allow to create temporary requested entities.
 
 @discussion Some methods use property `id` (server side id of the entity). You should create this property with dynamic accessors.
 */
@interface AEManagedObject : NSManagedObject
/**
 Updated timestamp of the entity. Changes during deserialization.
 */
@property(retain, nonatomic) NSDate *syncDate;

#pragma mark - Initialization
/**
 Initializes new managed object from json object in requested context.
 
 @param jsonObject Parsed JSON dictionary.
 @param context A context used for managed object.
 
 @return An initialized object with property values from json object in requested context.
 */
- (id)initFromJSONObject:(id)jsonObject inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 Factory method for creating or updating managed object from json object in requested context.
 
 @param json Parsed JSON dictionary.
 @param context A context used for managed object.
 
 @discussion This method will request from coordinator saved object by field `id`. This behaviour can be redefined via mapping.
 
 @return Created or updated managed object with property values from json object in requested context.
 */
+ (AEManagedObject *)createOrUpdateFromJsonObject:(id)json inManagedObjectContext:(NSManagedObjectContext *)context;

#pragma mark - JSON serializaiton
/**
 Deserializes managed object from json object.
 
 @param jsonObject Parsed JSON dictionary.
 
 @return A string with serialized object.
 */
- (void)updateFromJSONObject:(id)jsonObject;

/**
 Serializes managed object into json object with respec to json root name and relations.
 
 @param withRootObject Defines wheither result object should contain root object.
 @param withRelations Defines wheither result object should contain serialized associaitions.
 
 @discussion This method provides only 1 level depth of relations serilization.
 
 @return A string with serialized object.
 */
- (id)toJSONObjectWithRootObject:(BOOL)withRootObject andRelations:(BOOL)withRelations;

/**
 Serializes managed object into json object with root object and 1 level of relations.
 
 @return A string with serialized object.
 */
- (id)toJSONObject;

#pragma mark - Remote fetch
/**
 Performs GET request with path and parameters via provided client, deserializes response in background.
 
 @param client `AFHTTPClient` subclass to perform request.
 @param path Requested path.
 @param parameters Request parameters (query string).
 @param success A block, will be invoked with success operation.
 @param failure A block, will be invoked with failed operation.
 */
+ (void)fetchWithClient:(AFHTTPClient *)client
                   path:(NSString *)path 
             parameters:(NSDictionary *)parameters                
                success:(void (^)(NSArray *entities))success 
                failure:(void (^)(NSError *error))failure;

/**
 Performs GET request with path and parameters via provided client, deserializes response in background. Allowes to acces to the plain json response.
 
 @param client `AFHTTPClient` subclass to perform request.
 @param path Requested path.
 @param parameters Request parameters (query string).
 @param jsonResponse A block, will be invoked after receiving json response.
 @param success A block, will be invoked with success operation.
 @param failure A block, will be invoked with failed operation.
 */
+ (void)fetchWithClient:(AFHTTPClient *)client
                   path:(NSString *)path 
             parameters:(NSDictionary *)parameters  
           jsonResponse:(void (^)(id json))jsonResponse
                success:(void (^)(NSArray *entities))success 
                failure:(void (^)(NSError *error))failure;

#pragma mark - Local fetch (new syntax)
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

@interface AEManagedObject (Pivate)
/**
 Defines date formatter used to parse date strings to `NSDate`
 
 @discussion By default uses POSIX date formatter. Identifies fields to parse via objective-c runtime library (by field type).
 
 @return A singleton instance of the date formatter.
 */
+ (NSDateFormatter *)dateFormatter;

/**
 Defines root object of the json object.
 
 @discussion By default looks for `data` object.
 
 @return Root object name for json serialization/deserialization.
 */
+ (NSString *)jsonRoot;

/**
 Defines if object should be saved after serialization.
 
 @discussion By default `YES`.
 
 @return `YES` if object should be saved, otherwise `NO`.
 */
+ (BOOL)requiresPersistence;

/**
 Defines property mappings between managed object and json object.
 
 @discussion By default we are looking for property in json object with the same name as on managed object. You can redefined this looking proccess by providing mappings dictionary, where key defines property to remap(managed object property) and value defines property to map to(json object property). You don't need to define mapping for the properties with same name in managed and json objects.
 
 @return A dictionary with mappings.
 */
+ (NSDictionary *)propertyMappings;
@end
