//
//  ORMMATestBedViewController.h
//  ORMMATestBed
//
//  Created by Robert Hedin on 9/8/10.
//  Copyright The Weather Channel 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ORMMAView.h"



@interface ORMMATestBedViewController : UIViewController <ORMMAViewDelegate,
														  UITextFieldDelegate>
{
@private
	ORMMAView *m_ormmaView;
	
	UIView *m_locationBarView;
	UIView *m_contentAreaView;
	UIView *m_tabBarView;
	
	UILabel *m_urlLabel;
	UITextField *m_urlField;
	UIButton *m_loadAdButton;
}
@property( nonatomic, retain ) IBOutlet ORMMAView *ormmaView;

@property( nonatomic, retain ) IBOutlet UIView *locationBarView;
@property( nonatomic, retain ) IBOutlet UIView *contentAreaView;
@property( nonatomic, retain ) IBOutlet UIView *tabBarView;

@property( nonatomic, retain ) IBOutlet UILabel *urlLabel;
@property( nonatomic, retain ) IBOutlet UITextField *urlField;
@property( nonatomic, retain ) IBOutlet UIButton *loadAdButton;


- (IBAction)loadAdButtonPressed:(id)sender; 


@end

