/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "ORMMATestBedAppDelegate.h"
#import "ORMMATestBedViewController.h"

@implementation ORMMATestBedAppDelegate

@synthesize window = m_window;
@synthesize viewController = m_viewController;



#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application 
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{    
    
    // Override point for customization after application launch.

    // Add the view controller's view to the window and display.
	self.window.backgroundColor = [UIColor greenColor];
    [self.window addSubview:self.viewController.view];
    [self.window makeKeyAndVisible];

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application 
{
}


- (void)applicationDidEnterBackground:(UIApplication *)application 
{
}


- (void)applicationWillEnterForeground:(UIApplication *)application 
{
}


- (void)applicationDidBecomeActive:(UIApplication *)application 
{
}


- (void)applicationWillTerminate:(UIApplication *)application 
{
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application 
{
}


- (void)dealloc 
{
    [m_viewController release], m_viewController = nil;
    [m_window release], m_window = nil;
    [super dealloc];
}


@end
