//
//  CSKAClient.h
//  cska
//
//  Created by Arthur Evstifeev on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AFHTTPClient.h"
#import "CommonEntity.h"
#import "CoreDataHelper.h"

@interface CommonClient : AFHTTPClient {

}

- (NSEntityDescription *)enityDescriptionInContext:(NSManagedObjectContext *)context;

- (NSMutableDictionary*)formBody:(int)start 
                           count:(int)limit 
                        dateFrom:(NSDate*)date;

- (CommonEntity*)createOrUpdate:(id)jsonString inManagedObjectContext:(NSManagedObjectContext*)context;
- (void)formatJson:(NSArray*)items 
             byOne:(BOOL)byOne
           success:(void (^)(NSArray* entities))success;

@end
