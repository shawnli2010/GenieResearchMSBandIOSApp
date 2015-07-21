//
//  ChooseExperimentViewController.h
//  BandSensor
//
//  Created by Xueyang Li on 7/15/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <MicrosoftBandKit_iOS/MicrosoftBandKit_iOS.h>
#import <ProximityKit/ProximityKit.h>

#import <UIKit/UIKit.h>
#import "KeychainItemWrapper.h"
#import "MBProgressHUD.h"
#import "AFNetworking.h"

@interface ChooseExperimentViewController : UIViewController <MSBClientManagerDelegate,RPKManagerDelegate>
extern BOOL isFromLogout;
extern BOOL inIbeaconRange;
extern NSMutableArray *roomArray;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hvacButtonHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *justCollectDataButtonHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *jcdTopSpace;

@property(nonatomic) NSString *username;
@property(nonatomic) NSString *password;

@property (nonatomic, weak) MSBClient *client;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) AFHTTPRequestOperationManager *AFManager;
@property (strong, nonatomic) RPKManager *RPKmanager;
@property (weak, nonatomic) IBOutlet UITextView *SKTTxtOutput;

@end
