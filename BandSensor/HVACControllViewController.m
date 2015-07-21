//
//  SkinTemperatureViewController.m
//  
//
//  Created by Xueyang Li on 5/10/15.
//
//

#import "HVACControllViewController.h"
#import "AppDelegate.h"

@interface HVACControllViewController () <UIAlertViewDelegate>
{
    NSMutableArray *feelArray;
    UIPickerView *feelPicker;
    int feelInt;
    
    NSUserDefaults *userDefaults;
    
    NSTimer *timerA;
    NSTimer *timerB;
    
    NSInteger checkRangeCounter;
    NSInteger checkRangeInt;
    
    NSString *tString;  // get a local var from a method
}
@end

@implementation HVACControllViewController
@synthesize isInIBeaconRange;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.RPKmanager = [RPKManager managerWithDelegate:self];
    [self.RPKmanager start];
    
    /************************************************** Get the app start time *****************************************/
    NSDate *currentTime = [NSDate date];
    // Convert the time to local time zone
    NSTimeInterval timeZoneSeconds = [[NSTimeZone localTimeZone] secondsFromGMT];
    currentTime = [currentTime dateByAddingTimeInterval:timeZoneSeconds];
    
    NSString *startString = [NSString stringWithFormat:@"App Starts at %@", currentTime];
    [self output:startString];
    /************************************************** Get the app start time *****************************************/
    
    [self.chooseFeelTextField setBorderStyle:UITextBorderStyleLine];
    
    [self addFeelPicker];
    
    //keyboard disappear when tapping outside of text field
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    feelArray = [[NSMutableArray alloc] init];
    [feelArray addObject:@""];    
    [feelArray addObject:@"GOOD"];
    [feelArray addObject:@"HOT"];
    [feelArray addObject:@"WARM"];
    [feelArray addObject:@"SLIGHTLY WARM"];
    [feelArray addObject:@"SLIGHTLY COOL"];
    [feelArray addObject:@"COOL"];
    [feelArray addObject:@"COLD"];
    
    userDefaults = [NSUserDefaults standardUserDefaults];
    
    [self configureLayout];
    
    [self addObserver:self forKeyPath:@"isInIBeaconRange" options:0 context:nil];
    
    timerA = [NSTimer scheduledTimerWithTimeInterval:1
                                              target:self
                                            selector:@selector(timerACheck)
                                            userInfo:nil
                                             repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timerA forMode:NSRunLoopCommonModes];
    
    checkRangeCounter = 2;
    checkRangeInt = 0;

//    [self startDetectingSkinTemp];
//    [self performSelector:@selector(startDetectingSkinTemp) withObject:nil afterDelay:120];
    [self checkWornCondition];
}

// Listen to the property to check whether is in ibeacon region or not
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [keyPath isEqualToString:@"isInIBeaconRange"])
    {
        if(self.isInIBeaconRange)
        {
            [self startDetectingSkinTemp];
            self.inOutLabel.text = @"IN the room";
            self.roomNumberLabel.text = [userDefaults objectForKey:@"current_room"];
        }
        else
        {
            self.inOutLabel.text = @"OUT of room";
            self.roomNumberLabel.text = @"";
            [self.client.sensorManager stopSkinTempUpdatesErrorRef:nil];
            [self output:@"Stop skin temperature detection"];
        }
    }
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
        self.isInIBeaconRange = inIbeaconRange;
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
        
        // Turn ON pushnotification
        [userDefaults setBool:true forKey:@"pushNotificationIsOn"];
        
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
        self.isInIBeaconRange = inIbeaconRange;
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
        
        // Turn OFF the pushnotification
        [userDefaults setBool:false forKey:@"pushNotificationIsOn"];
        [userDefaults setBool:false forKey:@"pushNotificationAlreadyOn"];
        
        [timerB invalidate];
    }
}

