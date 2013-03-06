//
// AEManagedObjectsCache.m
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

#import "AEManagedObjectsCache.h"
#import "AECoreDataHelper.h"

@implementation AEManagedObjectsCacheRecord
@dynamic etag;
@dynamic objectIdsArchieve;
@end

@interface AEManagedObjectsCache ()
@property (strong, nonatomic) NSPersistentStoreCoordinator *coordinator;
@end

@implementation AEManagedObjectsCache

static NSString * const kSQLiteDBFileName = @"AEManagedObjectsCache.sqlite";

+ (AEManagedObjectsCache *)sharedCache {
    static AEManagedObjectsCache *_sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _sharedCache = [[AEManagedObjectsCache alloc] init];
    });
    
    return _sharedCache;
}

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    NSPersistentStoreCoordinator *coordinator;
    coordinator         = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self cachedRecordModel]];
    self.coordinator    = coordinator;    
    [coordinator release];
    
#if OCUNIT
    BOOL storeCreated   = [coordinator addPersistentStoreWithType:NSInMemoryStoreType
                                                    configuration:nil
                                                              URL:nil
                                                          options:nil
                                                            error:nil];
#else
    NSArray *pathes     = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *appPath   = [[pathes lastObject] stringByAppendingPathComponent:kSQLiteDBFileName];
    NSURL *storeURL     = [NSURL fileURLWithPath:appPath isDirectory:NO];    
    BOOL storeCreated   = [coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                    configuration:nil
                                                              URL:storeURL
                                                          options:nil
                                                            error:nil];    
#endif
    if (!storeCreated) {
        [self release];
        return nil;
    }
        
    return self;
}

- (void)dealloc {
    [_coordinator release];
    [super dealloc];
}

- (BOOL)containsObjectIdsForEtag:(NSString *)etag {
    
    AEManagedObjectsCacheRecord *cacheRecord = [self cacheRecordForEtag:etag inMangedContext:[self createContext]];
    
    if (!cacheRecord || !cacheRecord.objectIdsArchieve) return NO;
    
    return YES;
}

- (NSArray *)objectIdsForEtag:(NSString *)etag {
        

    AEManagedObjectsCacheRecord *cacheRecord = [self cacheRecordForEtag:etag inMangedContext:[self createContext]];
    if (!cacheRecord || !cacheRecord.objectIdsArchieve) return nil;
    
    NSArray *objectIdURLs       = [NSKeyedUnarchiver unarchiveObjectWithData:cacheRecord.objectIdsArchieve];
    NSMutableArray *objectIds   = [NSMutableArray array];
    
    NSPersistentStoreCoordinator *coordinator = [mainThreadContext() persistentStoreCoordinator];
    [objectIdURLs enumerateObjectsUsingBlock:^(NSURL *objURL, NSUInteger idx, BOOL *stop) {
        
        NSManagedObjectID *objectID = [coordinator managedObjectIDForURIRepresentation:objURL];
        [objectIds addObject:objectID];
    }];
    
    return objectIds;
}

- (BOOL)setObjectIds:(NSArray *)objectIds forEtag:(NSString *)etag {
    
    if (!etag || !objectIds) return NO;
    
    AEManagedObjectsCacheRecord *cacheRecord;
    NSManagedObjectContext *context;
    
    NSArray *objectIdURLS = [objectIds valueForKeyPath:@"URIRepresentation"];
    
    context     = [self createContext];
    cacheRecord = [NSEntityDescription insertNewObjectForEntityForName:@"AEManagedObjectsCacheRecord"
                                                inManagedObjectContext:context];
    cacheRecord.etag                = etag;
    cacheRecord.objectIdsArchieve   = [NSKeyedArchiver archivedDataWithRootObject:objectIdURLS];
    
    return [AECoreDataHelper save:context];
}

- (BOOL)removeObjectIdsForEtag:(NSString *)etag {

    NSManagedObjectContext *context = [self createContext];
    AEManagedObjectsCacheRecord *cacheRecord = [self cacheRecordForEtag:etag inMangedContext:context];

    [context deleteObject:cacheRecord];
    return [AECoreDataHelper save:context];
}

#pragma mark - private

- (AEManagedObjectsCacheRecord *)cacheRecordForEtag:(NSString *)etag inMangedContext:(NSManagedObjectContext*)context {
    
    NSPredicate *predicate  = [NSPredicate predicateWithFormat:@"etag == %@", etag];
    return [AEManagedObjectsCacheRecord requestFirstResult:[AEManagedObjectsCacheRecord where:predicate]
                                      managedObjectContext:context];
}

- (NSManagedObjectModel *)cachedRecordModel {
    
    NSAttributeDescription *etagAttribute = [[NSAttributeDescription alloc] init];
    [etagAttribute setName:@"etag"];
    [etagAttribute setAttributeType:NSStringAttributeType];
    [etagAttribute setOptional:NO];
    
    NSAttributeDescription *objIdsAttribute = [[NSAttributeDescription alloc] init];
    [objIdsAttribute setName:@"objectIdsArchieve"];
    [objIdsAttribute setAttributeType:NSTransformableAttributeType];
    [objIdsAttribute setOptional:NO];
    
    NSEntityDescription *cacheRecordEntity = [[NSEntityDescription alloc] init];    
    [cacheRecordEntity setName:@"AEManagedObjectsCacheRecord"];
    [cacheRecordEntity setManagedObjectClassName:@"AEManagedObjectsCacheRecord"];    
    [cacheRecordEntity setProperties:@[ etagAttribute, objIdsAttribute ]];
    
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
    [model setEntities:@[ cacheRecordEntity ]];
    
    [cacheRecordEntity release];
    [objIdsAttribute release];
    [etagAttribute release];
    
    return [model autorelease];
}

- (NSManagedObjectContext *)createContext {
    
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
    [context setPersistentStoreCoordinator:_coordinator];
    
    return [context autorelease];
}

@end
