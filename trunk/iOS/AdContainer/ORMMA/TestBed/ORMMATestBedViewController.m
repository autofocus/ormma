//
//  ORMMATestBedViewController.m
//  ORMMATestBed
//
//  Created by Robert Hedin on 9/8/10.
//  Copyright The Weather Channel 2010. All rights reserved.
//

#import "ORMMATestBedViewController.h"




typedef enum OTBAdAnimationDirectionEnum
{
	kAnimateOffScreen = -1,
	kAnimateOnScreen = 1
} OTBAdAnimationDirection;



@interface ORMMATestBedViewController ()

- (void)animateAd:(OTBAdAnimationDirection)direction;

@end



@implementation ORMMATestBedViewController


#pragma mark -
#pragma mark Constants

NSString * const kWxDataObject = @"var wx = {}; \n\n" \
                                   "wx.config = {\n" \
                                   "  page: {\n" \
                                   "    pageId:  'testbed',\n" \
                                   "    pageURL: '',\n" \
                                   "    version: '1.0'\n" \
                                   "  },\n" \
                                   "\n" \
                                   "  user: {\n" \
                                   "    age:       '',\n" \
                                   "    gender:    '',\n" \
                                   "    asi:       '',\n" \
                                   "    view:      '',\n" \
                                   "    cobrand:   '',\n" \
                                   "    dec:       '',\n" \
                                   "    entry:     '',\n" \
                                   "    skin:      '',\n" \
                                   "    installed: ''\n" \
                                   "  },\n" \
                                   "\n" \
                                   "  ad: {\n" \
                                   "    mode:     '',\n" \
                                   "    site:     '',\n" \
                                   "    testsite: '',\n" \
                                   "    zone:     '',\n" \
                                   "    layout:   '',\n" \
                                   "    ord:      '',\n" \
                                   "    keywords: '',\n" \
                                   "    sequence: '',\n" \
                                   "    postions: {},\n" \
                                   "    wap:      ''\n" \
                                   "  },\n" \
                                   "\n" \
                                   "  loc: {\n" \
                                   "    gpr:      '',\n" \
                                   "    country:  'US',\n" \
                                   "    state:    'GA',\n" \
                                   "    dma:      '524',\n" \
                                   "    zip:      '30339',\n" \
                                   "    claritas: '8',\n" \
                                   "    locId:    '30339',\n" \
                                   "    locType:  '4',\n" \
                                   "    city:     ''\n" \
                                   "  },\n" \
                                   "\n" \
                                   "  wx: {\n" \
                                   "    temp:             '32',\n" \
                                   "    tempR:            '',\n" \
                                   "    realTemp:         '',\n" \
                                   "    cond:             'sun',\n" \
                                   "    pollen:           ''\n" \
                                   "    wind:             '',\n" \
                                   "    windSpeed:        '13',\n" \
                                   "    uv:               '',\n" \
                                   "    uvIndex:          '3',\n" \
                                   "    hum:              '52',\n" \
                                   "    relativeHumidity: '',\n" \
                                   "    severe:           '',\n" \
                                   "    wxIcon:           '%7@'\n" \
                                   "  }\n" \
                                   "};";



#pragma mark -
#pragma mark Properties

@synthesize ormmaView = m_ormmaView;
@synthesize locationBarView = m_locationBarView;
@synthesize contentAreaView = m_contentAreaView;
@synthesize tabBarView = m_tabBarView;
@synthesize urlLabel = m_urlLabel;
@synthesize urlField = m_urlField;
@synthesize loadAdButton = m_loadAdButton;




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
	
	[super viewDidUnload];
	NSLog( @"View Did Unload" );
}



#pragma mark -
#pragma mark View Appear / Disappear

- (void)viewWillAppear:(BOOL)animated
{
	NSLog( @"View Will Appear" );
//	NSString *path = [[NSBundle mainBundle] pathForResource:@"ormma-test-ad-level-2"
//													 ofType:@"html"];
//	NSLog( @"Ad Path is: %@", path );
//	NSString *adFragment = [NSString stringWithContentsOfFile:path
//											  encoding:NSUTF8StringEncoding
//												 error:NULL];
//	
//	// refresh the ad
//	NSURL *url = [NSURL URLWithString:@"http://localhost/~rhedin/ad.html"];
//	[self.ormmaView loadHTMLCreative:adFragment
//						 creativeURL:url];
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


- (NSString *)javascriptForInjection
{
	return kWxDataObject;
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
