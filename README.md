## NSManagedObject with JSON support and refined fetched requests

 Common base class for `JSON` based managed objects. Solves general tasks:

 - `JSON` serialization and desirialization. Fast serialization process via `JSONKit` with type-checking and mappings.
 - Fetching remote items. All actions performed in background (using `GCD`), main thread active only when synthesizing saved entites from `objectID`.
 - Simplified fetch requests. ActiveRecord-like behaviour.

 ```objective-c
NSFetchRequest *request = [[TestEntity find:@(1)] orderBy:@"id", nil];
NSFetchRequest *request = [TestEntity find:@(1)];
NSFetchRequest *request = [TestEntity where:predicate];
```

 - Handles json root objects, dates and allow to create temporary requested entities.

## CoreData helpers

Solves common `CoreData` task:

- Creating contexts, model, coordinator.
- Dedicated context singleton for the main thread.
- Simple fetched requests.
- Merging notifications.
- Automatic switching to memory store for unit tests

## Social networks

Clients for social networks with common interface, authentication, credentials caching.

- Generic `OAuth1.x` implementation.
- `Keychain` token storage.
- `SSO` supported where possible.
- Implemented wrappers for fetching user `profile`, `connections` and creating `shares`.
- Implemented clients for: `Facebook`, `Twitter`, `LinkedIn`, `Google+`, `Xing`, `Vkontakte`.

## Unit testing

Async test looping with blocks:

 ```objective-c
- (void)runAsyncTestUntil:(NSTimeInterval)interval
                   test:(void (^)())test;
- (void)runAsyncTest:(void (^)(AsyncTestConditon* endCondition))test
        withInterval:(NSTimeInterval)interval;
- (void)runAsyncTest:(void (^)(AsyncTestConditon* endCondition))test;
```

implement your async test in block and return `endCondition.trigger` after getting callback result, looping continues till interval expiration.

## Installation

[cocoapods](http://cocoapods.org) `podspec` included. Unit test included. Social network client examples included.

## License ##

(The MIT License)
