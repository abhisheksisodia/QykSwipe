//
//  LoginViewController.m
//  LikedOrNope
//
//  Created by Behroz Saadat on 2015-06-12.
//  Copyright (c) 2015 modocache. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"
#import "TabBarController.h"
#import <Parse/Parse.h>

@interface LoginViewController ()

@end

@implementation LoginViewController
@synthesize loginView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self loadLoginView];
}

- (void)loadLoginView {
    loginView = [[InstagramLoginView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:loginView];
    
    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    // here i can set accessToken received on previous login
    appDelegate.instagram.accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"];
    appDelegate.instagram.sessionDelegate = self;
    if ([appDelegate.instagram isSessionValid]) {
        // Tear down login view
        [self tearDownLoginView];
        [self scoreAuthentication];
    }
}

- (void)tearDownLoginView {
    TabBarController *tabBarController = [[TabBarController alloc] init];
    [self.navigationController pushViewController:tabBarController animated:NO];
    [self removeFromParentViewController];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// IGSessionDelegate
#pragma mark - IGSessionDelegate

- (void)scoreAuthentication {
    PFQuery *query = [PFQuery queryWithClassName:@"UserScore"];
    [query whereKey:@"accessToken" equalTo:[[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"]];
    if ([query getFirstObject]) {
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                // The find succeeded.
                // Do something with the found objects
                int score = 0;
                NSString *objectID;
                for (PFObject *object in objects) {
                    score = [[object objectForKey:@"score"] intValue];
                    objectID = object.objectId;
                }
                [[NSUserDefaults standardUserDefaults] setObject:objectID forKey:@"objectID"];
                [[NSUserDefaults standardUserDefaults] setInteger:score forKey:@"savedScore"];
            } else {
                // Log details of the failure
                NSLog(@"Error: %@ %@", error, [error userInfo]);
            }
        }];
    }
    else {
        PFObject *userScore = [PFObject objectWithClassName:@"UserScore"];
        userScore[@"score"] = [NSNumber numberWithInteger:0];
        userScore[@"accessToken"] = [[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"];
        userScore[@"playerName"] = @"nil";
        userScore[@"cheatMode"] = @NO;
        [userScore saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSLog(@"Success");
            } else {
                NSLog(@"Error");
            }
        }];
    }

}

-(void)igDidLogin {
    // here i can store accessToken
    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [[NSUserDefaults standardUserDefaults] setObject:appDelegate.instagram.accessToken forKey:@"accessToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self scoreAuthentication];
    [self tearDownLoginView];
}

-(void)igDidNotLogin:(BOOL)cancelled {
    NSLog(@"Instagram did not login");
    NSString* message = nil;
    if (cancelled) {
        message = @"Access cancelled!";
    } else {
        message = @"Access denied!";
    }
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
}

-(void)igDidLogout {
    NSLog(@"Instagram did logout");
    // remove the accessToken
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"accessToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)igSessionInvalidated {
    NSLog(@"Instagram session was invalidated");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
