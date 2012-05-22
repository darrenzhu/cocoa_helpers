My everyday cocoa stuff.

## REST api clients ##

Wrapper for the AFHTTPClient. Returns decoded from json coredata objects. Contains methods fro easier entities requests:

	- (NSArray*)all:(NSManagedObjectContext*)context;
	- (NSArray*)all:(NSManagedObjectContext*)context orderBy:(NSString*)firstSortingParam, ... NS_REQUIRES_NIL_TERMINATION;
	- (NSArray*)all:(NSManagedObjectContext*)context orderByDescriptors:(NSSortDescriptor*)firstDescriptor, ... NS_REQUIRES_NIL_TERMINATION;

	- (id)find:(NSManagedObjectContext*)context itemId:(id)itemId;

	- (NSArray*)where:(NSManagedObjectContext*)context wherePredicate:(NSPredicate*)wherePredicate;
	- (NSArray*)where:(NSManagedObjectContext*)context wherePredicate:(NSPredicate*)wherePredicate orderBy:(NSString*)firstSortingParam, ... NS_REQUIRES_NIL_TERMINATION;
	- (NSArray*)where:(NSManagedObjectContext*)context wherePredicate:(NSPredicate*)wherePredicate orderByDescriptors:(NSSortDescriptor*)firstDescriptor, ... NS_REQUIRES_NIL_TERMINATION;

Concrete client class should implement:
	
	- (NSDateFormatter *)dateFormatter;
	- (NSEntityDescription *)enityDescriptionInContext:(NSManagedObjectContext *)context;

NSDateFormatter for correct decodin/encoding of the HTTPRequests date params and NSEntityDescription to point the entitity which it posses

Client entities base class should implement NSDateFormatter for correct decoding of the dates

	- (NSDateFormatter*)dateFormatter;

## Social networks ##

Clients for the social networks (facebook, twitter, vkontakte) with common interface, authentication credentials caching

Exposes:

	- (BOOL)isSessionValid;
	- (void)login;
	- (void)shareLink:(NSString*)link withTitle:(NSString*)title andMessage:(NSString*)message;

Should be implemented in concrete class:

	@interface SNClient (Private)
	- (void)doLoginWorkflow;
	- (void)regainToken:(NSDictionary*)savedKeysAndValues;
	- (void)saveToken:(NSDictionary*)tokensToSave;
	- (BOOL)processWebViewResult:(NSURL*)processUrl;
	@end

Optianal delegate inteface:

	@protocol SNClientDelegate <NSObject>
	- (void)client:(SNClient*)client showAuthPage:(NSString*)url;
	- (void)clientDidLogin:(SNClient*)client ;
	@end

## Unit testing (OCUnit+OCMock) ##

Class methods for stubing REST api requests (via AFHTTPNetworking) with results from txt file (saved handshakes):

	+ (void)stubGetPath:(NSString*)path 
	      forClientMock:(id)clientMock
	          andParams:(NSDictionary*)params 
	  withHandshakeFile:(NSString*)handshakeFile;

Async test looping with blocks:

	- (void)runAsyncTestUntil:(NSTimeInterval)interval 
                     test:(void (^)())test;
	- (void)runAsyncTest:(void (^)(AsyncTestConditon* endCondition))test 
	        withInterval:(NSTimeInterval)interval;
	- (void)runAsyncTest:(void (^)(AsyncTestConditon* endCondition))test;

implement your async test in block and return endCondition.trigger after getting callback result, looping continues till interval expiration.

## Other ##

Also contains useful categories and wrapper for the common CoreData activities.

## License ##

(The MIT License)