//
//  CollectDataSettingViewController.h
//  BandSensor
//
//  Created by Xueyang Li on 7/8/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectDataSettingViewController : UIViewController 

extern BOOL pushNotificationIsOn;
extern BOOL pushNotificationAlreadyOn;

@property (weak, nonatomic) IBOutlet UISwitch *reminderSwitch;


@end
