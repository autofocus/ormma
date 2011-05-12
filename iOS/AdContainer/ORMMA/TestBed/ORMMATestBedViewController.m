/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "ORMMATestBedViewController.h"




typedef enum OTBAdAnimationDirectionEnum
{
	kAnimateOffScreen = -1,
	kAnimateOnScreen = 1
} OTBAdAnimationDirection;



@interface ORMMATestBedViewController ()

@property( nonatomic, copy ) NSString *phoneNumber;
@property( nonatomic, copy ) NSURL *url;

- (void)animateAd:(OTBAdAnimationDirection)direction;

@end



@implementation ORMMATestBedViewController


#pragma mark -
#pragma mark Constants



#pragma mark -
#pragma mark Properties

@synthesize ormmaView = m_ormmaView;
@synthesize locationBarView = m_locationBarView;
@synthesize contentAreaView = m_contentAreaView;
@synthesize tabBarView = m_tabBarView;
@synthesize urlLabel = m_urlLabel;
@synthesize urlField = m_urlField;
@synthesize loadAdButton = m_loadAdButton;

@synthesize phoneNumber = m_phoneNumber;
@synthesize url = m_url;




#pragma mark -
#pragma mark Initialization / Memory Management

- (id)initWithCoder:(NSCoder *)coder
{
    if ( ( self = [super initWithCoder:coder] ) ) 
	{
        // Custom initialization
    }
    return self;
}


- (id)initWithNibName:(NSString *)nibNameOrNil 
			   bundle:(NSBundle *)nibBundleOrNil 
{
    if ( ( self = [super initWithNibName:nibNameOrNil 
								  bundle:nibBundleOrNil] ) ) 
	{
        // Custom initialization
    }
    return self;
}


- (void)dealloc 
{
	[m_ormmaView release], m_ormmaView = nil;
	[m_locationBarView release], m_locationBarView = nil;
	[m_contentAreaView release], m_contentAreaView = nil;
	[m_tabBarView release], m_tabBarView  = nil;
	[m_urlLabel release], m_urlLabel = nil;
	[m_urlField release], m_urlField = nil;
	[m_loadAdButton release], m_loadAdButton = nil;
	[m_phoneNumber release], m_phoneNumber = nil;
	[m_url release], m_url = nil;
    [super dealloc];
}


- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}



#pragma mark -
#pragma mark View Load / Unload

- (void)viewDidLoad 
{
	NSLog( @"View Did Load" );
    [super viewDidLoad];
	
	// set the delegate
	self.ormmaView.ormmaDelegate = self;
	self.ormmaView.allowLocationServices = YES;
	CGSize maxSize = { 320, 250 };
	self.ormmaView.maxSize = maxSize;
    
    
	
	self.view.backgroundColor = [UIColor purpleColor];
	
	// set the last URL
	NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
	NSString *s = [d objectForKey:@"lastURL"];
	if ( d != nil )
	{
		self.urlField.text = s;
	}
}


- (void)viewDidUnload 
{
	self.ormmaView = nil;
	self.locationBarView = nil;
	self.contentAreaView = nil;
	self.tabBarView  = nil;
	self.urlLabel = nil;
	self.urlField = nil;
	self.loadAdButton = nil;
	self.phoneNumber = nil;
	self.url = nil;
	
	[super viewDidUnload];
	NSLog( @"View Did Unload" );
}



#pragma mark -
#pragma mark View Appear / Disappear

- (void)viewWillAppear:(BOOL)animated
{
	NSLog( @"View Will Appear" );
}


- (void)viewDidAppear:(BOOL)animated
{
	NSLog( @"View Did Appear" );
}


- (void)viewWillDisappear:(BOOL)animated
{
	// not showing anymore, animate ad out of the way
	[self animateAd:kAnimateOffScreen];
	NSLog( @"View Will Disappear" );
}


