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

@interface AEViewController () <AESNClientDelegate>
@property (weak, nonatomic) IBOutlet UITextView *profileTextView;
@property (weak, nonatomic) IBOutlet UITextView *friendsTextView;
@property (strong, nonatomic) AEFBClient *fbClient;
@property (strong, nonatomic) AETWClient *twClient;
@property (strong, nonatomic) AELIClient *liClient;
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

- (IBAction)myspace:(id)sender {
}

- (IBAction)google:(id)sender {
}

- (IBAction)vk:(id)sender {
}

#pragma mark - AESNClientDelegate
- (void)client:(AESNClient *)client wantsPresentAuthPage:(NSURL *)url {
    UIWebView *_webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    _webView.delegate = client;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:request];
    
    [self.view addSubview:_webView];
}

- (void)clientDidLogin:(AESNClient *)client {
    NSLog(@"Logged with client %@!", client);
    
    [client profileInformationWithSuccess:^(NSDictionary *profile) {
        _profileTextView.text = [NSString stringWithFormat:@"%@", profile];
    } failure:^(NSError *error) {
        NSLog(@"Unable to get profile with client %@, %@", client, error);
    }];
    
    [client friendsInformationWithLimit:10 offset:0 success:^(NSArray *friends) {
        _friendsTextView.text = [friends componentsJoinedByString:@"\n"];
    } failure:^(NSError *error) {
        NSLog(@"Unable to get friends with client %@, %@", client, error);
    }];    
}

@end
