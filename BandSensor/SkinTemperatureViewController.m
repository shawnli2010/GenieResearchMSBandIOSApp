//
//  SkinTemperatureViewController.m
//  
//
//  Created by Xueyang Li on 5/10/15.
//
//

#import "SkinTemperatureViewController.h"

@interface SkinTemperatureViewController ()

@end

@implementation SkinTemperatureViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [MSBClientManager sharedManager].delegate = self;
    NSArray	*clients = [[MSBClientManager sharedManager] attachedClients];
    _client = [clients firstObject];
    if ( _client == nil )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed"
                                                        message:@"No Bands Attached"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    [[MSBClientManager sharedManager] connectClient:_client];
    
    //keyboard disappear when tapping outside of text field
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - dismissKeyboard
-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - Client Manager Delegates

- (void)clientManager:(MSBClientManager *)clientManager clientDidConnect:(MSBClient *)client
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                    message:@"Band connected!"
                                                   delegate:nil
                                          cancelButtonTitle:@"Start Experiment"
                                          otherButtonTitles:nil];
    [alert show];
    [self performSegueWithIdentifier:@"startExperiment" sender:self];
}

- (void)clientManager:(MSBClientManager *)clientManager clientDidDisconnect:(MSBClient *)client
{
    NSLog(@"in ConnectedViewController disconnected");
}

- (void)clientManager:(MSBClientManager *)clientManager client:(MSBClient *)client didFailToConnectWithError:(NSError *)error
{
    NSLog(@"in ConnectedViewController failed to connect to band");
}

#pragma mark - AFNetworking Button Pressed
- (IBAction)AFTestButtonPressed:(UIButton *)sender {
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://genie.ucsd.edu"]];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"genie.calendar.ucsd@gmail.com" password:@"5056789"];
    
    [manager GET:@"https://genie.ucsd.edu/api/v1/sensors/weather" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}




@end
