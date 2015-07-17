//
//  ChooseExperimentViewController.m
//  BandSensor
//
//  Created by Xueyang Li on 7/15/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "ChooseExperimentViewController.h"
#import "CollectDataViewController.h"
#import "HVACControllViewController.h"

@interface ChooseExperimentViewController ()
{
    NSMutableArray *roomArray;
}

@end

@implementation ChooseExperimentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self configureLayout];
    [self setUpMicrosoftBandManager];
    [self fetchRooms];
}

-(void)configureLayout
{
    // Calculate the button width based on screen width
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat realScreenHeight = screenHeight - navBarHeight;
    
    self.jcdTopSpace.constant = navBarHeight;
    
    self.justCollectDataButtonHeight.constant = realScreenHeight/2;
    self.hvacButtonHeight.constant = realScreenHeight/2;
    
    // Show the progress HUD when the app is trying to connect to the band
    self.hud = [[MBProgressHUD alloc] init];
    [self.view addSubview:self.hud];
    self.hud.labelText = @"Connecting to the band...";
    self.hud.yOffset = -10;
    [self.hud show:YES];
}

-(void)setUpMicrosoftBandManager{
    
    [MSBClientManager sharedManager].delegate = self;
    NSArray	*clients = [[MSBClientManager sharedManager] attachedClients];
    self.client = [clients firstObject];
    if ( self.client == nil )
    {
        [self.hud hide:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed"
                                                        message:@"No Bands Attached to the Phone"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    [[MSBClientManager sharedManager] connectClient:self.client];
}

// Fetch the rooms for this user because the http request requires room as a parameter
-(void)fetchRooms{

    roomArray = [[NSMutableArray alloc] init];
    [self.AFManager GET:@"https://genie.ucsd.edu/api/v1/users/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        int i = 0;
        for(NSString *roomNumber in responseObject[@"rooms"])
        {
            [roomArray addObject:responseObject[@"rooms"][i][@"room"]];
            i++;
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error when fetch room: %@", error);
        //        [self output:[NSString stringWithFormat:@"Error: %@", error]];
        [self.hud hide:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"An error happened when fetching the rooms"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }];
}

#pragma mark - Microsoft Band Client Manager Delegates

- (void)clientManager:(MSBClientManager *)clientManager clientDidConnect:(MSBClient *)client
{
    //POTENTIAL ERROR: if the speed of internet is very slow that the rooms might be fetched from the server later than the band is connected
    // then it will always show the error alert no matter whether the user has room on the server or not
    if([roomArray count] == 0)
    {
        [self.hud hide:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"You have no room in Genie, please go to genie.ucsd.edu and add a room"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        //        NSLog(@"%@",roomArray[0])
        if (self.client && self.client.isDeviceConnected)
        {
            [self.hud hide:YES];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                            message:@"Band connected!"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            [self.hud hide:YES];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Band is not connected!"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (void)clientManager:(MSBClientManager *)clientManager clientDidDisconnect:(MSBClient *)client
{
    NSLog(@"in ChooseExperimentViewController clientDidDisconnect");
//    [self output:@"in ConnectedViewController disconnected"];

}

- (void)clientManager:(MSBClientManager *)clientManager client:(MSBClient *)client didFailToConnectWithError:(NSError *)error
{
    NSLog(@"in ChooseExperimentViewController didFailToConnectWithError: %@", error);
    //    [self output:@"in ConnectedViewController failed to connect to band"];
}

#pragma mark - Prepare for segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"ChooseToJustCollectData"]){
        CollectDataViewController *controller = (CollectDataViewController *)segue.destinationViewController;
        
        controller.AFManager = self.AFManager;
        controller.roomArray = roomArray;
        controller.client = self.client;
    }
    
    if([segue.identifier isEqualToString:@"ChooseToHVACControl"]){
        HVACControllViewController *controller = (HVACControllViewController *)segue.destinationViewController;
        
        controller.AFManager = self.AFManager;
        controller.roomArray = roomArray;
        controller.client = self.client;
    }
    
}


#pragma mark - Button Pressed Methods
- (IBAction)jcdButtonPressed:(UIButton *)sender {
    [self performSegueWithIdentifier:@"ChooseToJustCollectData" sender:self];
}

- (IBAction)hvacButtonPressed:(UIButton *)sender {
    [self performSegueWithIdentifier:@"ChooseToHVACControl" sender:self];
}

- (IBAction)logoutButtonPressed:(UIBarButtonItem *)sender {
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"Credential" accessGroup:nil];
    [keychain resetKeychainItem];

    isFromLogout = TRUE;
    
    [[MSBClientManager sharedManager] cancelClientConnection:self.client];
    
    NSLog(@"roomArray: %@",roomArray);

    [self.navigationController dismissViewControllerAnimated:TRUE completion:nil];
    
}

@end
