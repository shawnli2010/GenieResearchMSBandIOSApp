//
//  CollectDataViewController.m
//  BandSensor
//
//  Created by Xueyang Li on 7/7/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "CollectDataViewController.h"

@interface CollectDataViewController ()
{
    NSMutableArray *feelArray;
    UIPickerView *feelPicker;
    int feelInt;
    
}
@end

@implementation CollectDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.SKTTxtOutput setHidden:false];
    [self.currentSkinTempLabel setHidden:true];
    [self.dataRecordingTimeLabel setHidden:true];
    
    //keyboard disappear when tapping outside of text field
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    feelArray = [[NSMutableArray alloc] init];
    [feelArray addObject:@"GOOD"];
    [feelArray addObject:@"HOT"];
    [feelArray addObject:@"WARM"];
    [feelArray addObject:@"SLIGHTLY WARM"];
    [feelArray addObject:@"SLIGHTLY COOL"];
    [feelArray addObject:@"COOL"];
    [feelArray addObject:@"COLD"];
    
    [self addFeelPicker];
    
    // Automatically start skin temperature detecting
    if (self.client && self.client.isDeviceConnected)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Welcome!"
                                                        message:@"Skin temperature detection will start shortly"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [self startDetectingSkinTemp];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Band is not connected!Please press logout and re-login to reconnect the band"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}


# pragma mark - dismissKeyboard
-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

# pragma mark - helper method to wrap up the client delegate start detecting method
-(void)startDetectingSkinTemp
{
    [self output:@"Start detecting skin temperature..."];
    [self.client.sensorManager startSkinTempUpdatesToQueue:nil errorRef:nil withHandler:^(MSBSensorSkinTempData *skinTemperatureData, NSError *error) {
        
        //Check whether the user have changed their settings of reminder notification
        if(pushNotificationIsOn && !pushNotificationAlreadyOn)
        {
            NSDate *currentTime = [NSDate date];;
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.fireDate = currentTime;
            localNotification.alertBody = [NSString stringWithFormat:@"How are you feeling right now?"];
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            localNotification.applicationIconBadgeNumber = 1;
            localNotification.repeatInterval = NSCalendarUnitHour;
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            
            pushNotificationAlreadyOn = true;
        }
        else if(!pushNotificationIsOn)
        {
            // Delete all the previous notifications
            UIApplication *app = [UIApplication sharedApplication];
            NSArray *eventArray = [app scheduledLocalNotifications];
            for (int i=0; i<[eventArray count]; i++)
            {
                //Cancelling local notification
                [app cancelLocalNotification:eventArray[i]];
            }
            
            pushNotificationAlreadyOn = false;
        }
        
        // Convert c to f
        double fTemp = skinTemperatureData.temperature * (9.0/5.0) + 32;
        
        // Create the Json Object for skin temperature
        NSString *tempString = [NSString stringWithFormat:@"%.2f", fTemp];
        
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
        [self.AFManager POST:@"https://genie.ucsd.edu/api/v1/users/persistskintemperature" parameters:@{@"skin_temperature": tempString, @"room":self.roomArray[0], @"feeling":[NSNumber numberWithInt:feelInt]}
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

#pragma mark - Microsoft Band Client Manager Delegates

- (void)clientManager:(MSBClientManager *)clientManager clientDidConnect:(MSBClient *)client
{
    [self output:@"in CollectDataViewController clientDidConnect"];
    NSLog(@"in CollectDataViewController clientDidConnect");
}

- (void)clientManager:(MSBClientManager *)clientManager clientDidDisconnect:(MSBClient *)client
{
    [self output:@"in CollectDataViewController clientDidDisconnect"];
    NSLog(@"in CollectDataViewController clientDidDisconnect");
}

- (void)clientManager:(MSBClientManager *)clientManager client:(MSBClient *)client didFailToConnectWithError:(NSError *)error
{
    [self output:@"in CollectDataViewController didFailToConnectWithError"];
    NSLog(@"in CollectDataViewController didFailToConnectWithError");
}

# pragma mark - picker view helper method

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
        feelInt = -1;
    }
    else if([self.chooseFeelTextField.text isEqualToString:@"GOOD"])
    {
        feelInt = 0;
    }
    else if([self.chooseFeelTextField.text isEqualToString:@"WARM"])
    {
        feelInt = 1;
    }
    else if([self.chooseFeelTextField.text isEqualToString:@"SLIGHTLY WARM"])
    {
        feelInt = 2;
    }
    else if([self.chooseFeelTextField.text isEqualToString:@"HOT"])
    {
        feelInt = 3;
    }
    else if([self.chooseFeelTextField.text isEqualToString:@"SLIGHTLY COOL"])
    {
        feelInt = 4;
    }
    else if([self.chooseFeelTextField.text isEqualToString:@"COOL"])
    {
        feelInt = 5;
    }
    else if([self.chooseFeelTextField.text isEqualToString:@"COLD"])
    {
        feelInt = 6;
    }
    
    NSString *alertMessage = [@"You just set your feeling to " stringByAppendingString:self.chooseFeelTextField.text];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                    message:alertMessage
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
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

#pragma mark - helper method, log information to the TextView console in the app

- (void)output:(NSString *)message
{
    self.SKTTxtOutput.text = [NSString stringWithFormat:@"%@\n%@", self.SKTTxtOutput.text, message];
    CGPoint p = [self.SKTTxtOutput contentOffset];
    [self.SKTTxtOutput setContentOffset:p animated:NO];
    [self.SKTTxtOutput scrollRangeToVisible:NSMakeRange([self.SKTTxtOutput.text length], 0)];
}

#pragma mark - button pressed method
- (IBAction)settingButtonPressed:(UIBarButtonItem *)sender {
    [self performSegueWithIdentifier:@"CollectDataToSetting" sender:self];
}

- (IBAction)backButtonPressed:(UIBarButtonItem *)sender {
    [self.client.sensorManager stopSkinTempUpdatesErrorRef:nil];
    [self.navigationController popViewControllerAnimated:TRUE];
}

@end
