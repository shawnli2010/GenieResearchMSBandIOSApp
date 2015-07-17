//
//  ChooseExperimentViewController.h
//  BandSensor
//
//  Created by Xueyang Li on 7/15/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KeychainItemWrapper.h"
#import <MicrosoftBandKit_iOS/MicrosoftBandKit_iOS.h>
#import "MBProgressHUD.h"
#import "AFNetworking.h"





@interface ChooseExperimentViewController : UIViewController <MSBClientManagerDelegate>
extern BOOL isFromLogout;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hvacButtonHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *justCollectDataButtonHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *jcdTopSpace;

@property(nonatomic) NSString *username;
@property(nonatomic) NSString *password;

@property (nonatomic, weak) MSBClient *client;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) AFHTTPRequestOperationManager *AFManager;

@end
