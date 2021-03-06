//
//  AEAppDelegate.m
//  SNTests
//
//  Created by ap4y on 1/17/13.
//
//

#import "AppDelegate.h"

#import "AEViewController.h"
#import "AEFBClient.h"
#import "AEGPClient.h"
#import "AELIClient.h"
#import "AETWClient.h"
#import "AEXingClient.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[AEViewController alloc] initWithNibName:@"AEViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if ([[url scheme] isEqualToString:@"ap4y.sntests"]) {
        return [[AEGPClient currentClient] processWebViewResult:url];
    } else if ([[url scheme] isEqualToString:@"linengine"]) {
        return [[AELIClient currentClient] processWebViewResult:url];
    } else if ([[url scheme] isEqualToString:@"twengine"]) {
        return [[AETWClient currentClient] processWebViewResult:url];
    } else if ([[url scheme] isEqualToString:@"xingengine"]) {
        return [[AEXingClient currentClient] processWebViewResult:url];
    } else {
        return [[AEFBClient currentClient] processWebViewResult:url];
    }
    
    return NO;
}

@end
