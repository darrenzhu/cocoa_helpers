//
//  AEHTTPClient.m
//  AEHelpers
//
//  Created by ap4y on 1/16/13.
//
//

#import "AEHTTPClient.h"
#import "AFJSONRequestOperation.h"

@implementation AEHTTPClient
NSString * const baseUrlString = @"http://api.test.com";

+ (AEHTTPClient *)sharedClient {
    static AEHTTPClient *_sharedClient;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseUrl = [NSURL URLWithString:baseUrlString];
        _sharedClient = [[AEHTTPClient alloc] initWithBaseURL:baseUrl];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self setStringEncoding:NSUTF8StringEncoding];
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

@end
