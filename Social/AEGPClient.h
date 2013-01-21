//
//  AEGPClient.h
//  SNTests
//
//  Created by ap4y on 1/18/13.
//
//

#import "AESNClient.h"

@interface AEGPClient : AESNClient

+ (AEGPClient *)currentGPClient;
- (id)initWithClientID:(NSString *)clientID
              language:(NSString *)language
                 scope:(NSArray *)scope
            bundleName:(NSString *)bundleName;

@end
