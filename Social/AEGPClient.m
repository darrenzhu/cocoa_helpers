//
//  AEGPClient.m
//  SNTests
//
//  Created by ap4y on 1/18/13.
//
//

#import "AEGPClient.h"
#import "GTLQueryPlus.h"

@interface AEGPClient () <GPPSignInDelegate>
@property (retain, nonatomic) GPPSignIn *gpSignIn;
@property (retain, nonatomic) NSString *accessToken;
@end

@implementation AEGPClient

static GPPSignIn *currentSignIn;
+ (GPPSignIn *)currentSignIn {
    return currentSignIn;
}

- (id)initWithClientID:(NSString *)clientID language:(NSString *)language scope:(NSArray *)scope {
    self = [super init];
    if (self) {
        self.gpSignIn = [[GPPSignIn alloc] initWithClientID:clientID
                                                   language:language
                                                      scope:scope
                                               keychainName:nil];
        _gpSignIn.delegate = self;
        currentSignIn = _gpSignIn;
    }
    return self;
}

- (void)dealloc {
    [currentSignIn release];
    [super dealloc];
}

- (void)profileInformationWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    GTLQueryPlus *profileQuery = [GTLQueryPlus ];
    profileQuery.fields = @"id,emails,image,name,displayName";
    profileQuery.completionBlock = ^(GTLServiceTicket *ticket, id object, NSError *error) {
        if (error == nil) {
            // Get the user profile
            GTLPlusPerson *userProfile = object;
            // Get what we want
            NSArray * userEmails = userProfile.emails;
            NSString * email = ((GTLPlusPersonEmailsItem *)[userEmails objectAtIndex:0]).value;
            NSString * name = userProfile.displayName;
            NSString * profileId = userProfile.identifier;
        } else {
            // Log the error
            NSLog(@"Error : %@", [error localizedDescription]);
        }
    };}

#pragma mark - overrides

- (void)doLoginWorkflow {
    [_gpSignIn authenticate:YES clearKeychain:NO];
}

- (void)regainToken:(NSDictionary *)savedKeysAndValues {}

#pragma mark - GPPSignInDelegate
- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error {
    if (error) {
        return;
    }
    
    if (self.delegate) {
        [self.delegate clientDidLogin:self];
    }
}

@end
