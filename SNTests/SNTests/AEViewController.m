//
//  AEViewController.m
//  SNTests
//
//  Created by ap4y on 1/17/13.
//
//

#import "AEViewController.h"
#import "AEFBClient.h"
#import "AETWClient.h"
#import "AELIClient.h"
#import "AEGPClient.h"

@interface AEViewController () <AESNClientDelegate>
@property (weak, nonatomic) IBOutlet UITextView *profileTextView;
@property (weak, nonatomic) IBOutlet UITextView *friendsTextView;
@property (strong, nonatomic) AEFBClient *fbClient;
@property (strong, nonatomic) AETWClient *twClient;
@property (strong, nonatomic) AELIClient *liClient;
@property (strong, nonatomic) AEGPClient *gpClient;
@end

@implementation AEViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)facebook:(id)sender {
    self.fbClient = [[AEFBClient alloc] initWithId:@"295109963930116"
                                       permissions:@[ @"share_item", @"user_work_history"]];
    _fbClient.delegate = self;
    [_fbClient login];
}

- (IBAction)twitter:(id)sender {
    self.twClient = [[AETWClient alloc] initWithKey:@"fVprggQkOYWNGZNmnu6bjA"
                                             secret:@"r4unocIWkFtHzFM9tKFVmY2nKoC4ssabTD1bfpNk"
                                        andRedirect:@"twengine://auth_token"];
    _twClient.delegate = self;
    [_twClient login];
}

- (IBAction)linkedin:(id)sender {
    self.liClient = [[AELIClient alloc] initWithKey:@"oghhm15b8dt8"
                                             secret:@"NTORlXatMJnzn2qj"
                                        permissions:@[ @"r_fullprofile", @"r_network" ]
                                        andRedirect:@"linengine://authtoken.com"];
    _liClient.delegate = self;
    [_liClient login];
}

- (IBAction)google:(id)sender {
    self.gpClient = [[AEGPClient alloc] initWithClientID:@"869080294705.apps.googleusercontent.com"
                                                language:@"en"
                                                   scope:@[ @"https://www.googleapis.com/auth/plus.me" ]
                                              bundleName:@"ap4y.SNTests"];

    _gpClient.delegate = self;
    [_gpClient login];
}

#pragma mark - AESNClientDelegate
- (void)client:(AESNClient *)client wantsPresentAuthPage:(NSURL *)url {
//  You can present web view or use SSO via openURL
//    UIWebView *_webView = [[UIWebView alloc] initWithFrame:self.view.frame];
//    _webView.delegate = client;
//    
//    NSURLRequest *request = [NSURLRequest requestWithURL:url];
//    [_webView loadRequest:request];
//    
//    [self.view addSubview:_webView];
    
    [[UIApplication sharedApplication] openURL:url];
}

- (void)clientDidLogin:(AESNClient *)client {
    NSLog(@"Logged with client %@!", client);
    
    [client profileInformationWithSuccess:^(NSDictionary *profile) {
        _profileTextView.text = [NSString stringWithFormat:@"%@", profile];
    } failure:^(NSError *error) {
        NSLog(@"Unable to get profile with client %@, %@", client, error);
    }];
    
    if ([client isKindOfClass:[AEGPClient class]]) {
        _friendsTextView.text = @"";
    }
    
    [client friendsInformationWithLimit:10 offset:0 success:^(NSArray *friends) {
        _friendsTextView.text = [friends componentsJoinedByString:@"\n"];
    } failure:^(NSError *error) {
        NSLog(@"Unable to get friends with client %@, %@", client, error);
    }];    
}

@end