- (void)viewDidDisappear:(BOOL)animated
{
	NSLog( @"View Did Disappear" );
}



#pragma mark -
#pragma mark Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



#pragma mark -
#pragma mark ORMMA Delegate

- (UIViewController *)ormmaViewController
{
	return self;
}


// Called if an ad fails to load
- (void)adFailedToLoad:(ORMMAView *)adView
{
	NSLog( @"ORMAView Delegate Call: adFailedToLoad: %@", adView.lastError );
}


// Called just before to an ad is displayed
- (void)adWillShow:(ORMMAView *)adView
{
	NSLog( @"ORMAView Delegate Call: adWillShow" );
	
	// let's animate our ad on-screen
	CGRect r = self.ormmaView.frame;
	if ( r.origin.y < 0 )
	{
		[self animateAd:kAnimateOnScreen];
	}
}


// Called just after to an ad is displayed
- (void)adDidShow:(ORMMAView *)adView
{
	NSLog( @"ORMAView Delegate Call: adDidShow" );
}


// Called just before to an ad is Hidden
- (void)adWillHide:(ORMMAView *)adView
{
	NSLog( @"ORMAView Delegate Call: adWillHide" );
	
	// let's animate our ad off-screen
	CGRect r = self.ormmaView.frame;
	if ( r.origin.y >= 0 )
	{
		[self animateAd:kAnimateOffScreen];
	}
}


// Called just after to an ad is Hidden
- (void)adDidHide:(ORMMAView *)adView
{
	NSLog( @"ORMAView Delegate Call: adDidHide" );
}


// Called after the ad is resized in place to allow the parent application to
// animate things if desired.
- (void)willResizeAd:(ORMMAView *)adView
			  toSize:(CGSize)size
{
	NSLog( @"ORMAView Delegate Call: willResizeAd" );
	[UIView beginAnimations:@"Resizing"
					context:nil];
	[UIView setAnimationDuration:0.5];

	// we need to reposition the on screen elements
	CGRect lf = m_locationBarView.frame;
	CGRect cf = m_contentAreaView.frame;
	
	if ( size.height > 50 )
	{
		// we're expanding
		lf.origin.y += 200;
		cf.origin.y += 200;
		cf.size.height -= 200;
	}
	else
	{
		// we're closing
		lf.origin.y -= 200;
		cf.origin.y -= 200;
		cf.size.height += 200;
	}
	
	m_locationBarView.frame = lf;
	m_contentAreaView.frame = cf;
}


// Called after the ad is resized in place to allow the parent application to
// animate things if desired.
- (void)didResizeAd:(ORMMAView *)adView
			 toSize:(CGSize)size
{
	NSLog( @"ORMAView Delegate Call: didResizeAd" );

	[UIView commitAnimations];
}


// Called just before to an ad expanding
- (void)adWillExpand:(ORMMAView *)adView
{
	NSLog( @"ORMAView Delegate Call: adWillExpand" );
}



// Called just after to an ad expanding
- (void)adDidExpand:(ORMMAView *)adView
{
	NSLog( @"ORMAView Delegate Call: adDidExpand" );
}



// Called just before an ad closes
- (void)adWillClose:(ORMMAView *)adView
{
	NSLog( @"ORMAView Delegate Call: adWillClose" );
}



// Called just after an ad closes
- (void)adDidClose:(ORMMAView *)adView
{
	NSLog( @"ORMAView Delegate Call: adDidClose" );
}



// called when the ad will begin heavy content (usually when the ad goes full screen)
- (void)appShouldSuspendForAd:(ORMMAView *)adView
{
	NSLog( @"ORMAView Delegate Call: appWillSuspendForAd" );
}


// called when the ad is finished with it's heavy content (usually when the ad returns from full screen)
- (void)appShouldResumeFromAd:(ORMMAView *)adView
{
	NSLog( @"ORMAView Delegate Call: appWillResumeFromAd" );
}


