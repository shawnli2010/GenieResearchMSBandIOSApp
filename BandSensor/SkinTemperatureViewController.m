//
//  SkinTemperatureViewController.m
//  
//
//  Created by Xueyang Li on 5/10/15.
//
//

#import "SkinTemperatureViewController.h"

@interface SkinTemperatureViewController ()
{
    NSMutableArray *roomArray;
    UIPickerView *roomPicker;
    
    AFHTTPRequestOperationManager *manager;
}
@end

@implementation SkinTemperatureViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.inOutLabel.text = @"OUT";
    self.roomNumberLabel.text = @"";
    [self.inOutLabel setTextAlignment:NSTextAlignmentCenter];
    [self.roomNumberLabel setTextAlignment:NSTextAlignmentCenter];
    
    [self.chooseRoomTextField setBorderStyle:UITextBorderStyleLine];
    
    // AFNetWorking Manager setup
    manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://genie.ucsd.edu"]];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"genie.calendar.ucsd@gmail.com" password:@"5056789"];
  
    // Fetch the user's rooms
    roomArray = [[NSMutableArray alloc] init];
    [roomArray addObject:@""];
    
    // Get the rooms of this user
    // Post the data to Genie
    [manager GET:@"https://genie.ucsd.edu/api/v1/users/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        int i = 0;
        for(NSString *roomNumber in responseObject[@"rooms"])
        {
            [roomArray addObject:responseObject[@"rooms"][i][@"room"]];
            i++;
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self output:[NSString stringWithFormat:@"Error: %@", error]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Failed to fetch rooms for the user"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }];
    
    [self addRoomPicker];
    
    self.hud = [[MBProgressHUD alloc] init];
    [self.view addSubview:self.hud];
    self.hud.labelText = @"Connecting to the band...";
    self.hud.yOffset = -100;
    [self.hud show:YES];

    // Microsoft Band Manager setup
    [MSBClientManager sharedManager].delegate = self;
    NSArray	*clients = [[MSBClientManager sharedManager] attachedClients];
    _client = [clients firstObject];
    if ( _client == nil )
    {
        [self.hud hide:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed"
                                                        message:@"No Bands Attached to the Phone"
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
    [self.hud hide:YES];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                    message:@"Band connected!"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)clientManager:(MSBClientManager *)clientManager clientDidDisconnect:(MSBClient *)client
{
    [self output:@"in ConnectedViewController disconnected"];
}

- (void)clientManager:(MSBClientManager *)clientManager client:(MSBClient *)client didFailToConnectWithError:(NSError *)error
{
    [self output:@"in ConnectedViewController failed to connect to band"];
}

/*************************************************************************************/
#pragma mark - Picker View Data source
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent: (NSInteger)component {
    return roomArray.count;
}

#pragma mark- Picker View Delegate
-(NSString *)pickerView:(UIPickerView *)pickerView
            titleForRow:(NSInteger)row
           forComponent:(NSInteger)component
{
    return [roomArray objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component
{
    self.chooseRoomTextField.text = [NSString stringWithFormat:@"%@", [roomArray objectAtIndex:row]];
}

#pragma mark - add picker helper method
// Helper method to add the picker
-(void)addRoomPicker
{
    roomPicker = [[UIPickerView alloc] initWithFrame:CGRectZero];
    roomPicker.delegate = self;
    roomPicker.dataSource = self;
    [roomPicker setShowsSelectionIndicator:YES];
    self.chooseRoomTextField.inputView = roomPicker;
    
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
    self.chooseRoomTextField.inputAccessoryView = mypickerToolbar;
}

-(void)pickerDoneClicked
{
    [self.chooseRoomTextField resignFirstResponder];
}

- (void)output:(NSString *)message
{
    self.SKTTxtOutput.text = [NSString stringWithFormat:@"%@\n%@", self.SKTTxtOutput.text, message];
    CGPoint p = [self.SKTTxtOutput contentOffset];
    [self.SKTTxtOutput setContentOffset:p animated:NO];
    [self.SKTTxtOutput scrollRangeToVisible:NSMakeRange([self.SKTTxtOutput.text length], 0)];
}

/*************************************************************************************/
#pragma mark - Button Pressed methods
- (IBAction)inButtonPressed:(UIButton *)sender {
    if([self.chooseRoomTextField.text isEqualToString:@""])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Please choose your room number"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    self.inOutLabel.text = @"IN";
    self.roomNumberLabel.text = self.chooseRoomTextField.text;
    
    // Post the data to Genie
    [manager POST:@"https://genie.ucsd.edu/api/v1/users/changeroom/in" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"JSON: %@", responseObject);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                        message:@"Set status as IN the room"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self output:[NSString stringWithFormat:@"Error: %@", error]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Failed to set in/out status"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }];
    
    // Start the band's skin temperature detecting
    if (self.client && self.client.isDeviceConnected)
    {
        [self output:@"Starting skin temperature updates..."];
        [self.client.sensorManager startSkinTempUpdatesToQueue:nil errorRef:nil withHandler:^(MSBSensorSkinTempData *skinTemperatureData, NSError *error) {
            
            // Convert c to f
            double fTemp = skinTemperatureData.temperature * (9.0/5.0) + 32;
            
            // Create the Json Object for skin temperature
            NSString *tempString = [NSString stringWithFormat:@"%f", fTemp];
            
            // Post the data to Genie
            [manager POST:@"https://genie.ucsd.edu/api/v1/users/skintemperature" parameters:@{@"skin_temperature": tempString} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                NSDate *date = [NSDate date];
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
                NSString *string2 = [formatter stringFromDate:date];
                
                NSString* outString = [NSString stringWithFormat:@"%@:   %@ f", string2, tempString];
                [self output:outString];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self output:[NSString stringWithFormat:@"Error: %@", error]];
            }];
        }];
        
        [self.client.sensorManager startBandContactUpdatesToQueue:nil errorRef:nil withHandler:^(MSBSensorBandContactData *contactData, NSError *error) {
            NSString *myString = [NSString stringWithFormat:@"Wear State, %d", (int)(contactData.wornState)];
            NSDate *date = [NSDate date];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"%hh:%mm:%ss"];
            NSString *timeString = [formatter stringFromDate:date];
            NSString* outString = [NSString stringWithFormat:@"%@, %@", myString, timeString];
            NSLog(@"%@",outString);
        }];
    }
    else
    {
        [self output:@"Band is not connected. Please wait...."];
    }
}

- (IBAction)outButtonPressed:(UIButton *)sender {
    // Post the data to Genie
    [manager POST:@"https://genie.ucsd.edu/api/v1/users/changeroom/out" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                        message:@"Set status as OUT of the room"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self output:[NSString stringWithFormat:@"Error: %@", error]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Failed to set in/out status"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }];
    
    [self output:@"Stop temperature detection"];
    [self.client.sensorManager stopSkinTempUpdatesErrorRef:nil];
    
    self.inOutLabel.text = @"OUT";
    self.roomNumberLabel.text = @"";
    
}

@end