-(void)configureLayout
{
    [self.currentSkinTempLabel setHidden:true];
    [self.dataRecordingTimeLabel setHidden:true];
    [self.inOutLabel setHidden:true];
    [self.roomNumberLabel setHidden:true];
    [self.lastFeelingLabel setHidden:true];
    
//    [self.SKTTxtOutput setHidden:true];
    
    [self.roomNumberLabel setHidden:false];
    [self.roomNumberLabel setText:[userDefaults objectForKey:@"current_room"]];
    NSLog(@"check userDefaults: %@",[userDefaults objectForKey:@"current_room"]);
    
    [self.inOutLabel setHidden:false];
    self.inOutLabel.text = @"IN the room";
    
    [self.inOutLabel setTextAlignment:NSTextAlignmentCenter];
    [self.roomNumberLabel setTextAlignment:NSTextAlignmentCenter];
    [self.currentSkinTempLabel setTextAlignment:NSTextAlignmentCenter];
    [self.dataRecordingTimeLabel setTextAlignment:NSTextAlignmentCenter];
}


# pragma mark - dismissKeyboard
-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

/*************************************************************************************/
#pragma mark - Picker View Data source
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent: (NSInteger)component {
    return feelArray.count;
}

#pragma mark- Picker View Delegate
-(NSString *)pickerView:(UIPickerView *)pickerView
            titleForRow:(NSInteger)row
           forComponent:(NSInteger)component
{
    return [feelArray objectAtIndex:row];;
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component
{
    self.chooseFeelTextField.text = [NSString stringWithFormat:@"%@", [feelArray objectAtIndex:row]];
}

#pragma mark - add picker helper method

-(void)addFeelPicker
{
    feelPicker = [[UIPickerView alloc] initWithFrame:CGRectZero];
    feelPicker.delegate = self;
    feelPicker.dataSource = self;
    [feelPicker setShowsSelectionIndicator:YES];
    self.chooseFeelTextField.inputView = feelPicker;
    
    // Create done button in UIPickerView
    UIToolbar*  mypickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
    mypickerToolbar.barStyle = UIBarStyleBlackOpaque;
    [mypickerToolbar sizeToFit];
    NSMutableArray *barItems = [[NSMutableArray alloc] init];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    [barItems addObject:flexSpace];
    
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(pickerDoneClicked)];
    [barItems addObject:doneBtn];
    
    [mypickerToolbar setItems:barItems animated:YES];
    self.chooseFeelTextField.inputAccessoryView = mypickerToolbar;
}

-(void)pickerDoneClicked
{
    [self.chooseFeelTextField resignFirstResponder];
    
    if([self.chooseFeelTextField.text isEqualToString:@""])
    {
        feelInt = 100;
    }
    else if([self.chooseFeelTextField.text isEqualToString:@"GOOD"])
    {
        feelInt = 0;
    }
    else if([self.chooseFeelTextField.text isEqualToString:@"WARM"])
    {
        feelInt = 2;
    }
    else if([self.chooseFeelTextField.text isEqualToString:@"SLIGHTLY WARM"])
    {
        feelInt = 1;
    }
    else if([self.chooseFeelTextField.text isEqualToString:@"HOT"])
    {
        feelInt = 3;
    }
    else if([self.chooseFeelTextField.text isEqualToString:@"SLIGHTLY COOL"])
    {
        feelInt = -1;
    }
    else if([self.chooseFeelTextField.text isEqualToString:@"COOL"])
    {
        feelInt = -2;
    }
    else if([self.chooseFeelTextField.text isEqualToString:@"COLD"])
    {
        feelInt = -3;
    }
    
    if(tString && self.isInIBeaconRange)
    {
        [self.AFManager POST:@"https://genie.ucsd.edu/api/v1/users/persistskintemperature" parameters:@{@"skin_temperature": tString, @"room":[userDefaults objectForKey:@"current_room"], @"feeling":[NSNumber numberWithInt:feelInt]}
                     success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSLog(@"Success: %@",responseObject);
         }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
         {
             NSLog(@"Posting to Testing database %@", error.description);
         }];
    }
    
    [self.lastFeelingLabel setHidden:false];
    [self.lastFeelingLabel setText:self.chooseFeelTextField.text];
    
    [self.chooseFeelTextField setText:@""];
}

