//
//  CommonEntity.h
//  cska
//
//  Created by Arthur Evstifeev on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CommonClient;
@interface CommonEntity : NSManagedObject

- (id)initFromJSON:(id)json withEntity:(NSEntityDescription*)entityDescription inManagedObjectContext:(NSManagedObjectContext*)context;

- (NSDateFormatter *)dateFormatter;
- (void)postprocessJSON:(id)json withClient:(CommonClient*)client;

- (void)updateFromJSON:(id)json;
- (NSString*)toJSON;

@end
