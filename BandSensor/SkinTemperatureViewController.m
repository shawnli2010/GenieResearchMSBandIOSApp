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
    
    NSMutableArray *feelArray;
    UIPickerView *feelPicker;
    int feelInt;
    
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
    [self.chooseFeelTextField setBorderStyle:UITextBorderStyleLine];
    
    // AFNetWorking Manager setup
    manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://genie.ucsd.edu"]];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.username password:self.password];
  
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
    [self addFeelPicker];
    
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
    
    feelArray = [[NSMutableArray alloc] init];
    [feelArray addObject:@"HOT"];
    [feelArray addObject:@"WARM"];
    [feelArray addObject:@"SLIGHTLY WARM"];
    [feelArray addObject:@"GOOD"];
    [feelArray addObject:@"SLIGHTLY COOL"];
    [feelArray addObject:@"COOL"];
    [feelArray addObject:@"COLD"];
    
    
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
    if(pickerView == roomPicker)
        return roomArray.count;
    else
        return feelArray.count;
}

#pragma mark- Picker View Delegate
-(NSString *)pickerView:(UIPickerView *)pickerView
            titleForRow:(NSInteger)row
           forComponent:(NSInteger)component
{
    if(pickerView == roomPicker)
        return [roomArray objectAtIndex:row];
    else
        return [feelArray objectAtIndex:row];;
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component
{
    if(pickerView == roomPicker)
        self.chooseRoomTextField.text = [NSString stringWithFormat:@"%@", [roomArray objectAtIndex:row]];
    else
        self.chooseFeelTextField.text = [NSString stringWithFormat:@"%@", [feelArray objectAtIndex:row]];
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
    
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(pickerDoneClicked1)];
    [barItems addObject:doneBtn];
    
    [mypickerToolbar setItems:barItems animated:YES];
    self.chooseRoomTextField.inputAccessoryView = mypickerToolbar;
}

-(void)pickerDoneClicked1
{
    [self.chooseRoomTextField resignFirstResponder];
}

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
    
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(pickerDoneClicked2)];
    [barItems addObject:doneBtn];
    
    [mypickerToolbar setItems:barItems animated:YES];
    self.chooseFeelTextField.inputAccessoryView = mypickerToolbar;
}

-(void)pickerDoneClicked2
{
    [self.chooseFeelTextField resignFirstResponder];
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
    [manager POST:@"https://genie.ucsd.edu/api/v1/users/changeroom/in" parameters:@{@"room_name":self.chooseRoomTextField.text} success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
            
            // Post data to Genie persistent skin temperature database, testing purpose only
            [manager POST:@"https://genie.ucsd.edu/api/v1/users/persistskintemperature" parameters:@{@"skin_temperature": tempString, @"room":self.chooseRoomTextField.text, @"feeling":[NSNumber numberWithInt:feelInt]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Success: %@",responseObject);
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Posting to Testing database %@", error.description);
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

- (IBAction)addFeelButtonPressed:(UIButton *)sender {
    if([self.chooseFeelTextField.text isEqualToString:@""])
    {
        feelInt = -1;
    }
    else if([self.chooseFeelTextField.text isEqualToString:@"HOT"])
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
    else if([self.chooseFeelTextField.text isEqualToString:@"GOOD"])
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


@end
