//
//  SkinTemperatureViewController.h
//  
//
//  Created by Xueyang Li on 5/10/15.
//
//

#import <UIKit/UIKit.h>
#import <MicrosoftBandKit_iOS/MicrosoftBandKit_iOS.h>
#import "AFNetworking.h"
#import "MBProgressHUD.h"


@interface SkinTemperatureViewController : UIViewController <MSBClientManagerDelegate,UIPickerViewDataSource,UIPickerViewDelegate>


// Skin temperature output
@property (nonatomic, weak) MSBClient *client;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (weak, nonatomic) IBOutlet UITextView *SKTTxtOutput;



@property (weak, nonatomic) IBOutlet UIButton *inButton;
@property (weak, nonatomic) IBOutlet UIButton *outButton;
@property (weak, nonatomic) IBOutlet UITextField *chooseRoomTextField;

@property (weak, nonatomic) IBOutlet UILabel *inOutLabel;
@property (weak, nonatomic) IBOutlet UILabel *roomNumberLabel;

@end
