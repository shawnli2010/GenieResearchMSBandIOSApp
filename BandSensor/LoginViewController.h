//
//  LoginViewController.h
//  BandSensor
//
//  Created by Xueyang Li on 5/10/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SkinTemperatureViewController.h"

@interface LoginViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end
