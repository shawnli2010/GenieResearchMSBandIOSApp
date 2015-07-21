//
//  CollectDataSettingViewController.m
//  BandSensor
//
//  Created by Xueyang Li on 7/8/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "CollectDataSettingViewController.h"

@interface CollectDataSettingViewController ()
{
    NSUserDefaults *userDefaults;
}
@end

@implementation CollectDataSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self.reminderSwitch addTarget:self action:@selector(stateChanged:) forControlEvents:UIControlEventValueChanged];
    
    userDefaults = [NSUserDefaults standardUserDefaults];
    
    if([userDefaults boolForKey:@"pushNotificationIsOn"]) [self.reminderSwitch setOn:YES];
    else    [self.reminderSwitch setOn:NO];
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



@end
