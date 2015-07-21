//
//  LoginViewController.m
//  BandSensor
//
//  Created by Xueyang Li on 5/10/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "LoginViewController.h"
#import "ChooseExperimentViewController.h"

@interface LoginViewController ()
{
    KeychainItemWrapper *keychain;
    
    AFHTTPRequestOperationManager *AFManager;
}
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view
    [self.SKTTxtOutput setHidden:true];
    
    self.RPKmanager = [RPKManager managerWithDelegate:self];
    
    NSString *startString = [NSString stringWithFormat:@"App Starts at %@", [self getCurrentTimeString]];
    [self output:startString];
    NSLog(@"%@",startString);
    
    /************************************************************************/
    keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"Credential" accessGroup:nil];
    [keychain setObject:@"MY_APP_CREDENTIALS" forKey:(__bridge id)kSecAttrService];


    // Check whether there are existing keychain, if it exists, then set the two textfields
    // And in viewDidAppear the program will auto login
    if ([[keychain objectForKey:(__bridge id)kSecAttrAccount] length])
    {
        [self.usernameTextField  setText:[keychain objectForKey:(__bridge id)(kSecAttrAccount)]];
        [self.passwordTextField setText:[keychain objectForKey:(__bridge id)(kSecValueData)]];
    }
    /************************************************************************/
    
    self.hud = [[MBProgressHUD alloc] init];
    [self.view addSubview:self.hud];
    
    [self.passwordTextField setSecureTextEntry:YES];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    // prevent the touch event to the table view being eaten by the tap
    [tap setCancelsTouchesInView:NO];
}

- (void)viewDidAppear:(BOOL)animated
{

    if([self.usernameTextField.text length])
    {
        if(!isFromLogout)
        {
            [self performLogin];
        }
        else
        {
            [self.usernameTextField setText:@""];
            [self.passwordTextField setText:@""];
        }
    }
    
    [self.RPKmanager start];
    NSLog(@"IN Login VIEWDIDAPPEAR!!!!");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Helper method to login the user
-(void)performLogin {
    if([self.usernameTextField.text isEqualToString:@""] || [self.passwordTextField.text isEqualToString:@""] )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"No input field should be blank"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        
        [self.hud show:YES];
        
        // Associate username and pasword for this AFManager
        [self setupAFManager];
        
        /*************************** Use AFNetWorking Manager to authenticate username and password ***************************/
        // Send a useless request just for authentication
        [AFManager GET:@"https://genie.ucsd.edu/api/v1/users/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self.hud hide:YES];
            
            // If the authentication is successful, then store the username and password into keychain for future auto login use
            [keychain setObject:self.usernameTextField.text forKey:(__bridge id)(kSecAttrAccount)];
            [keychain setObject:self.passwordTextField.text forKey:(__bridge id)(kSecValueData)];
            
            [self.RPKmanager stop];
            
            [self performSegueWithIdentifier:@"loginToChoose" sender:self];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self.hud hide:YES];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Your username or password is incorrect"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }];
    }
}

- (IBAction)loginButtonPressed:(UIButton *)sender {
    [self performLogin];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - AFManager setup helper method
-(void)setupAFManager{

    AFManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://genie.ucsd.edu"]];
    AFManager.requestSerializer = [AFJSONRequestSerializer serializer];
    [AFManager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.usernameTextField.text password:self.passwordTextField.text];
}

#pragma mark - Prepare for segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"loginToChoose"]){
        
        UINavigationController *navController = [segue destinationViewController];
        ChooseExperimentViewController *controller = (ChooseExperimentViewController *)([[navController viewControllers] lastObject]);
        
        controller.username = self.usernameTextField.text;
        controller.password = self.passwordTextField.text;
        controller.AFManager = AFManager;
        controller.RPKmanager = self.RPKmanager;
        
    }
}

#pragma mark - helper method, log information to the TextView console in the app

