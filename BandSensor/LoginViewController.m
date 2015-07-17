//
//  LoginViewController.m
//  BandSensor
//
//  Created by Xueyang Li on 5/10/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "LoginViewController.h"
#import "ChooseExperimentViewController.h"

@interface LoginViewController ()
{
    KeychainItemWrapper *keychain;
    
    AFHTTPRequestOperationManager *AFManager;
}
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view
    
    /************************************************************************/
    keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"Credential" accessGroup:nil];
    [keychain setObject:@"MY_APP_CREDENTIALS" forKey:(__bridge id)kSecAttrService];


    // Check whether there are existing keychain, if it exists, then auto login
    if ([[keychain objectForKey:(__bridge id)kSecAttrAccount] length])
    {
        [self.usernameTextField  setText:[keychain objectForKey:(__bridge id)(kSecAttrAccount)]];
        [self.passwordTextField setText:[keychain objectForKey:(__bridge id)(kSecValueData)]];
    }
    /************************************************************************/
    
    self.hud = [[MBProgressHUD alloc] init];
    [self.view addSubview:self.hud];
    
    [self.passwordTextField setSecureTextEntry:YES];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    // prevent the touch event to the table view being eaten by the tap
    [tap setCancelsTouchesInView:NO];
}

- (void)viewDidAppear:(BOOL)animated
{

    if([self.usernameTextField.text length])
    {
        if(!isFromLogout)
        {
            [self setupAFManager];
            
            [self performSegueWithIdentifier:@"loginToChoose" sender:self];
            NSLog(@"in viewdidappear");
        }
        else
        {
            [self.usernameTextField setText:@""];
            [self.passwordTextField setText:@""];
        }
    }
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
    else
    {
    
        [self.hud show:YES];
    
        [self setupAFManager];
    
        /*************************** Use AFNetWorking Manager to authenticate username and password ***************************/
        // Send a useless request just for authentication
        [AFManager GET:@"https://genie.ucsd.edu/api/v1/users/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self.hud hide:YES];
        
            //    [keychain setObject:(__bridge id)(kSecAttrAccessibleWhenUnlocked) forKey:(__bridge id)(kSecAttrAccessible)];
            [keychain setObject:self.usernameTextField.text forKey:(__bridge id)(kSecAttrAccount)];
            [keychain setObject:self.passwordTextField.text forKey:(__bridge id)(kSecValueData)];
        
            [self performSegueWithIdentifier:@"loginToChoose" sender:self];
        
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self.hud hide:YES];
        
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Your username or password is incorrect"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }];
    }
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - AFManager setup helper method
-(void)setupAFManager{

    AFManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://genie.ucsd.edu"]];
    AFManager.requestSerializer = [AFJSONRequestSerializer serializer];
    [AFManager.requestSerializer setAuthorizationHeaderFieldWithUsername:self.usernameTextField.text password:self.passwordTextField.text];
}

#pragma mark - Prepare for segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"loginToChoose"]){
        
        UINavigationController *navController = [segue destinationViewController];
        ChooseExperimentViewController *controller = (ChooseExperimentViewController *)([[navController viewControllers] lastObject]);
        
        controller.username = self.usernameTextField.text;
        controller.password = self.passwordTextField.text;
        controller.AFManager = AFManager;
        
    }
}



@end
