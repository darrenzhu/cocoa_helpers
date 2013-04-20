//
// AEManagedObject+AERemoteFetch.m
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

#import "AEManagedObject+AERemoteFetch.h"
#import "AEManagedObject+AEJSONSerialization.h"

#import "AFHTTPRequestOperation.h"
#import "AEManagedObjectsCache.h"

@implementation AEManagedObject (AERemoteFetch)

/**
 With this entity id we will be checking for unsaved entities (decision POST/PUT). Check against string.
 */
static NSString * const kUnsavedClientSideEntityId = @"0";
static NSString * const kEtagKeyIdentifier         = @"Etag";

+ (void)fetchWithClient:(AFHTTPClient *)client
                   path:(NSString *)path
             parameters:(NSDictionary *)parameters
                success:(void (^)(NSArray *entities))success
                failure:(void (^)(NSError *error))failure {
    
    [self fetchWithClient:client
                     path:path
               parameters:parameters
             jsonResponse:nil
                  success:success
                  failure:failure];
}

+ (void)fetchWithClient:(AFHTTPClient *)client
                   path:(NSString *)path
             parameters:(NSDictionary *)parameters
           jsonResponse:(void (^)(id json))jsonResponse
                success:(void (^)(NSArray *entities))success
                failure:(void (^)(NSError *error))failure {
    
    [client getPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!responseObject) return;
        if (jsonResponse) jsonResponse(responseObject);
        
        if (!success) return;
        if ([self cachedManagedObjectsForOperation:operation success:success]) return;
        
        NSString *etag = [[operation.response allHeaderFields] valueForKey:kEtagKeyIdentifier];
        NSArray *items = responseObject;
        if ([self jsonRoot]) {
            items = [responseObject valueForKeyPath:[self jsonRoot]];
        }
        
        if ([items isKindOfClass:[NSArray class]]) {
            
            dispatch_async([self jsonQueue], ^{
                [self formatJson:items withEtag:etag success:success];
            });
            
        } else if ([items isKindOfClass:[NSDictionary class]]) {
            
            dispatch_async([self jsonQueue], ^{
                [self formatJson:@[ items ] withEtag:etag success:success];
            });
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark - create/update

+ (void)submitRecord:(AEManagedObject *)record
          withClient:(AFHTTPClient *)client
                path:(NSString *)path
             success:(void (^)(id entity))success
             failure:(void (^)(NSError *error))failure {
    
    void (^successBlock)(AFHTTPRequestOperation *operation, id responseObject) =
    ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *jsonObject = responseObject;
        if ([[self class] jsonRoot]) {
            jsonObject = [responseObject valueForKey:[[self class] jsonRoot]];
        }
        
        if (![jsonObject isKindOfClass:[NSDictionary class]]) return;
        
        dispatch_async([[self class] jsonQueue], ^{
            NSManagedObjectContext *context = [AECoreDataHelper createManagedObjectContext];
            [AECoreDataHelper addMergeNotificationForMainContext:context];
            
            AEManagedObject *objectCopyInBackContext = [self createOrUpdateFromJsonObject:jsonObject
                                                                   inManagedObjectContext:context];
            [AECoreDataHelper save:context];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                /**
                 We are removing previous entity because it was a temp client side representation
                 */
                [record.managedObjectContext rollback];
                
                if (success) success([mainThreadContext() objectWithID:[objectCopyInBackContext objectID]]);
            });
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *operation, id responseObject) =
    ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (failure) failure(error);
    };
    
    NSString *idField   = [self entityIdPropertyName];
    NSString *entityId  = [NSString stringWithFormat:@"%@", [record valueForKey:idField]];
    if ([record valueForKey:idField] && [entityId length] > 0 && ![entityId isEqual:kUnsavedClientSideEntityId]) {
        
        NSString *putPath = [path stringByAppendingFormat:@"/%@", entityId];
        [client putPath:putPath parameters:[record toJSONObject] success:successBlock failure:failureBlock];
    } else {
        
        [client postPath:path parameters:[record toJSONObject] success:successBlock failure:failureBlock];
    }
}

#pragma mark - private

+ (dispatch_queue_t)jsonQueue {
    static dispatch_queue_t _jsonQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _jsonQueue = dispatch_queue_create("com.ae.json_proccess", DISPATCH_QUEUE_SERIAL);
    });
    
    return _jsonQueue;
}

+ (void)formatJson:(NSArray *)items withEtag:(NSString *)etag success:(void (^)(NSArray *entities))success {
    
    NSManagedObjectContext *context = [[AECoreDataHelper createManagedObjectContext] retain];
    [AECoreDataHelper addMergeNotificationForMainContext:context];
    NSMutableArray *result = [NSMutableArray array];
    
    for (id jsonString in items) {
        AEManagedObject *entity = [self createOrUpdateFromJsonObject:jsonString inManagedObjectContext:context];
        [result addObject:entity];
    }
    
    if ([self requiresPersistence]) {
        [AECoreDataHelper save:context];
    }
    
    NSArray *objectIds = [result valueForKeyPath:@"objectID"];
    dispatch_async([self jsonQueue], ^{
        
        [[AEManagedObjectsCache sharedCache] setObjectIds:objectIds forEtag:etag];
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        success([self managedObjectsInMainThreadWithObjectIds:objectIds]);
        [context release];
    });
}

+ (BOOL)cachedManagedObjectsForOperation:(AFHTTPRequestOperation *)operation
                                 success:(void (^)(NSArray *entities))success {
    
    NSCachedURLResponse *cachedResponse;
    NSHTTPURLResponse *cachedHTTPResponse;
    NSString *prevEtag, *etag;
    
    cachedResponse     = [[NSURLCache sharedURLCache] cachedResponseForRequest:operation.request];
    cachedHTTPResponse = (NSHTTPURLResponse *)cachedResponse.response;
    
    if (!cachedHTTPResponse) return NO;
    
    prevEtag    = [[cachedHTTPResponse allHeaderFields] valueForKey:kEtagKeyIdentifier];
    etag        = [[operation.response allHeaderFields] valueForKey:kEtagKeyIdentifier];
    
    if ([etag length] <= 0) return NO;
    
    if (![etag isEqualToString:prevEtag]) {
        
        dispatch_async([self jsonQueue], ^{
            [[AEManagedObjectsCache sharedCache] removeObjectIdsForEtag:prevEtag];
        });
        return NO;
    }
    
    if (![[AEManagedObjectsCache sharedCache] containsObjectIdsForEtag:etag]) return NO;
    
    dispatch_async([self jsonQueue], ^{
        NSArray *objectIds = [[AEManagedObjectsCache sharedCache] objectIdsForEtag:etag];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            success([self managedObjectsInMainThreadWithObjectIds:objectIds]);
        });
    });
    
    return YES;
}

+ (NSArray *)managedObjectsInMainThreadWithObjectIds:(NSArray *)objectIds {
    
    NSMutableArray *resultInMainThread = [NSMutableArray array];
    for (NSManagedObjectID *objectID in objectIds) {
        
        [resultInMainThread addObject:[mainThreadContext() objectWithID:objectID]];
    }
    
    return resultInMainThread;
}

@end