- (void)output:(NSString *)message
{
    self.SKTTxtOutput.text = [NSString stringWithFormat:@"%@\n%@", self.SKTTxtOutput.text, message];
    CGPoint p = [self.SKTTxtOutput contentOffset];
    [self.SKTTxtOutput setContentOffset:p animated:NO];
    [self.SKTTxtOutput scrollRangeToVisible:NSMakeRange([self.SKTTxtOutput.text length], 0)];
}

#pragma mark Helper method to get the current time string

- (NSString *)getCurrentTimeString
{
    NSDate *currentTime = [NSDate date];
    // Convert the time to local time zone
    NSTimeInterval timeZoneSeconds = [[NSTimeZone localTimeZone] secondsFromGMT];
    currentTime = [currentTime dateByAddingTimeInterval:timeZoneSeconds];
    NSString *currentTimeString = [NSString stringWithFormat:@"%@",currentTime];
    return currentTimeString;
}

#pragma mark Proximity Kit Delegate Methods

- (void)proximityKitDidSync:(RPKManager *)manager {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *message = [NSString stringWithFormat:@"LGVC: Did Sync AT TIME:%@", [self getCurrentTimeString]];
        [self output:message];
        NSLog(@"%@",message);
    });
}

- (void)proximityKit:(RPKManager *)manager didEnter:(RPKBeacon*)region {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *message = [NSString stringWithFormat:@"LGVC: Entered Region %@ (%@)!!!!!!!!!! AT TIME:%@", region.name, region.identifier, [self getCurrentTimeString]];
        [self output:message];
        NSLog(@"%@",message);
        
        // When enter an ibeacon region, try to perform auto login
        if ([[keychain objectForKey:(__bridge id)kSecAttrAccount] length])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *message = [NSString stringWithFormat:@"LGVC: AUTO LOGIN AT TIME: %@", [self getCurrentTimeString]];
                [self output:message];
            });
        
            [self performLogin];
        }
    });
}

- (void)proximityKit:(RPKManager *)manager didExit:(RPKBeacon *)region {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *message = [NSString stringWithFormat:@"LGVC: Exited Region %@ (%@)*********** AT TIME:%@", region.name, region.identifier, [self getCurrentTimeString]];
        [self output:message];
        NSLog(@"%@", message);
        
        NSString *message2 = [NSString stringWithFormat:@"LGVC: major value = %@", region.major];
        [self output:message2];
    });
}

- (void)proximityKit:(RPKManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(RPKBeacon *)region
{
    for (RPKBeacon *beacon in beacons) {
//        NSLog(@"LGVC: Ranged UUID: %@ Major:%@ Minor:%@ RSSI:%@", [beacon.uuid UUIDString], beacon.major, beacon.minor, beacon.rssi);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *message = [NSString stringWithFormat:@"LGVC: Ranged UUID: %@ Major:%@ Minor:%@ RSSI:%@", [beacon.uuid UUIDString], beacon.major, beacon.minor, beacon.rssi];
//            [self output:message];
        });
    }
}

- (void)proximityKit:(RPKManager *)manager didDetermineState:(RPKRegionState)state forRegion:(RPKRegion *)region
{
    if (state == RPKRegionStateInside) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *message = [NSString stringWithFormat:@"LGVC: State Changed: inside region %@ (%@) AT TIME:%@", region.name, region.identifier, [self getCurrentTimeString]];
            [self output:message];
            NSLog(@"%@",message);
        });
    } else if (state == RPKRegionStateOutside) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *message = [NSString stringWithFormat:@"LGVC: State Changed: outside region %@ (%@) AT TIME:%@", region.name, region.identifier, [self getCurrentTimeString]];
            [self output:message];
            NSLog(@"%@",message);
        });
    } else if (state == RPKRegionStateUnknown) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *message = [NSString stringWithFormat:@"LGVC: State Changed: unknown region %@ (%@) AT TIME:%@", region.name, region.identifier, [self getCurrentTimeString]];
            [self output:message];
            NSLog(@"%@",message);
        });
    }
}

- (void)proximityKit:(RPKManager *)manager didFailWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *message = [NSString stringWithFormat:@"LGVC: Error: %@ AT TIME:%@", error.description,[self getCurrentTimeString]];
        [self output:message];
        NSLog(@"%@", message);
    });
}

@end
