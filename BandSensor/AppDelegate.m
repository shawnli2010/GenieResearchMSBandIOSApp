/*---------------------------------------------------------------------------------------------------
 *
 * Copyright (c) Microsoft Corporation All rights reserved.
 *
 * MIT License:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 * associated documentation files (the  "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial
 * portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
 * NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * ------------------------------------------------------------------------------------------------*/

#import "AppDelegate.h"

// declare global variable for push notification recurrence minutes
BOOL isFromLogout;
BOOL inIbeaconRange;

NSMutableArray *roomArray;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
//    self.locationManager = [[CLLocationManager alloc] init];
//    self.locationManager.delegate = self;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    isFromLogout = false;
    inIbeaconRange = false;
    
//    self.RPKmanager = [RPKManager managerWithDelegate:self];
//    [self.RPKmanager start];
    
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)])
    {
        [[UIApplication sharedApplication] registerUserNotificationSettings:
         [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound|UIUserNotificationTypeBadge
                                           categories:nil]];
    }
    
    [userDefaults setObject:@"" forKey:@"current_room"];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark Helper method to get the current time string

- (NSString *)getCurrentTimeString
{
    NSDate *currentTime = [NSDate date];
    // Convert the time to local time zone
    NSTimeInterval timeZoneSeconds = [[NSTimeZone localTimeZone] secondsFromGMT];
    currentTime = [currentTime dateByAddingTimeInterval:timeZoneSeconds];
    NSString *currentTimeString = [NSString stringWithFormat:@"%@",currentTime];
    return currentTimeString;
}

#pragma mark Proximity Kit Delegate Methods

//- (void)proximityKit:(RPKManager *)manager didDetermineState:(RPKRegionState)state forRegion:(RPKRegion *)region
//{
//    UILocalNotification *notification = [[UILocalNotification alloc] init];
//    notification.soundName = UILocalNotificationDefaultSoundName;
//    
//    if (state == RPKRegionStateInside)
//    {
//        notification.alertBody = [NSString stringWithFormat:@"You are inside state"];
//    }
//    else if (state == RPKRegionStateOutside)
//    {
//        notification.alertBody = [NSString stringWithFormat:@"You are outside of state"];
//    }
//    else if (state == RPKRegionStateUnknown)
//    {
//        notification.alertBody = [NSString stringWithFormat:@"Unknown state"];
//    }
//    
//    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
//}

//-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{
//    
//    UILocalNotification *notification = [[UILocalNotification alloc] init];
//    notification.soundName = UILocalNotificationDefaultSoundName;
//    
//    if(state == CLRegionStateInside)
//    {
//        notification.alertBody = [NSString stringWithFormat:@"You are inside region %@", region.identifier];
//    }
//    else if(state == CLRegionStateOutside)
//    {
//        notification.alertBody = [NSString stringWithFormat:@"You are outside region %@", region.identifier];
//    }
//    else
//    {
//        return;
//    }
//    
//    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
//}


@end