#pragma mark - helper method, log information to the TextView console in the app

- (void)output:(NSString *)message
{
    self.SKTTxtOutput.text = [NSString stringWithFormat:@"%@\n%@", self.SKTTxtOutput.text, message];
    CGPoint p = [self.SKTTxtOutput contentOffset];
    [self.SKTTxtOutput setContentOffset:p animated:NO];
    [self.SKTTxtOutput scrollRangeToVisible:NSMakeRange([self.SKTTxtOutput.text length], 0)];
}
# pragma mark - helper method to wrap up the client delegate start detecting method
-(void)startDetectingSkinTemp
{
    [self output:@"Start detecting skin temperature..."];
    [self.client.sensorManager startSkinTempUpdatesToQueue:nil errorRef:nil withHandler:^(MSBSensorSkinTempData *skinTemperatureData, NSError *error) {
        
        //Check whether the user have changed their settings of reminder notification
        if( [userDefaults boolForKey:@"pushNotificationIsOn"] && ![userDefaults boolForKey:@"pushNotificationAlreadyOn"])
        {
            NSDate *currentTime = [NSDate date];;
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.fireDate = currentTime;
            localNotification.alertBody = [NSString stringWithFormat:@"How are you feeling right now?"];
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            localNotification.applicationIconBadgeNumber = 1;
            localNotification.repeatInterval = NSCalendarUnitHour;
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            
            [userDefaults setBool:true forKey:@"pushNotificationAlreadyOn"];
        }
        else if(![userDefaults boolForKey:@"pushNotificationIsOn"])
        {
            // Delete all the previous notifications
            UIApplication *app = [UIApplication sharedApplication];
            NSArray *eventArray = [app scheduledLocalNotifications];
            for (int i=0; i<[eventArray count]; i++)
            {
                //Cancelling local notification
                [app cancelLocalNotification:eventArray[i]];
            }
            
            [userDefaults setBool:false forKey:@"pushNotificationAlreadyOn"];
        }
        
        
        // Convert c to f
        double fTemp = skinTemperatureData.temperature * (9.0/5.0) + 32;
        
        // Create the Json Object for skin temperature
        NSString *tempString = [NSString stringWithFormat:@"%.2f", fTemp];
        tString = tempString;
        
        /*************************** Post the data to Genie ***************************/
        [self.AFManager POST:@"https://genie.ucsd.edu/api/v1/users/skintemperature" parameters:@{@"skin_temperature": tempString}
                     success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSDate *date = [NSDate date];
             NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
             [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
             NSString *timeString = [formatter stringFromDate:date];
             
             NSString* outString = [NSString stringWithFormat:@"%@:   %@ f", timeString, tempString];
             
             [self output:outString];
             NSLog(@"%@",outString);
             
             [self.dataRecordingTimeLabel setText:timeString];
             [self.currentSkinTempLabel setText:tempString];
             [self.currentSkinTempLabel setHidden:false];
             [self.dataRecordingTimeLabel setHidden:false];
             
         }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
         {
             [self output:[NSString stringWithFormat:@"Error: %@", error]];
             NSLog(@"%@",[NSString stringWithFormat:@"Error: %@", error]);
         }];
        
        /*************************** Post data to Genie persistent skin temperature database, testing purpose only ***************************/
        [self.AFManager POST:@"https://genie.ucsd.edu/api/v1/users/persistskintemperature" parameters:@{@"skin_temperature": tempString, @"room":[userDefaults objectForKey:@"current_room"], @"feeling":[NSNumber numberWithInt:99]}
                     success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSLog(@"Success: %@",responseObject);
         }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
         {
             NSLog(@"Posting to Testing database %@", error.description);
         }];
    }];
}

