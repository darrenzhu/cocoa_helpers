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
    self.fbClient = [[AEFBClient alloc] initWithId:@"295109963930116"];
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
    NSLog(@"Logged!");
}

@end
