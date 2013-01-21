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
        return [[AEGPClient currentGPClient] processWebViewResult:url];
    } else {
        return [[AEFBClient currentFacebook] handleOpenURL:url];
    }
    
    return NO;
}

@end
