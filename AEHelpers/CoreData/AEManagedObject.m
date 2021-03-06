//
// AEManagedObject.m
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

@implementation AEManagedObject

#pragma mark - predefined entityId
/**
 *  Fallback for previous API
 */
+ (NSString *)entityIdPropertyName {
    return @"id";
}

#pragma mark - Local fetch
+ (NSEntityDescription *)enityDescriptionInContext:(NSManagedObjectContext *)context {
    return [NSEntityDescription entityForName:NSStringFromClass(self.class)
                       inManagedObjectContext:context];
}

+ (NSFetchRequest *)all {
    return [AECoreDataHelper requestWithPredicate:nil andSortingDescriptors:nil];;
}

+ (NSFetchRequest *)find:(id)itemId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", [self entityIdPropertyName], itemId];
    return [AECoreDataHelper requestWithPredicate:predicate andSortingDescriptors:nil];
}

+ (NSFetchRequest *)where:(NSPredicate *)wherePredicate {
    return [AECoreDataHelper requestWithPredicate:wherePredicate andSortingDescriptors:nil];
}

+ (NSArray *)requestResult:(NSFetchRequest *)request
      managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    [request setEntity:[self enityDescriptionInContext:managedObjectContext]];
    return [AECoreDataHelper requestResult:request managedObjectContext:managedObjectContext];
}

+ (id)requestFirstResult:(NSFetchRequest *)request managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    [request setFetchLimit:1];
    NSArray *result = [self requestResult:request managedObjectContext:managedObjectContext];
    
    if (result && result.count == 0) {
        return nil;
    }
    
    return [result objectAtIndex:0];
}

#pragma mark - threading helper

+ (NSArray *)managedObjectsInMainThreadWithObjectIds:(NSArray *)objectIds {
    
    NSMutableArray *resultInMainThread = [NSMutableArray array];
    for (NSManagedObjectID *objectID in objectIds) {
        
        [resultInMainThread addObject:[mainThreadContext() objectWithID:objectID]];
    }
    
    return resultInMainThread;
}

@end
