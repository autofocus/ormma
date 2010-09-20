//
//  ORMMATestBedViewController.h
//  ORMMATestBed
//
//  Created by Robert Hedin on 9/8/10.
//  Copyright The Weather Channel 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ORMMAView.h"



@interface ORMMATestBedViewController : UIViewController <ORMMAViewDelegate>
{
@private
	ORMMAView *m_ormmaView;
	
	UIView *m_locationBarView;
	UIView *m_contentAreaView;
	UIView *m_tabBarView;
}
@property( nonatomic, retain ) IBOutlet ORMMAView *ormmaView;

@property( nonatomic, retain ) IBOutlet UIView *locationBarView;
@property( nonatomic, retain ) IBOutlet UIView *contentAreaView;
@property( nonatomic, retain ) IBOutlet UIView *tabBarView;


@end

