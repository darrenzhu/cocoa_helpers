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

@implementation AEManagedObject (AERemoteFetch)

/**
 With this entity id we will be checking for unsaved entities (decision POST/PUT). Check against string.
 */
static NSString * const kUnsavedClientSideEntityId = @"0";

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
        
        if (success) {
            NSArray *items = responseObject;
            if ([self jsonRoot]) {
                items = [responseObject valueForKey:[self jsonRoot]];
            }
            
            if ([items isKindOfClass:[NSArray class]] && [items count] > 0 &&
                ![[items objectAtIndex:0] isKindOfClass:[NSNull class]]) { //JSONKit returns sometimes array with NSNull
                
                dispatch_async([self jsonQueue], ^{
                    [self formatJson:items success:success];
                });
                
            } else if ([items isKindOfClass:[NSDictionary class]]) {
                dispatch_async([self jsonQueue], ^{
                    [self formatJson:@[ items ] success:success];
                });
            }
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
                jsonObject = [responseObject valueForKeyPath:[[self class] jsonRoot]];
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
    
    NSString *entityId = [NSString stringWithFormat:@"%@", [record valueForKey:@"id"]];
    if ([record valueForKey:@"id"] && [entityId length] > 0 && ![entityId isEqual:kUnsavedClientSideEntityId]) {
        
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
        _jsonQueue = dispatch_queue_create("com.or.json_proccess", 0);
    });
    
    return _jsonQueue;
}

+ (void)formatJson:(NSArray *)items success:(void (^)(NSArray *entities))success {
    
    NSManagedObjectContext *context = [[AECoreDataHelper createManagedObjectContext] retain];
    [AECoreDataHelper addMergeNotificationForMainContext:context];
    NSMutableArray *result = [NSMutableArray array];
    
    for (id jsonString in items) {
        AEManagedObject *entity = [self createOrUpdateFromJsonObject:jsonString
                                              inManagedObjectContext:context];
        [result addObject:entity];
    }
    
    if ([self requiresPersistence]) {
        [AECoreDataHelper save:context];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *resultInMainThread = [NSMutableArray array];
        for (AEManagedObject *entity in result) {
            AEManagedObject *entityInMainThread = (AEManagedObject *)[mainThreadContext() objectWithID:entity.objectID];
            [resultInMainThread addObject:entityInMainThread];
        }
        success(resultInMainThread);
        [context release];
    });
}

@end
