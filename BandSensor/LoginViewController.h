//
//  LoginViewController.h
//  BandSensor
//
//  Created by Xueyang Li on 5/10/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HVACControllViewController.h"
#import "CollectDataViewController.h"
#import "KeychainItemWrapper.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"



@interface LoginViewController : UIViewController
extern BOOL isFromLogout;
extern BOOL inIbeaconRange;

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (weak, nonatomic) IBOutlet UITextView *SKTTxtOutput;




@end
