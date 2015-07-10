//
//  CollectDataSettingViewController.m
//  BandSensor
//
//  Created by Xueyang Li on 7/8/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "CollectDataSettingViewController.h"

@interface CollectDataSettingViewController ()

@end

@implementation CollectDataSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self.reminderSwitch addTarget:self action:@selector(stateChanged:) forControlEvents:UIControlEventValueChanged];
    
    if(pushNotificationIsOn) [self.reminderSwitch setOn:YES];
}

- (void)stateChanged:(UISwitch *)switchState
{
    if ([switchState isOn])
    {
        pushNotificationIsOn = true;
    }
    else
    {
        pushNotificationIsOn = false;
    }
}



@end
