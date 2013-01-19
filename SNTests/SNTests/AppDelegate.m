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

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [[AEFBClient currentFacebook] handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([[AEFBClient currentFacebook] handleOpenURL:url]) {
        return YES;
    }
    
    return [[AEGPClient currentSignIn] handleURL:url
                               sourceApplication:sourceApplication
                                      annotation:annotation];
}

@end
