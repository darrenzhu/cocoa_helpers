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

- (NSEntityDescription *)enityDescriptionInContext:(NSManagedObjectContext *)context {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSMutableDictionary*)formBody:(int)start 
                           count:(int)limit 
                        dateFrom:(NSDate*)date {
    
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    
    [params setValue:[NSNumber numberWithInt:start] forKey:@"from"];
    
    if (limit > 0)
        [params setValue:[NSNumber numberWithInt:limit] forKey:@"count"];
    
    if (date) {
        NSDateFormatter* f = [[NSDateFormatter alloc] init];
        [f setDateFormat:@"yyyy-MM-dd+HH:mm:ss"];    
        
        [params setValue:[f stringFromDate:date] forKey:@"dateFrom"];    
    }
    
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
    
    if (!byOne)
        success(result);    
    
    [CoreDataHelper save:context];
}

@end
