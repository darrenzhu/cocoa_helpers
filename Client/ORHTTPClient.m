//
//  CSKAClient.m
//  cska
//
//  Created by Arthur Evstifeev on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ORHTTPClient.h"

@implementation ORHTTPClient

+ (void)processRequest:(NSURLRequest*)request 
               success:(void (^)(AFHTTPRequestOperation* operation))success
                failed:(void (^)(NSError* error))failed {
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.completionBlock = ^{
        if ([operation hasAcceptableStatusCode]) {            
            success(operation);            
        } else {
            if (failed) {
                failed(operation.error);
            }
            NSLog(@"Error: %@, %@", operation.error, operation.responseString);
        }
    };
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation]; 
    [queue release];
}

- (id)getPathSync:(NSString*)path {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    });
    NSString* dataUrl = [NSString stringWithFormat:@"%@%@", self.baseURL, path];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:dataUrl]];
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request 
                                                 returningResponse:nil 
                                                             error:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    });
    return [NSString stringWithUTF8String:responseData.bytes];
}

@end
