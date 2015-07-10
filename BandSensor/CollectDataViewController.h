//
//  CollectDataViewController.h
//  BandSensor
//
//  Created by Xueyang Li on 7/7/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MicrosoftBandKit_iOS/MicrosoftBandKit_iOS.h>

#import "AFNetworking.h"
#import "MBProgressHUD.h"

@interface CollectDataViewController : UIViewController <MSBClientManagerDelegate,UIPickerViewDataSource,UIPickerViewDelegate>

extern BOOL pushNotificationIsOn;
extern BOOL pushNotificationAlreadyOn;

@property (nonatomic, weak) MSBClient *client;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (weak, nonatomic) IBOutlet UITextView *SKTTxtOutput;

@property(nonatomic) NSString *username;
@property(nonatomic) NSString *password;

@property (weak, nonatomic) IBOutlet UITextField *chooseFeelTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *SettingButton;

@property (weak, nonatomic) IBOutlet UILabel *currentSkinTempLabel;
@property (weak, nonatomic) IBOutlet UILabel *dataRecordingTimeLabel;

@end
