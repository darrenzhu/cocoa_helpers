//
// AEManagedObject+AERemoteFetch.h
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
#import "AFHTTPClient.h"

@interface AEManagedObject (AERemoteFetch)

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

/**
 Performs PUT or POST request in order to submit changes to the server. This method will return new instance with data from response in `success` block.
 
 @param record A record to submit.
 @param client `AFHTTPClient` subclass to perform request.
 @param path Requested path.
 @param success A block, will be invoked with success operation.
 @param failure A block, will be invoked with failed operation.
 
 @discussion We are identifying new object by id. You can't get id on clint side with object creation. If object has id we will perform PUT request with RESTful path (/path/id). 
    You don't need to save managed object before post, in most cases you can't provide all necessary data on client side and pass validations. This method will rollback all changes in record managed object context, and will return new entity in `success` block. This new instance will be created or updated entity.
    If `failure` encoutered rollback will not be performed, so you can try to resubmit.
 */
+ (void)submitRecord:(AEManagedObject *)record
          withClient:(AFHTTPClient *)client
                path:(NSString *)path
             success:(void (^)(id entity))success
             failure:(void (^)(NSError *error))failure;

@end
