    //
//  ORMMAWebBrowserViewController.m
//  ORMMA
//
//  Created by Robert Hedin on 11/4/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import "ORMMAWebBrowserViewController.h"



@interface ORMMAWebBrowserViewController ()

- (void)updateButton:(UIButton *)button
	  withImageNamed:(NSString *)imageName;

- (UIImage *)imageForName:(NSString *)name;


@end




@implementation ORMMAWebBrowserViewController

#pragma mark -
#pragma mark Constants



#pragma mark -
#pragma mark Statics

static NSString *s_scale = nil;


#pragma mark -
#pragma mark Properties

@synthesize webView = m_webView;
@synthesize browserNavigationBar = m_browserNavigationBar;
@synthesize backButton = m_backButton;
@synthesize forwardButton = m_forwardButton;
@synthesize refreshButton = m_refreshButton;
@synthesize pageLoadingIndicator = m_pageLoadingIndicator;
@synthesize closeButton = m_closeButton;
@synthesize browserDelegate = m_browserDelegate;
@dynamic URL;
@dynamic backButtonEnabled;
@dynamic forwardButtonEnabled;
@dynamic refreshButtonEnabled;
@dynamic closeButtonEnabled;



#pragma mark -
#pragma mark Initializers / Memory Management

+ (void)initialize
{
	// determine the scale factor
	if ([self respondsToSelector:@selector(contentScaleFactor)])
	{
		if ( [[UIScreen mainScreen] scale] == 2.0 )
		{
			// retina display, use larger images
			s_scale = @"@2x";
		}
		
	}
}


- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil 
{
    if ( ( self = [super initWithNibName:nibNameOrNil 
                                  bundle:nibBundleOrNil] ) ) 
    {
        // Get a handle to our bundle
		NSString *path = [[NSBundle mainBundle] pathForResource:@"ORMMA"
														 ofType:@"bundle"];
		if ( path == nil )
		{
			[NSException raise:@"Invalid Build Detected"
						format:@"Unable to find ORMMA.bundle. Make sure it is added to your resources!"];
		}
		m_ormmaBundle = [[NSBundle bundleWithPath:path] retain];
    }
    return self;
}


- (void)dealloc 
{
	[m_ormmaBundle release], m_ormmaBundle = nil;
	[m_webView release], m_webView = nil;
	[m_browserNavigationBar release], m_browserNavigationBar = nil;
	[m_backButton release], m_backButton = nil;
	[m_forwardButton release], m_forwardButton = nil;
	[m_refreshButton release], m_refreshButton = nil;
	[m_pageLoadingIndicator release], m_pageLoadingIndicator = nil;
	[m_closeButton release], m_closeButton = nil;
	m_browserDelegate = nil;
    [super dealloc];
}


- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark -
#pragma mark Load / Unload

- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	// update the button images
	NSLog( @"Update Button Images" );
	[self updateButton:self.backButton
		withImageNamed:@"back"];
	[self updateButton:self.forwardButton
		withImageNamed:@"forward"];
	[self updateButton:self.refreshButton
		withImageNamed:@"refresh"];
	[self updateButton:self.closeButton
		withImageNamed:@"close"];
}


- (void)viewDidUnload 
{
    [super viewDidUnload];
	
	self.webView = nil;
	self.browserNavigationBar = nil;
	self.backButton = nil;
	self.forwardButton = nil;
	self.refreshButton = nil;
	self.pageLoadingIndicator = nil;
	self.closeButton = nil;

}



#pragma mark -
#pragma mark View Appear / Disappear

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:m_url];
	[self.webView loadRequest:request];

}



#pragma mark -
#pragma mark Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Overriden to allow any orientation.
    return YES;
}



#pragma mark -
#pragma mark Dynamic Properties

- (NSURL *)URL
{
	return self.webView.request.URL;
}


- (void)setURL:(NSURL *)url
{
	NSLog( @"Loading URL: %@", url );
	if ( m_url != nil )
	{
		[m_url release], m_url = nil;
	}
	m_url = url;
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[self.webView loadRequest:request];
}


- (BOOL)backButtonEnabled
{
	return self.backButton.hidden;
}


- (void)setBackButtonEnabled:(BOOL)enabled
{
	self.backButton.hidden = enabled;
	if ( !enabled )
	{
		// back is not available, so forward cannot be either
		self.forwardButton.hidden = YES;
	}
}


- (BOOL)forwardButtonEnabled
{
	return self.forwardButton.hidden;
}


- (void)setForwardButtonEnabled:(BOOL)enabled
{
	self.forwardButton.hidden = !enabled;
	if ( enabled ) 
	{
		// the forward button is available so the back button must be as well
		self.backButton.hidden = NO;
	}
}


- (BOOL)refreshButtonEnabled
{
	return self.refreshButton.hidden;
}


- (void)setRefreshButtonEnabled:(BOOL)enabled
{
	self.refreshButton.hidden = enabled;
}


- (BOOL)closeButtonEnabled
{
	return self.closeButton.hidden;
}


- (void)setCloseButtonEnabled:(BOOL)enabled
{
	self.closeButton.hidden = enabled;
}


#pragma mark -
#pragma mark Button Actions

- (IBAction)backButtonPressed:(id)sender
{
	NSLog( @"Back Button Pressed." );
	[self.webView goBack];
}


- (IBAction)forwardButtonPressed:(id)sender
{
	NSLog( @"Forward Button Pressed." );
	[self.webView goForward];
}


- (IBAction)refreshButtonPressed:(id)sender
{
	NSLog( @"Refresh Button Pressed." );
	[self.webView reload];
}


- (IBAction)closeButtonPressed:(id)sender
{
	NSLog( @"Close Button Pressed." );
	if ( self.browserDelegate == nil )
	{
		// not assigned a delegate, just dismiss the view controller
		// (assumes that we're a modal dialog)
		NSLog( @"Auto Dismiss of Modal Browser" );
		[self.parentViewController dismissModalViewControllerAnimated:YES];
	}
	else
	{
		NSLog( @"Use Delegate to Dismiss Browser" );
		[self.browserDelegate doneWithBrowser];
	}
}



#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webView:(UIWebView *)webView 
didFailLoadWithError:(NSError *)error
{
	NSLog( @"Error loading: %@, %@", webView.request.URL, error );
}


- (BOOL)webView:(UIWebView *)webView 
shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType
{
	// allow everything
	NSLog( @"Allow URL: %@", request.URL );
	return YES;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	// we've finished loading the page
	NSLog( @"Web Page Finished Loading" );
	[self.pageLoadingIndicator stopAnimating];
	
	// enable the back/forward buttons as needed
	self.backButton.enabled = self.webView.canGoBack;
	self.forwardButton.enabled = self.webView.canGoForward;
}


- (void)webViewDidStartLoad:(UIWebView *)webView
{
	// let the user know we're doing something
	NSLog( @"Web Page Started Loading" );
	[self.pageLoadingIndicator startAnimating];
}


#pragma mark -
#pragma mark Utilities

- (void)updateButton:(UIButton *)button
	  withImageNamed:(NSString *)imageName
{
	UIImage *image = [self imageForName:imageName];
	[button setImage:image
			forState:UIControlStateNormal];
}


- (UIImage *)imageForName:(NSString *)name
{
	NSString *imageName;
	if ( s_scale == nil )
	{
		imageName = name;
	}
	else
	{
		imageName = [name stringByAppendingString:s_scale];
	}
	NSString *imagePath = [m_ormmaBundle pathForResource:imageName
												  ofType:@"png"];
	UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
	return image;
}

@end
