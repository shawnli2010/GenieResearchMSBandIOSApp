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
