//
//  LoginViewController.m
//  BandSensor
//
//  Created by Xueyang Li on 5/10/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view
    
    [self.passwordTextField setSecureTextEntry:YES];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    // prevent the touch event to the table view being eaten by the tap
    [tap setCancelsTouchesInView:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonPressed:(UIButton *)sender {
    if([self.usernameTextField.text isEqualToString:@""] || [self.passwordTextField.text isEqualToString:@""] )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"No input field should be blank"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }

    // TEMPORARILY CANNOT WORK BECAUSE GENIE.UCSD.EDU IS BROKEN
    // Cannot test this auto-login functionality because genie.ucsd.edu is down for now
    /************************************************************************/
    KeychainItemWrapper* keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"Keychain" accessGroup:nil];
    [keychain setObject:(__bridge id)(kSecAttrAccessibleWhenUnlocked) forKey:(__bridge id)(kSecAttrAccessible)];
    [keychain setObject:self.usernameTextField.text forKey:(__bridge id)(kSecAttrAccount)];
    [keychain setObject:self.passwordTextField.text forKey:(__bridge id)(kSecValueData)];
    /************************************************************************/
    
    [self performSegueWithIdentifier:@"loginSegue" sender:self];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - Navigation
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"loginSegue"])
    {
        SkinTemperatureViewController *controller = (SkinTemperatureViewController *)segue.destinationViewController;
        controller.username = self.usernameTextField.text;
        controller.password = self.passwordTextField.text;
    }
    
}


@end
