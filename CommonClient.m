//
//  CSKAClient.m
//  cska
//
//  Created by Arthur Evstifeev on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CommonClient.h"
#import "AFJSONRequestOperation.h"

@implementation CommonClient

+ (CommonClient *)sharedClient {
    static CommonClient* _sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:kTTBaseURLString]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }        
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];   
    [self setStringEncoding:NSWindowsCP1251StringEncoding];
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

- (NSEntityDescription *)enityDescriptionInContext:(NSManagedObjectContext *)context {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSMutableDictionary*)formBody:(int)start 
                           count:(int)limit {
    
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    
    [params setValue:[NSNumber numberWithInt:start] forKey:@"from"];
    
    if (limit > 0)
        [params setValue:[NSNumber numberWithInt:limit] forKey:@"count"];
        
    return params;
}

- (CommonEntity*)createOrUpdate:(id)jsonString inManagedObjectContext:(NSManagedObjectContext*)context {
    
    NSNumber* curId = [jsonString valueForKeyPath:@"id"];
    
    NSEntityDescription* entityDesc = [self enityDescriptionInContext:context];
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    [fetchRequest setEntity:entityDesc];    
    
    NSPredicate* idPredicate = [NSPredicate predicateWithFormat:@"id = %@", curId];
    [fetchRequest setPredicate:idPredicate];
    
    CommonEntity* entity = [CoreDataHelper requestFirstResult:fetchRequest managedObjectContext:context];
    if (entity) {
        [entity updateFromJSON:jsonString];  
    }
    else {
        Class class = NSClassFromString([self enityDescriptionInContext:context].managedObjectClassName);
        
        if (class)
            entity = [[[class alloc] initFromJSON: jsonString withEntity:[self enityDescriptionInContext:context] inManagedObjectContext:context] autorelease]; 
    }
    
    [entity postprocessJSON:jsonString InContext:context]; 
    
    return entity;
}

- (void)formatJson:(NSArray*)items 
             byOne:(BOOL)byOne
           success:(void (^)(NSArray* entities))success {    
    
    NSManagedObjectContext* context = [[[NSManagedObjectContext alloc] init] autorelease];
    [context setPersistentStoreCoordinator:[CoreDataHelper persistentStoreCoordinator]];
    
    NSMutableArray* result = [NSMutableArray array];        
    
    for (id jsonString in items) {                                
        
        CommonEntity* entity = [self createOrUpdate:jsonString inManagedObjectContext:context];                            
        [result addObject:entity];
        
        if (byOne) {
            success(result);
            [result removeAllObjects];
        }                       
    }     
    
    [CoreDataHelper save:context];
    
    if (!byOne)
        success(result);    
}

- (void)values:(NSString*)valueCategory
    withParams:(NSDictionary*)params
       success:(void (^)(NSArray* entities))success        
       failure:(void (^)(NSError *error))failure {
    
    [self getPath:[NSString stringWithFormat:@"?c=mobile&m=%@", valueCategory] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSArray* items = [responseObject valueForKeyPath:@"data"];
        
        if ([items isKindOfClass:NSArray.class] && items.count > 0) {
            if ([NSThread isMainThread]) {
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    [self formatJson:items byOne:NO success:success];
                });
            }
            else
                [self formatJson:items byOne:NO success:success];
        }
        else {
            success([NSArray array]);
        }
                        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void)photosForCardId:(NSNumber*)cardId            
                success:(void (^)(NSArray* entities))success        
                failure:(void (^)(NSError *error))failure {
    
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;        
    
    [self getPath:[NSString stringWithFormat:@"/mobile/card/%i/photos", cardId.intValue] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        NSArray* items = [responseObject valueForKeyPath:@"data"];
        
        if ([items isKindOfClass:NSArray.class] && items.count > 0)
            success(items);

                
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        failure(error);
    }];
}

- (void)commentsForCardId:(NSNumber*)cardId            
                  success:(void (^)(NSArray* entities))success        
                  failure:(void (^)(NSError *error))failure {
    
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;        
    
    [self getPath:[NSString stringWithFormat:@"/mobile/card/%i/comments", cardId.intValue] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSArray* items = [responseObject valueForKeyPath:@"data"];
        
        success(items);
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        failure(error);
    }];
}


- (void)getCitiesWithMask:(NSString*)mask success:(void (^)(NSArray* cities))success {
    [self getPath:[NSString stringWithFormat:@"?c=mobile&m=cities_json&name=%@", mask] parameters:nil 
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
              NSArray* items = [responseObject valueForKeyPath:@"data"];
              
              if ([items isKindOfClass:NSArray.class])
                  success(items);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (void)shareOnFbForProfile:(NSString*)profileID response:(void (^)(NSString* response))response {
    
    [self getPath:[NSString stringWithFormat:@"mobile/fb_share/&id=%@", profileID] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        response(operation.responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        response(operation.responseString);
    }];
}

- (void)addFavoriteForProfile:(NSString*)profileID response:(void (^)(NSString* response))response {
    
    [self getPath:[NSString stringWithFormat:@"?c=mobile&m=add_fav&id=%@", profileID] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        response(operation.responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        response(operation.responseString);
    }];
}

- (void)addTip:(NSString*)message forProfile:(NSString*)profileID response:(void (^)(NSString* response))response {
    
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    [params setObject:profileID forKey:@"obj_id"];
    [params setObject:message forKey:@"message"];
    
    [self postPath:@"?c=mobile&m=add_comment" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        response(operation.responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        response(operation.responseString);
    }];
}

- (void)setRate:(int)rate ForProfile:(NSString*)profileID response:(void (^)(NSString* response))response {
    
    [self getPath:[NSString stringWithFormat:@"?c=mobile&m=rate_obj&obj_id=%@&rate=%i", profileID, rate] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        response(operation.responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        response(operation.responseString);
    }];    
}

- (void)setBookmarkForProfile:(NSString*)profileID response:(void (^)(NSString* response))response {
    
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    [params setObject:profileID forKey:@"obj_id"];
    
    [self postPath:@"?c=mobile&m=bookmark" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        response(operation.responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        response(operation.responseString);
    }];    
}

- (void)sendFBMessage:(NSString*)message toUser:(NSString*)userId withToken:(NSString*)token response:(void (^)(NSString* response))response {
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    [params setObject:token forKey:@"access_token"];
    [params setObject:message forKey:@"message"];
    
    [self postPath:[NSString stringWithFormat:@"https://graph.facebook.com/%@/feed", userId] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        response(operation.responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        response(operation.responseString);
    }];    
}

- (void)doLoginWithToken:(NSString*)token reponse:(void (^)(NSString* response))response {
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    [params setObject:token forKey:@"access"];
    
    [self postPath:@"?mobile/check_auth" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        response(operation.responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        response(operation.responseString);
    }];    
}

- (void)uploadImage:(UIImage*)image forProfile:(NSString*)profileID success:(void (^)())success {
    _success = success;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSString *urlString = [NSString stringWithFormat:@"%@?c=mobile&m=load_image&id=%@", kTTBaseURLString, profileID];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    
    NSMutableData *body = [NSMutableData data];    
    
    NSString *boundary = [NSString stringWithString:@"---------------------------14737809831466499882746641449"];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0f);
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithString:@"Content-Disposition: attachment; name=\"image\"; filename=\"image.jpg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithString:@"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:imageData]];
    [body appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:body];
    
    [NSURLConnection connectionWithRequest:request delegate:self]; 
}

#pragma mark - NSURLConnection

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    _success();        
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {    
    NSLog(@"%@", error);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end
