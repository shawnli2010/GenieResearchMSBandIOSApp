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

@interface ChooseExperimentViewController () <UIAlertViewDelegate>
{
    NSUserDefaults *userDefaults;
    
    BOOL onThisVC;
    
    NSTimer *timerA;
    NSTimer *timerB;
    
    NSInteger checkRangeCounter;
    NSInteger checkRangeInt;
    
}

@end

@implementation ChooseExperimentViewController

@synthesize isInBeaconRange;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.SKTTxtOutput setHidden:true];
    
    [self configureLayout];
    [self setUpMicrosoftBandManager];
    [self fetchRooms];

    userDefaults = [NSUserDefaults standardUserDefaults];
    
    self.RPKmanager = [RPKManager managerWithDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.RPKmanager start];
    onThisVC = true;
    
    timerA = [NSTimer scheduledTimerWithTimeInterval:1
                                              target:self
                                            selector:@selector(timerACheck)
                                            userInfo:nil
                                             repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timerA forMode:NSRunLoopCommonModes];
    
    checkRangeCounter = 2;
    checkRangeInt = 0;
    
    NSLog(@"IN ChooseExperiment VIEWDIDAPPEAR!!!!");
}

-(void)timerACheck
{
    [self output:@"I am OUT of region"];
    if(checkRangeCounter != 2)
    {
        timerB = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(timerBCheck)
                                                userInfo:nil
                                                 repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timerB forMode:NSRunLoopCommonModes];
        [self output:@"I just got INTO the region!!!!!!"];
        
        inIbeaconRange = TRUE;
        // Set status as IN the room
        [self.AFManager POST:@"https://genie.ucsd.edu/api/v1/users/changeroom/in" parameters:@{@"room_name":[userDefaults objectForKey:@"current_room"]}
                     success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             [self output:@"Set status as IN the room"];
             NSLog(@"Set status as IN the room");
         }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
         {
             NSLog(@"Faile to set room in/out status, error:%@", error.description);
         }];
        
        [timerA invalidate];
    }
}

-(void)timerBCheck
{
    if(checkRangeCounter > checkRangeInt)
    {
        [self output:@"I am INSIDE the region"];
        checkRangeInt++;
    }
    else
    {
        checkRangeCounter = 2;
        checkRangeInt = 0;
        
        timerA = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(timerACheck)
                                                userInfo:nil
                                                 repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timerA forMode:NSRunLoopCommonModes];
        [self output:@"I just got OUT of the region*********"];

        inIbeaconRange = FALSE;
        // Set status as OUT the room
        [self.AFManager POST:@"https://genie.ucsd.edu/api/v1/users/changeroom/out" parameters:nil
                     success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             [self output:@"Set status as OUT the room"];
             NSLog(@"Set status as OUT the room");
         }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
         {
             NSLog(@"Faile to set room in/out status, error:%@", error.description);
         }];
        
        [timerB invalidate];
    }
}

# pragma mark - Configure UI
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
            
            // If the user has chosen HVAC experiment before
            // AND the user is in ibeacon range right now
            // then auto navigate user to HVAC control
            BOOL isHVAC = [userDefaults boolForKey:@"isHVAC"];
            
            if(isHVAC) NSLog(@"isHVAC == TRUE !!!~~~!!!~~~");
            if(inIbeaconRange) NSLog(@"inIbeaconRange == TRUE !!!~~~!!!~~~");
            
            if(inIbeaconRange && isHVAC)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm"
                                                                message:@"Are you wearing the band right now?"
                                                               delegate:self
                                                      cancelButtonTitle:@"NO"
                                                      otherButtonTitles:@"YES", nil];
                [alert show];
            }
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
        controller.client = self.client;
    }
    
    if([segue.identifier isEqualToString:@"ChooseToHVACControl"]){
        HVACControllViewController *controller = (HVACControllViewController *)segue.destinationViewController;
        
        controller.AFManager = self.AFManager;
        controller.client = self.client;
//        controller.RPKmanager = self.RPKmanager;
    }
    
}

#pragma mark Proximity Kit Delegate Methods

- (void)proximityKitDidSync:(RPKManager *)manager {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *message = [NSString stringWithFormat:@"CEVC: Did Sync AT TIME:%@", [self getCurrentTimeString]];
        [self output:message];
        NSLog(@"%@",message);
    });
}

