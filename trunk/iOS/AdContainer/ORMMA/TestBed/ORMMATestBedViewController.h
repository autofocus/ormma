/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <UIKit/UIKit.h>
#import "ORMMAView.h"



@interface ORMMATestBedViewController : UIViewController <ORMMAViewDelegate,
														  UITextFieldDelegate,
														  UIActionSheetDelegate>
{
@private
	ORMMAView *m_ormmaView;
	
	UIView *m_locationBarView;
	UIView *m_contentAreaView;
	UIView *m_tabBarView;
	
	UILabel *m_urlLabel;
	UITextField *m_urlField;
	UIButton *m_loadAdButton;
	
	NSString *m_phoneNumber;
	NSURL *m_url;
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

