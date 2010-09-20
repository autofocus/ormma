//
//  ORMMATestBedAppDelegate.h
//  ORMMATestBed
//
//  Created by Robert Hedin on 9/8/10.
//  Copyright The Weather Channel 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ORMMATestBedViewController;

@interface ORMMATestBedAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *m_window;
    ORMMATestBedViewController *m_viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ORMMATestBedViewController *viewController;

@end

