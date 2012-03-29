//
//  CommonEntity.h
//  cska
//
//  Created by Arthur Evstifeev on 12/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CommonEntity : NSManagedObject

@property(nonatomic, retain) NSNumber* id;

- (void)postprocessJSON:(id)json InContext:(NSManagedObjectContext*)context;
- (void)updateFromJSON:(id)json;
- (id)initFromJSON:(id)json withEntity:(NSEntityDescription*)entityDescription inManagedObjectContext:(NSManagedObjectContext*)context;
- (NSString*)toJSON;
- (void)formatCell:(UIView*)cell;

@end
