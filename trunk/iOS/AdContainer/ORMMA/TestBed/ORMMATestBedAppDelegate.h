/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <UIKit/UIKit.h>

@class ORMMATestBedViewController;

@interface ORMMATestBedAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *m_window;
    ORMMATestBedViewController *m_viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ORMMATestBedViewController *viewController;

@end