#pragma mark - Helper method to check whether the user is wearing the band or not
-(void)checkWornCondition
{
    //  An event(wear to take off the band) has to happen in order for the following chunk of code to execute
    [self.client.sensorManager startBandContactUpdatesToQueue:nil errorRef:nil withHandler:^(MSBSensorBandContactData *contactData, NSError *error) {
        // Check whether the user is wearing the band or not
        if(!contactData.wornState)
        {
            [self.client.sensorManager stopSkinTempUpdatesErrorRef:nil];
        }
        else
        {
            [self performSelector:@selector(startDetectingSkinTemp) withObject:nil afterDelay:180];
        }
    }];
}


/*************************************************************************************/
#pragma mark - Button Pressed methods

- (IBAction)backButtonPressed:(UIBarButtonItem *)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm"
                                                    message:@"Go back to experiments choosing page will stop skin temperature detecting, are your sure you want to go back?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Yes", nil];
    [alert show];
}

- (IBAction)settingButtonPressed:(UIBarButtonItem *)sender {
    [self performSegueWithIdentifier:@"HVACToSetting" sender:self];
}


#pragma mark - Microsoft Band Client Manager Delegates

- (void)clientManager:(MSBClientManager *)clientManager clientDidConnect:(MSBClient *)client
{
    [self output:@"in HVACViewController clientDidConnect"];
    NSLog(@"in HVACViewController clientDidConnect");
}

- (void)clientManager:(MSBClientManager *)clientManager clientDidDisconnect:(MSBClient *)client
{
    [self output:@"in HVACViewController clientDidDisconnect"];
    NSLog(@"in HVACViewController clientDidDisconnect");
}

- (void)clientManager:(MSBClientManager *)clientManager client:(MSBClient *)client didFailToConnectWithError:(NSError *)error
{
    [self output:@"in HVACViewController didFailToConnectWithError"];
    NSLog(@"in HVACViewController didFailToConnectWithError");
}

#pragma mark Proximity Kit Delegate Methods

- (void)proximityKitDidSync:(RPKManager *)manager {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self output:@"HVACVC: Did Sync"];
    });
    NSLog(@"HVACVC: Did Sync");
    
}
- (void)proximityKit:(RPKManager *)manager didEnter:(RPKBeacon*)region {
//    NSLog(@"HVACVC: Entered Region %@ (%@)", region.name, region.identifier);
//    dispatch_async(dispatch_get_main_queue(), ^{
//        NSString *message = [NSString stringWithFormat:@"HVACVC: Entered Region %@ (%@)!!!!!!!", region.name, region.identifier];
//        [self output:message];
//        
//        // Check whether the beacon's room number belongs to this user or not
//        for(NSString *room_number in roomArray)
//        {
//            if([room_number isEqualToString:[region.major stringValue]])
//            {
//                inIbeaconRange = true;
//                [userDefaults setObject:room_number forKey:@"current_room"];
//            
//                self.inOutLabel.text = @"IN the room";
//                self.roomNumberLabel.text = [userDefaults objectForKey:@"current_room"];
//                
//                
//                [self.AFManager POST:@"https://genie.ucsd.edu/api/v1/users/changeroom/in" parameters:@{@"room_name":[userDefaults objectForKey:@"current_room"]}
//                             success:^(AFHTTPRequestOperation *operation, id responseObject)
//                 {
//                     [self output:@"Set status as IN the room"];
//                     NSLog(@"Set status as IN the room");
//                 }
//                             failure:^(AFHTTPRequestOperation *operation, NSError *error)
//                 {
//                     NSLog(@"Faile to set room in/out status, error:%@", error.description);
//                 }];
//                
//                [self startDetectingSkinTemp];
//            }
//        }
//    });
}

