//
//  CSKAClient.m
//  cska
//
//  Created by Arthur Evstifeev on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ORHTTPClient.h"

#import "AFNetworkActivityIndicatorManager.h"

@implementation ORHTTPClient

- (id)getPathSync:(NSString*)path {
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];    
    NSString* dataUrl = [NSString stringWithFormat:@"%@%@", self.baseURL, path];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:dataUrl]];
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request 
                                                 returningResponse:nil 
                                                             error:nil];
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:NO];
    return [NSString stringWithUTF8String:responseData.bytes];
}

- (void)getPath:(NSString *)path 
     parameters:(NSDictionary *)parameters 
        success:(void (^)(AFHTTPRequestOperation *, id))success 
        failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [super getPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:NO];
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:NO];
        failure(operation, error);
    }];
}

@end