- (void)placePhoneCall:(NSString *)number
{
	// confirm the user wants to make a phone call
	self.phoneNumber = number;
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ORMMA PHONE CALL"
													message:@"ORMMA Creative has requested to place a phone call. Continue?"
												   delegate:self
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"OK", nil]; 
	[alert show];
	[alert release];
}


- (void)showURLFullScreen:(NSURL *)url
			   sourceView:(UIView *)view
{
	self.url = url;
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Open URL in..."
													   delegate:self 
											  cancelButtonTitle:@"Cancel" 
										 destructiveButtonTitle:nil 
											  otherButtonTitles:@"Open in Safari", nil];
	[sheet showInView:view];
	[sheet release];
}


#pragma mark Alert View & Action Sheet Delegate

- (void)alertView:(UIAlertView *)alertView 
clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if ( buttonIndex != alertView.cancelButtonIndex )
	{
		// user decided to continue
		NSString *urlString = [NSString stringWithFormat:@"tel:%@", self.phoneNumber];
		NSURL *url = [NSURL URLWithString:urlString];
		NSLog( @"Executing: %@", url );
		[[UIApplication sharedApplication] openURL:url]; 
	}
}


- (void)actionSheet:(UIActionSheet *)actionSheet 
clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if ( buttonIndex != actionSheet.cancelButtonIndex )
	{
		// launch external browser
		[[UIApplication sharedApplication] openURL:self.url]; 
	}
}



#pragma mark -
#pragma mark Button Actions

- (IBAction)loadAdButtonPressed:(id)sender
{
	// reset for loading the URL
	self.loadAdButton.hidden = YES;
	self.urlField.hidden = NO;
	self.urlLabel.hidden = NO;
	
	// reset the ad
	[m_ormmaView restoreToDefaultState];
	
	// bring up the keyboard
	[self.urlField becomeFirstResponder];
}



#pragma mark -
#pragma mark Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	// make sure we have a good URL
	NSString *txt = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ( txt.length == 0 )
	{
		// nothing to do
		return NO;
	}
	
	// we have something, make sure we've got a protocol
	if ( ![txt hasPrefix:@"http://"] && ![txt hasPrefix:@"https://"] )
	{
		// no protocol, assume http
		txt = [@"http://" stringByAppendingString:txt];
	}
	
	// now make sure it's a valid URL
	NSURL *url = [NSURL URLWithString:txt];
	if ( url == nil )
	{
		// bad URL
		return NO;
	}
	
	// store the text for next time around
	NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
	[d setObject:txt
		  forKey:@"lastURL"];

	// load the creative
	[self.ormmaView loadCreative:url];
	
	// resign first responder
	[textField resignFirstResponder];
	
	// reset for next load
	self.loadAdButton.hidden = NO;
	self.urlField.hidden = YES;
	self.urlLabel.hidden = YES;

	// done
	return YES;
}



#pragma mark -
#pragma mark Helpers

// Called just before to an ad is displayed
- (void)animateAd:(OTBAdAnimationDirection)direction
{
	// let's animate our ad on-screen
	[UIView beginAnimations:@"animate-ad"
					context:nil];
	[UIView setAnimationDuration:0.5];
	
	// find out how much to change things by
	CGFloat delta = self.ormmaView.frame.size.height;
	
	// we want to animate the ad view on screen
	CGRect r = self.ormmaView.frame;
	r.origin.y += ( delta * direction );
	self.ormmaView.frame = r;
	
	// we need to move the location bar down
	r = self.locationBarView.frame;
	r.origin.y += ( delta * direction );
	self.locationBarView.frame = r;
	
	// we need to move the content area down and shrink it
	r = self.contentAreaView.frame;
	r.origin.y += ( delta * direction );
	r.size.height += ( ( delta * direction ) * -1 );
	self.contentAreaView.frame = r;
	
	[UIView commitAnimations];
}


@end