- (void)proximityKit:(RPKManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(RPKBeacon *)region
{
    for (RPKBeacon *beacon in beacons) {
        NSString *message = [NSString stringWithFormat:@"CEVC: Ranged identifier: %@ Major:%@ RSSI:%@",beacon.identifier,beacon.major,beacon.rssi];
        NSLog(@"%@", message);
        
        for(NSString *room_number in roomArray)
        {
            if([room_number isEqualToString:[beacon.major stringValue]])
            {
                checkRangeCounter++;
                if(onThisVC) [userDefaults setObject:room_number forKey:@"current_room"];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
//            [self output:message];
         });
    }
}

- (void)proximityKit:(RPKManager *)manager didDetermineState:(RPKRegionState)state forRegion:(RPKBeacon *)region
{
//    if (state == RPKRegionStateInside) {
//        
//        // Check whether the beacon's room number belongs to this user or not
//        for(NSString *room_number in roomArray)
//        {
//            if([room_number isEqualToString:[region.major stringValue]])
//            {
//                inIbeaconRange = true;
//                if(onThisVC) [userDefaults setObject:room_number forKey:@"current_room"];
//            }
//        }
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSString *message = [NSString stringWithFormat:@"CEVC: State Changed: inside region %@ (%@) AT TIME:%@", region.name, region.identifier, [self getCurrentTimeString]];
//            [self output:message];
//            NSLog(@"%@",message);
//        });
//        
//    } else if (state == RPKRegionStateOutside) {
//        
//        // Check whether the user is getting out of the current room or not
//        NSString *current_room = [userDefaults objectForKey:@"current_room"];
//        if([current_room isEqualToString:[region.major stringValue]])
//        {
//            inIbeaconRange = false;
//            if(onThisVC) [userDefaults setObject:@"" forKey:@"current_room"];
//        }
//
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSString *message = [NSString stringWithFormat:@"CEVC: State Changed: outside region %@ (%@) AT TIME:%@", region.name, region.identifier, [self getCurrentTimeString]];
//            [self output:message];
//            NSLog(@"%@",message);
//        });
//    } else if (state == RPKRegionStateUnknown) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSString *message = [NSString stringWithFormat:@"CEVC: State Changed: unknown region %@ (%@) AT TIME:%@", region.name, region.identifier, [self getCurrentTimeString]];
//            [self output:message];
//            NSLog(@"%@",message);
//        });
//    }
}

- (void)proximityKit:(RPKManager *)manager didFailWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *message = [NSString stringWithFormat:@"CEVC: Error: %@ AT TIME:%@", error.description,[self getCurrentTimeString]];
        [self output:message];
        NSLog(@"%@", message);
    });
}

#pragma mark - Button Pressed Methods
- (IBAction)jcdButtonPressed:(UIButton *)sender {
    [self.RPKmanager stop];
    onThisVC = false;
    [timerA invalidate];
    [timerB invalidate];
    [self performSegueWithIdentifier:@"ChooseToJustCollectData" sender:self];
}

- (IBAction)hvacButtonPressed:(UIButton *)sender {
    [userDefaults setBool:true forKey:@"isHVAC"];
    
    if(inIbeaconRange)
    {
        [self.RPKmanager stop];
        onThisVC = false;
        [timerA invalidate];
        [timerB invalidate];
        [self performSegueWithIdentifier:@"ChooseToHVACControl" sender:self];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"You cannot start HVAC Control experiment because your are not in your room"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (IBAction)logoutButtonPressed:(UIBarButtonItem *)sender {
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"Credential" accessGroup:nil];
    [keychain resetKeychainItem];

    isFromLogout = TRUE;
    
    [self.RPKmanager stop];
    [[MSBClientManager sharedManager] cancelClientConnection:self.client];
    
    NSLog(@"roomArray: %@",roomArray);
    [timerA invalidate];
    [timerB invalidate];

    [self.navigationController dismissViewControllerAnimated:TRUE completion:nil];
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

# pragma mark - Alert view delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if([alertView.title isEqualToString:@"Confirm"])
    {
        if(buttonIndex == 1)
        {
            [self.RPKmanager stop];
            onThisVC = false;
            [timerA invalidate];
            [timerB invalidate];
            
            NSLog(@"Auto NAVIGATE TO HVAC~~~~~~");
            
            [self performSegueWithIdentifier:@"ChooseToHVACControl" sender:self];
        }
    }
}

@end
