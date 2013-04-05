//
// AEManagedObject+AEJSONSerialization.h
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

#import "AEManagedObject.h"

@interface AEManagedObject (AEJSONSerialization)

#pragma mark - Initialization
/**
 Initializes new managed object from json object in requested context.
 
 @param jsonObject Parsed JSON dictionary.
 @param context A context used for managed object.
 
 @return An initialized object with property values from json object in requested context.
 */
- (id)initFromJSONObject:(id)jsonObject inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 Factory method for creating or updating managed object from json object in requested context with relations.
 
 @param json Parsed JSON dictionary.
 @param context A context used for managed object.
 
 @discussion This method will request from coordinator saved object by field `id`. This behaviour can be redefined via mapping.
 
 @return Created or updated managed object with property values from json object in requested context.
 */
+ (AEManagedObject *)createOrUpdateFromJsonObject:(id)json inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 Factory method for creating or updating managed object from json object in requested context.
 
 @param json Parsed JSON dictionary.
 @param withRelations Defines wheither result object should contain deserialized relations.
 @param context A context used for managed object.
 
 @discussion This method will request from coordinator saved object by field `id`. This behaviour can be redefined via mapping.
 
 @return Created or updated managed object with property values from json object in requested context.
 */
+ (AEManagedObject *)createOrUpdateFromJsonObject:(id)json
                                    withRelations:(BOOL)withRelations
                           inManagedObjectContext:(NSManagedObjectContext *)context;

#pragma mark - Deserialization
/**
 Deserializes managed object from json object with relations.
 
 @param jsonObject Parsed JSON dictionary.
 @param withRelations Defines wheither result object should contain deserialized relations.
 
 @discussion This method provides only 1 level depth of relations deserialization.
 
 @return A managed object with property values from json object.
 */
- (void)updateFromJSONObject:(id)jsonObject withRelations:(BOOL)withRelations;

/**
 Deserializes managed object from json object with relations.
 
 @param jsonObject Parsed JSON dictionary.
 
 @return A managed object with property values from json object.
 */
- (void)updateFromJSONObject:(id)jsonObject;

#pragma mark - Serialization
/**
 Serializes managed object into json object with respect to json root name and relations.
 
 @param withRootObject Defines wheither result object should contain root object.
 @param withRelations Defines wheither result object should contain serialized relations.
 
 @discussion This method provides only 1 level depth of relations serialization.
 
 @return A disctionary with serialized object.
 */
- (id)toJSONObjectWithRootObject:(BOOL)withRootObject andRelations:(BOOL)withRelations;

/**
 Serializes managed object into json object with root object and 1 level of relations.
 
 @return An disctionary with serialized object.
 */
- (id)toJSONObject;

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
 
 @discussion By default expect json objects without root.
 
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
