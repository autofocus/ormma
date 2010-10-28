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
#pragma mark Properties

@synthesize ormmaView = m_ormmaView;
@synthesize locationBarView = m_locationBarView;
@synthesize contentAreaView = m_contentAreaView;
@synthesize tabBarView = m_tabBarView;




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
    [super viewDidLoad];
	
	// set the delegate
	self.ormmaView.ormmaDelegate = self;
}


- (void)viewDidUnload 
{
	self.ormmaView = nil;
	self.locationBarView = nil;
	self.contentAreaView = nil;
	self.tabBarView  = nil;
	
	[super viewDidUnload];
}



#pragma mark -
#pragma mark View Appear / Disappear

- (void)viewWillAppear:(BOOL)animated
{
	NSString *path = [[NSBundle mainBundle] pathForResource:@"Ad"
													 ofType:@"html"];
	NSLog( @"Ad Path is: %@", path );
	NSString *adFragment = [NSString stringWithContentsOfFile:path
											  encoding:NSUTF8StringEncoding
												 error:NULL];
	
	// refresh the ad
	NSURL *url = [NSURL URLWithString:@"http://localhost/~rhedin/ad.html"];
	[self.ormmaView loadHTMLCreative:adFragment
						 creativeURL:url];
}


- (void)viewDidAppear:(BOOL)animated
{
}


- (void)viewWillDisappear:(BOOL)animated
{
	// not showing anymore, animate ad out of the way
	[self animateAd:kAnimateOffScreen];
}


- (void)viewDidDisappear:(BOOL)animated
{
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

// Called if an ad fails to load
- (void)adFailedToLoad:(ORMMAView *)adView
{
	NSLog( @"ORMAView Delegate Call: adFailedToLoad: %@", adView.lastError );
}


// Called just before to an ad is displayed
- (void)adWillShow:(ORMMAView *)adView
		 isDefault:(BOOL)defaultAd
{
	NSLog( @"ORMAView Delegate Call: adWillShow" );
	
	// let's animate our ad on-screen
	if ( defaultAd )
	{
		[self animateAd:kAnimateOnScreen];
	}
}


// Called just after to an ad is displayed
- (void)adDidShow:(ORMMAView *)adView
		isDefault:(BOOL)defaultAd
{
	NSLog( @"ORMAView Delegate Call: adDidShow" );
}


// Called just before to an ad is Hidden
- (void)adWillHide:(ORMMAView *)adView
		 isDefault:(BOOL)defaultAd
{
	NSLog( @"ORMAView Delegate Call: adWillHide" );
	
	// let's animate our ad off-screen
	if ( defaultAd )
	{
		[self animateAd:kAnimateOffScreen];
	}
}


// Called just after to an ad is Hidden
- (void)adDidHide:(ORMMAView *)adView
		isDefault:(BOOL)defaultAd
{
	NSLog( @"ORMAView Delegate Call: adDidHide" );
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
- (void)appWillSuspendForAd:(ORMMAView *)adView
{
	NSLog( @"ORMAView Delegate Call: appWillSuspendForAd" );
}


// called when the ad is finished with it's heavy content (usually when the ad returns from full screen)
- (void)appWillResumeFromAd:(ORMMAView *)adView
{
	NSLog( @"ORMAView Delegate Call: appWillResumeFromAd" );
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
