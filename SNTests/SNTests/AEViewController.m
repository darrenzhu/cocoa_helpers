//
//  AEViewController.m
//  SNTests
//
//  Created by ap4y on 1/17/13.
//
//

#import "AEViewController.h"
#import "AEFBClient.h"

@interface AEViewController () <AESNClientDelegate>
@property (weak, nonatomic) IBOutlet UITextView *profileTextView;
@property (weak, nonatomic) IBOutlet UITextView *friendsTextView;
@property (strong, nonatomic) AEFBClient *fbClient;
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
}

- (IBAction)linkedin:(id)sender {
}

- (IBAction)myspace:(id)sender {
}

- (IBAction)google:(id)sender {
}

- (IBAction)vk:(id)sender {
}

#pragma mark - AESNClientDelegate
- (void)client:(AESNClient *)client wantsPresentAuthPage:(NSString *)url {
    
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