- (void)proximityKit:(RPKManager *)manager didExit:(RPKBeacon *)region {
//    NSLog(@"HVACVC: Exited Region %@ (%@)", region.name, region.identifier);
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        NSString *message = [NSString stringWithFormat:@"HVACVC: Exited Region %@ (%@)******************", region.name, region.identifier];
//        [self output:message];
//        
//        // Check whether the user is getting out of the current room or not
//        NSString *current_room = [userDefaults objectForKey:@"current_room"];
//        [self output:current_room];
//        [self output:@"*****************~~~~~~~~~~~~~~~~~~~~~~~~~"];
//        [self output:[region.major stringValue]];
//        if([current_room isEqualToString:[region.major stringValue]])
//        {
//            inIbeaconRange = false;
//            [userDefaults setObject:@"" forKey:@"current_room"];
//            
//            self.inOutLabel.text = @"OUT of room";
//            self.roomNumberLabel.text = @"";
//            
//            [self.AFManager POST:@"https://genie.ucsd.edu/api/v1/users/changeroom/out" parameters:nil
//                         success:^(AFHTTPRequestOperation *operation, id responseObject)
//             {
//                 [self output:@"Set status as OUT the room"];
//                 NSLog(@"Set status as OUT the room");
//             }
//                         failure:^(AFHTTPRequestOperation *operation, NSError *error)
//             {
//                 NSLog(@"Faile to set room in/out status, error:%@", error.description);
//             }];
//       
//            [self output:@"Stop temperature detection"];
//            [self.client.sensorManager stopSkinTempUpdatesErrorRef:nil];
//        }
//        
//    });
}

- (void)proximityKit:(RPKManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(RPKBeacon *)region
{
    for (RPKBeacon *beacon in beacons) {
        NSString *message = [NSString stringWithFormat:@"HVACVC: Ranged identifier: %@ Major:%@ RSSI:%@",beacon.identifier,beacon.major,beacon.rssi];
        NSLog(@"%@", message);
        
        if([[userDefaults objectForKey:@"current_room"] isEqualToString:[beacon.major stringValue]])
        {
            checkRangeCounter++;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            //            [self output:message];
        });
    }
}

- (void)proximityKit:(RPKManager *)manager didDetermineState:(RPKRegionState)state forRegion:(RPKRegion *)region
{
//    if (state == RPKRegionStateInside) {
//        NSLog(@"HVACVC: State Changed: inside region %@ (%@)", region.name, region.identifier);
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSString *message = [NSString stringWithFormat:@"HVACVC: State Changed: inside region %@ (%@)", region.name, region.identifier];
//            [self output:message];
//        });
//    } else if (state == RPKRegionStateOutside) {
//        NSLog(@"HVACVC: State Changed: outside region %@ (%@)", region.name, region.identifier);
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSString *message = [NSString stringWithFormat:@"HVACVC: State Changed: outside region %@ (%@)", region.name, region.identifier];
//            [self output:message];
//        });
//    } else if (state == RPKRegionStateUnknown) {
//        NSLog(@"HVACVC: State Changed: unknown region %@ (%@)", region.name, region.identifier);
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSString *message = [NSString stringWithFormat:@"HVACVC: State Changed: unknown region %@ (%@)", region.name, region.identifier];
//            [self output:message];
//        });
//    }
}

- (void)proximityKit:(RPKManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"HVACVC: Error: %@", error.description);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *message = [NSString stringWithFormat:@"HVACVC: Error: %@", error.description];
        [self output:message];
    });
}

# pragma mark - Alert view delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if([alertView.title isEqualToString:@"Confirm"])
    {
        if(buttonIndex == 1)
        {
            [self.RPKmanager stop];
            [self.client.sensorManager stopSkinTempUpdatesErrorRef:nil];
            [timerA invalidate];
            [timerB invalidate];
            [self removeObserver:self forKeyPath:@"isInIBeaconRange"];
            [self.navigationController popViewControllerAnimated:TRUE];
        }
    }
}


@end
