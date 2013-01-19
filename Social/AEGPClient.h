//
//  AEGPClient.h
//  SNTests
//
//  Created by ap4y on 1/18/13.
//
//

#import "AESNClient.h"
#import "GPPSignIn.h"

@interface AEGPClient : AESNClient

+ (GPPSignIn *)currentSignIn;
- (id)initWithClientID:(NSString *)clientID language:(NSString *)language scope:(NSArray *)scope;

@end
