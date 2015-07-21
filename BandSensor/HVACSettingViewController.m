//
//  HVACSettingViewController.m
//  BandSensor
//
//  Created by Xueyang Li on 7/19/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "HVACSettingViewController.h"

@interface HVACSettingViewController () <UIAlertViewDelegate>
{
    NSUserDefaults *userDefaults;
}
@end

@implementation HVACSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    userDefaults = [NSUserDefaults standardUserDefaults];

    [self.reminderSwitch addTarget:self action:@selector(stateChanged:) forControlEvents:UIControlEventValueChanged];
    [self.autoNavigationSwitch addTarget:self action:@selector(stateChanged2:) forControlEvents:UIControlEventValueChanged];
    
    if([userDefaults boolForKey:@"pushNotificationIsOn"]) [self.reminderSwitch setOn:YES];
    else [self.reminderSwitch setOn:NO];
    
    BOOL willAutoNavigation = [userDefaults boolForKey:@"isHVAC"];
    
    if(willAutoNavigation) [self.autoNavigationSwitch setOn:YES];
    else    [self.autoNavigationSwitch setOn:NO];
}

- (void)stateChanged:(UISwitch *)switchState
{
    if ([switchState isOn])
    {
        [userDefaults setBool:true forKey:@"pushNotificationIsOn"];
    }
    else
    {
        [userDefaults setBool:false forKey:@"pushNotificationIsOn"];
    }
}

- (void)stateChanged2:(UISwitch *)switchState
{
    if ([switchState isOn])
    {
        [userDefaults setBool:true forKey:@"isHVAC"];
    }
    else
    {
        [userDefaults setBool:false forKey:@"isHVAC"];
    }
}

@end
