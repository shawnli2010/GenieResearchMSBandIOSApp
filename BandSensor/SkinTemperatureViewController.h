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



@interface SkinTemperatureViewController : UIViewController <MSBClientManagerDelegate>


// Skin temperature output
@property (weak, nonatomic) IBOutlet UITextView *SKTTxtOutput;
@property (nonatomic, weak) MSBClient *client;

- (IBAction)startTemperature:(id)sender;
- (IBAction)stopTemperature:(id)sender;

@end
