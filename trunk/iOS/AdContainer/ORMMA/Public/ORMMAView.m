//
//  TWCRichAdView.m
//  RichMediaAds
//
//  Created by Robert Hedin on 9/7/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import "ORMMAView.h"
#import "ORMMAJavascriptBridge.h"
#import "UIDevice-Hardware.h"
#import "EventKit/EventKit.h"
#import "ORMMALocalServer.h"



@interface ORMMAView () <UIWebViewDelegate,
						 ORMMAJavascriptBridgeDelegate,
						 ORMMALocalServerDelegate>

@property( nonatomic, retain, readwrite ) NSError *lastError;
@property( nonatomic, assign, readwrite ) ORMMAViewState currentState;


- (void)commonInitialization;

- (void)loadDefaultHTMLStub;
- (NSString *)processHTMLStubUsingFragment:(NSString *)fragment;

- (NSInteger)angleFromOrientation:(UIDeviceOrientation)orientation;

- (void)copyFile:(NSString *)file
		  ofType:(NSString *)type
	  fromBundle:(NSBundle *)bundle
		  toPath:(NSString *)path;

- (void)closeButtonPressed:(id)sender;
- (void)blockingViewTouched:(id)sender;

- (void)logFrame:(CGRect)frame
			text:(NSString *)text;

- (NSString *)usingWebView:(UIWebView *)webView
		 executeJavascript:(NSString *)javascript, ...;

- (NSString *)usingWebView:(UIWebView *)webView
		 executeJavascript:(NSString *)javascript
			   withVarArgs:(va_list)varargs;
@end




@implementation ORMMAView


#pragma mark -
#pragma mark Constants

NSString * const kAdContentToken    = @"<!--AD-CONTENT-->";

NSString * const kAnimationKeyResize = @"resize";
NSString * const kAnimationKeyExpand = @"expand";
NSString * const kAnimationKeyCloseResized = @"closeResized";
NSString * const kAnimationKeyCloseExpanded = @"closeExpanded";

const CGFloat kCloseButtonHorizontalOffset = 5.0;
const CGFloat kCloseButtonVerticalOffset = 5.0;



#pragma mark -
#pragma mark Properties

@synthesize ormmaDelegate = m_ormmaDelegate;
@synthesize htmlStub = m_htmlStub;
@synthesize creativeURL = m_creativeURL;
@synthesize lastError = m_lastError;
@synthesize currentState = m_currentState;



#pragma mark -
#pragma mark Initializers / Memory Management

- (id)initWithCoder:(NSCoder *)coder
{
    if ( ( self = [super initWithCoder:coder] ) ) 
	{
		[self commonInitialization];
	}
	return self;
}


- (id)initWithFrame:(CGRect)frame 
{
    if ( ( self = [super initWithFrame:frame] ) ) 
    {
		[self commonInitialization];
    }
    return self;
}


- (void)commonInitialization
{
	// setup our cache
	m_localServer = [ORMMALocalServer sharedInstance];

	// create our bridge object
	m_javascriptBridge = [[ORMMAJavascriptBridge alloc] init];
	m_javascriptBridge.bridgeDelegate = self;
	
	// it's up to the client to set any resizing policy for this container
	
	// let's create a webview that will fill it's parent
	CGRect webViewFrame = CGRectMake( 0, 
									  0, 
									  self.frame.size.width, 
									  self.frame.size.height );
	m_webView = [[UIWebView alloc] initWithFrame:webViewFrame];
	
	// make sure the webview will expand/contract as needed
	m_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | 
								 UIViewAutoresizingFlexibleHeight;
	m_webView.clipsToBounds = YES;

	// register ourselves to recieve any delegate calls
	m_webView.delegate = self;
	
	// add the web view to the main view
	[self addSubview:m_webView];
	
	// start listening for notifications
	
	// let the OS know that we care about receiving various notifications
	m_currentDevice = [UIDevice currentDevice];
	[m_currentDevice beginGeneratingDeviceOrientationNotifications];
	m_currentDevice.proximityMonitoringEnabled = NO; // enable as-needed to conserve power

	// access our bundle
	NSString *path = [[NSBundle mainBundle] pathForResource:@"ORMMA"
													 ofType:@"bundle"];
	if ( path == nil )
	{
		[NSException raise:@"Invalid Build Detected"
					format:@"Unable to find ORMMA.bundle. Make sure it is added to your resources!"];
	}
	m_ormmaBundle = [[NSBundle bundleWithPath:path] retain];
		
	// setup the default HTML Stub
	path = [m_ormmaBundle pathForResource:@"ORMMA_Standard_HTML_Stub"
								   ofType:@"html"];
	NSLog( @"Stub Path is: %@", path );
	self.htmlStub = [NSString stringWithContentsOfFile:path
											  encoding:NSUTF8StringEncoding
												 error:NULL];
	
	// make sure the standard Javascript files are updated
	[self copyFile:@"ormmaapi"
			ofType:@"js"
		fromBundle:m_ormmaBundle
			toPath:m_localServer.cacheRoot];
	[self copyFile:@"ormmaios"
			ofType:@"js"
		fromBundle:m_ormmaBundle
			toPath:m_localServer.cacheRoot];
}


- (void)dealloc 
{
	// done with the cache
	m_localServer = nil;
	
	// we're done receiving device changes
	[m_currentDevice endGeneratingDeviceOrientationNotifications];

	// free up some memory
	[m_creativeURL release], m_creativeURL = nil;
	m_currentDevice = nil;
	[m_lastError release], m_lastError = nil;
	[m_webView release], m_webView = nil;
	[m_blockingView release], m_blockingView = nil;
	m_ormmaDelegate = nil;
	[m_htmlStub release], m_htmlStub = nil;
	[m_ormmaBundle release], m_ormmaBundle = nil;
	[m_javascriptBridge restoreServicesToDefaultState], [m_javascriptBridge release], m_javascriptBridge = nil;
    [super dealloc];
}

		 


#pragma mark -
#pragma mark UIWebViewDelegate Methods

- (void)webView:(UIWebView *)webView 
didFailLoadWithError:(NSError *)error
{
	NSLog( @"Failed to load URL into Web View" );
	self.lastError = error;
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(adFailedToLoad:)] ) )
	{
		[self.ormmaDelegate adFailedToLoad:self];
	}
}


- (BOOL)webView:(UIWebView *)webView 
shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL *url = [request URL];
	NSLog( @"Verify Web View should load URL: %@", url );
	if ( [request.URL isFileURL] )
	{
		// Direct access to the file system is disallowed
		return NO;
	}
	if ( [m_javascriptBridge processURL:url
							 forWebView:webView] )
	{
		// the bridge processed the url, nothing else to do
		NSLog( @"Javascript bridge processed URL." );
		return NO;
	}
	NSString *urlString = [url absoluteString];
	if ( [@"about:blank" isEqualToString:urlString] )
	{
		// don't bother loading the empty page
		NSLog( @"IFrame Detected" );
		return NO;
	}
	
	// for all other cases, just let the web view handle it
	NSLog( @"Perform Normal process for URL." );
	return YES;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	// we've finished loading the URL
	
	// check for the existence of the ORMMA objects
	// if they do not exist, then assume we're good to display
	// otherwise wait for the creative to notify us that its done.
	NSLog( @"Web View Finished Loading" );
	NSString *result = [self usingWebView:webView executeJavascript:@"typeof window.Ormma"];

	NSLog( @"Testing Web View for ORMMA: %@", result );
	if ( [result isEqualToString:@"object"] )
	{
		// we are ORMMA enabled
		// setup the screen size
		UIScreen *screen = [UIScreen mainScreen];
		CGSize screenSize = screen.bounds.size;	
		[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.setBaseScreenSize( %f, %f );", screenSize.width, screenSize.height];
		
		// setup orientation
		UIDeviceOrientation orientation = m_currentDevice.orientation;
		NSInteger angle = [self angleFromOrientation:orientation];
		[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.orientationChanged( %i );", angle];
		
		// add the various features the device supports, common to all iOS devices
		if ( [MFMailComposeViewController canSendMail] )
		{
			[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'email' );"];
		}
		if ( NSClassFromString( @"MFMessageComposeViewController" ) != nil )
		{
			// SMS support does exist
			if ( [MFMessageComposeViewController canSendText] ) 
			{
				[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'sms' );"];
			}
		}
		[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'location' );"];
		[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'network' );"];
		[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'orientation' );"];
		[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'shake' );"];
		[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'size' );"];
		[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'tilt' );"];
		
		// now add the features that are available on specific devices
		
		NSInteger platformType = [m_currentDevice platformType];
		switch ( platformType )
		{
			case UIDevice1GiPhone:
				[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'phone' );"];
				[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'camera' );"];
				break;
			case UIDevice3GiPhone:
				[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'phone' );"];
				[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'camera' );"];
				break;
			case UIDevice3GSiPhone:
				[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'phone' );"];
				[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'heading' );"];
				[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'camera' );"];
				break;
			case UIDevice4iPhone:
				[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'phone' );"];
				[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'rotation' );"];
				[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'camera' );"];
				break;
			case UIDevice1GiPad:
				[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'phone' );"];
				[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'rotation' );"];
				break;
			case UIDevice4GiPod:
				[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'rotation' );"];
				[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'camera' );"];
				break;
			default:
				break;
		}
		
		// see if calendar support is available
		Class eventStore = NSClassFromString( @"EKEventStore" );
		if ( eventStore != nil )
		{
			[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.addFeature( 'calendar' );"];
		}
		
		// let the ad know it can start work
		m_applicationReady = YES;
		[self usingWebView:webView executeJavascript:@"window.OrmmaBridge.applicationReady();"];
	}
	else
	{
		// just assume we're showing a non-rich ad
		if ( ( self.ormmaDelegate != nil ) && 
			( [self.ormmaDelegate respondsToSelector:@selector(adWillShow:isDefault:)] ) )
		{
			[self.ormmaDelegate adWillShow:self
								 isDefault:( webView == m_webView )];
		}
		if ( ( self.ormmaDelegate != nil ) && 
			( [self.ormmaDelegate respondsToSelector:@selector(adDidShow:isDefault:)] ) )
		{
			[self.ormmaDelegate adDidShow:self
								isDefault:( webView == m_webView )];
		}
	}
}


- (void)webViewDidStartLoad:(UIWebView *)webView
{
	NSLog( @"Web View Started Loading" );
}



#pragma mark -
#pragma mark Ad Loading

- (void)loadCreative:(NSURL *)url
{
	// reset our state
	m_applicationReady = NO;
	
	// ads loaded by URL are assumed to be complete as-is, just display it
	NSLog( @"Load Ad from URL: %@", url );
	self.creativeURL = url;
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[m_localServer cacheURL:url
			   withDelegate:self];
	[m_webView loadRequest:request];
}


- (void)loadHTMLCreative:(NSString *)htmlFragment
			 creativeURL:(NSURL *)url
{
	// reset our state
	m_applicationReady = NO;
	
	// ads loaded by HTML fragment are assumed to need a wrapper
	// so we use the specified HTML stub and inject what we need into it
	// and write everything to the filesystem in our cache.
	//NSLog( @"Load Ad fragment: %@", htmlFragment );	

	// get the final HTML and write the file to the cache
	NSString *html = [self processHTMLStubUsingFragment:htmlFragment];
	//NSLog( @"Full HTML is: %@", html );
	self.creativeURL = url;
	[m_localServer cacheHTML:html
					 baseURL:url
				withDelegate:self];
}



#pragma mark -
#pragma mark HTML Stub Control

- (void)loadDefaultHTMLStub
{
}


- (NSString *)processHTMLStubUsingFragment:(NSString *)fragment
{
	// build the string
	NSString *output = [self.htmlStub stringByReplacingOccurrencesOfString:kAdContentToken
																withString:fragment];
	return output;
}



#pragma mark -
#pragma mark External Ad Size Control

- (void)restoreToDefaultState
{
	if ( self.currentState != ORMMAViewStateDefault )
	{
		[self closeAd:m_webView];
	}
}



#pragma mark -
#pragma mark Javascript Bridge Delegate

- (void)applicationReadyNotificationRequestReceived
{
	NSLog( @"Application registered for Ready Notification" );
	if ( m_applicationReady )
	{
		NSLog( @"Application already ready, resending notification." );
		[self executeJavaScript:@"window.OrmmaBridge.applicationReady();"];
	}
}


- (NSString *)executeJavaScript:(NSString *)javascript, ...
{
	va_list args;
	va_start( args, javascript );
	NSString *result = [self usingWebView:m_webView
						executeJavascript:javascript
							  withVarArgs:args];
	va_end( args );
	return result;
}


- (NSString *)usingWebView:(UIWebView *)webView
		 executeJavascript:(NSString *)javascript, ...
{
	// handle variable argument list
	va_list args;
	va_start( args, javascript );
	NSString *result = [self usingWebView:webView
						executeJavascript:javascript
							  withVarArgs:args];
	va_end( args );
	return result;
}


- (NSString *)usingWebView:(UIWebView *)webView
		 executeJavascript:(NSString *)javascript
			   withVarArgs:(va_list)args
{
	NSString *js = [[[NSString alloc] initWithFormat:javascript arguments:args] autorelease];
	NSLog( @"Executing Javascript: %@", js );
	return [webView stringByEvaluatingJavaScriptFromString:js];
}


- (void)showAd:(UIWebView *)webView
{
	// called when the ad is ready to be displayed
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(adWillShow:isDefault:)] ) )
	{
		[self.ormmaDelegate adWillShow:self
							 isDefault:( webView == m_webView )];
	}
	
	// Nothing special to do
	
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(adDidShow:isDefault:)] ) )
	{
		[self.ormmaDelegate adDidShow:self
							isDefault:( webView == m_webView )];
	}
	
	// notify the ad view that the state has changed
	NSLog( @"STATE CHANGE TO default" );
	NSString *js = [NSString stringWithFormat:@"window.OrmmaBridge.stateChanged( 'default' );"];
	[self executeJavaScript:js];
}


- (void)hideAd:(UIWebView *)webView
{
	// called when the ad is ready to be displayed
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(adWillHide:isDefault:)] ) )
	{
		[self.ormmaDelegate adWillHide:self
							 isDefault:( webView == m_webView )];
	}
	
	// Nothing special to do
	
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(adDidHide:isDefault:)] ) )
	{
		[self.ormmaDelegate adDidHide:self
							isDefault:( webView == m_webView )];
	}
	
	// notify the ad view that the state has changed
	NSLog( @"STATE CHANGE TO hidden" );
	NSString *js = [NSString stringWithFormat:@"window.OrmmaBridge.stateChanged( 'hidden' );"];
	[self executeJavaScript:js];
}


- (void)closeAd:(UIWebView *)webView
{
	// reality check
	NSAssert( ( webView != nil ), @"Web View passed to close is NULL" );
	
	// if we're in the default state already, there is nothing to do
	if ( self.currentState == ORMMAViewStateDefault )
	{
		// default ad
		NSLog( @"Ignoring close of default state" );
		return;
	}
	
	// Closing the ad refers to restoring the default state, whatever tasks
	// need to be taken to achieve this state
	
	// Step 1: notify the app that we're starting
	if ( ( self.ormmaDelegate != nil ) && 
		 ( [self.ormmaDelegate respondsToSelector:@selector(adWillClose:)] ) )
	{
		[self.ormmaDelegate adWillClose:self];
	}
	
	// Step 2: closing the ad differs based on the current state
	if ( self.currentState == ORMMAViewStateExpanded )
	{
		// Step 2a: we remove the close button and reverse the growth
		[m_closeButton removeFromSuperview], m_closeButton = nil;
		[UIView beginAnimations:kAnimationKeyCloseExpanded
						context:nil];
		[UIView setAnimationDuration:0.5];
		[UIView setAnimationDelegate:self];
		m_expandedView.frame = m_initialFrame;;
		[UIView commitAnimations];
	}
	else
	{
		// Step 2b: the resized ad should animate back to the default size
		[UIView beginAnimations:kAnimationKeyCloseResized
						context:nil];
		[UIView setAnimationDuration:0.5];
		[UIView setAnimationDelegate:self];
		self.frame = m_defaultFrame;
		[UIView commitAnimations];
	}
	
	[self logFrame:m_defaultFrame
			  text:@"Frame Closed"];
	[self logFrame:self.superview.frame
			  text:@"Parent Frame"];

	// steps 3+ happens after the animation finishes
}


- (void)expandFrom:(CGRect)startingFrame
				to:(CGRect)endingFrame
		   withURL:(NSURL *)url
		 inWebView:(UIWebView *)webView
{
	// NOTE: We cannot resize if we're in full screen mode
	if ( self.currentState == ORMMAViewStateExpanded )
	{
		// Already Expanded
		return;
	}
	
	// when put into the expanded state, we are showing a URI in a completely
	// new frame. This frame is attached directly to the key window at the
	// initial location specified, and will animate to a new location.
	
	// Step 1: Notify the native app that we're preparing to resize
	if ( ( self.ormmaDelegate != nil ) && 
		 ( [self.ormmaDelegate respondsToSelector:@selector(adWillExpand:)] ) )
	{
		[self.ormmaDelegate adWillExpand:self];
	}
	
	// Step 2: store the initial frame
	m_initialFrame = CGRectMake( startingFrame.origin.x, 
								 startingFrame.origin.y,
								 startingFrame.size.width,
								 startingFrame.size.height );
	
	// Step 3: get the key window
	UIApplication *app = [UIApplication sharedApplication];
	UIWindow *keyWindow = [app keyWindow];
	
	// Step 4: create the new ad View
	m_expandedView = [[UIWebView alloc] initWithFrame:startingFrame];
	m_expandedView.clipsToBounds = YES;
	m_expandedView.delegate = self;
	m_expandedView.scalesPageToFit = YES;
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[m_expandedView loadRequest:request];
	[keyWindow addSubview:m_expandedView];
	
	// Step 5: Animate the new web view to the correct size and position
	[UIView beginAnimations:kAnimationKeyExpand
					context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelegate:self];
	m_expandedView.frame = endingFrame;
	[UIView commitAnimations];
	
	// Steps 6+ happens after the animation completes
}


- (void)resizeToWidth:(CGFloat)width
			   height:(CGFloat)height
			inWebView:(UIWebView *)webView
{
	// A resize action resizes the ad view in place without regard to the view 
	// hierarcy. The ad will remain anchored in place at its origin, but will
	// scale (up or down) to the width & height specified. Realistically, this
	// means that it is enirely possible for the ad to be clipped by it's parent
	// however this is as designed. If this is not desired, the user should use
	// the expand action instead.
	
	// Step 1: verify that we can resize
	if ( m_currentState == ORMMAViewStateExpanded )
	{
		// we can't resize an expanded ad
		return;
	}
	
	// Step 2: setup what we're resizing from
	if ( m_currentState == ORMMAViewStateDefault )
	{
		// Step 2a: currently in default state, so store the original frame
		m_defaultFrame = CGRectMake( self.frame.origin.x, 
									 self.frame.origin.y,
									 self.frame.size.width,
									 self.frame.size.height );
	}
	else
	{
		// Step 2b: resizing a resized ad, are we going back to default?
		if ( ( width == m_defaultFrame.size.width ) &&
			 ( height == m_defaultFrame.size.height ) )
		{
			// returning to default state
			[self closeAd:webView];
			return;
		}	
	}
	
	// Step 3: determine the final frame
	CGRect f = CGRectMake( self.frame.origin.x, 
						   self.frame.origin.x, 
						   width,
						   height );
	
	// Step 4: animate to the new size
	[UIView beginAnimations:kAnimationKeyResize
					context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelegate:self];
	self.frame = f;
	[UIView commitAnimations];

	[self logFrame:f 
			  text:@"Resize Frame"];
	
	// Steps 5+ occur when the animation completes
}


- (void)sendEMailTo:(NSString *)to
		withSubject:(NSString *)subject
		   withBody:(NSString *)body
			 isHTML:(BOOL)html
{
	// make sure that we can send email
	if ( [MFMailComposeViewController canSendMail] )
	{
		MFMailComposeViewController *vc = [[[MFMailComposeViewController alloc] init] autorelease];
		if ( to != nil )
		{
			NSArray *recipients = [NSArray arrayWithObject:to];
			[vc setToRecipients:recipients];
		}
		if ( subject != nil )
		{
			[vc setSubject:subject];
		}
		if ( body != nil )
		{
			[vc setMessageBody:body 
						isHTML:html];
		}
		vc.mailComposeDelegate = self;
		[self.ormmaDelegate.parentViewController presentModalViewController:vc
																   animated:YES];
	}
}


- (void)sendSMSTo:(NSString *)to
		 withBody:(NSString *)body
{
	if ( NSClassFromString( @"MFMessageComposeViewController" ) != nil )
	{
		// SMS support does exist
		if ( [MFMessageComposeViewController canSendText] ) 
		{
			// device can
			MFMessageComposeViewController *vc = [[[MFMessageComposeViewController alloc] init] autorelease];
			vc.messageComposeDelegate = self;
			if ( to != nil )
			{
				NSArray *recipients = [NSArray arrayWithObject:to];
				vc.recipients = recipients;
			}
			if ( body != nil )
			{
				vc.body = body;
			}
			[self.ormmaDelegate.parentViewController presentModalViewController:vc
																	   animated:YES];
		}
	}
}


- (CGRect)getAdFrameInWindowCoordinates
{
	CGRect frame = [self convertRect:self.frame toView:self.window];
	return frame;
}



#pragma mark -
#pragma mark Animation View Delegate

- (void)animationDidStop:(NSString *)animationID 
				finished:(NSNumber *)finished 
				 context:(void *)context
{
	NSString *newState = @"unknown";
	if ( [animationID isEqualToString:kAnimationKeyCloseExpanded] )
	{
		// finish the close expanded function
		
		// Step 7: remove the blocker view from the view hierarcy
		[m_blockingView removeFromSuperview], m_blockingView = nil;
		
		// Step 8: remove the expanded view
		[m_expandedView removeFromSuperview], m_expandedView = nil;
		
		// step 9: now notify the app that we're done
		if ( ( self.ormmaDelegate != nil ) && 
			 ( [self.ormmaDelegate respondsToSelector:@selector(adDidClose:)] ) )
		{
			[self.ormmaDelegate adDidClose:self];
		}
		
		// Step 10: setup state changed event
		newState = @"default";
		
		// Step 11: update our internal state
		self.currentState = ORMMAViewStateDefault;
	}
	else if ( [animationID isEqualToString:kAnimationKeyCloseResized] )
	{
		// finish the close resized function
		
		// step 5: now notify the app that we're done
		if ( ( self.ormmaDelegate != nil ) && 
			( [self.ormmaDelegate respondsToSelector:@selector(adDidClose:)] ) )
		{
			[self.ormmaDelegate adDidClose:self];
		}
		
		// Step 6: setup state changed event
		newState = @"default";
		
		// Step 7: update our internal state
		self.currentState = ORMMAViewStateDefault;
	}
	else
	{
		// finish the resize function

		// Step 6: notify the app that we're done
		if ( ( self.ormmaDelegate != nil ) && 
			 ( [self.ormmaDelegate respondsToSelector:@selector(adDidExpand:)] ) )
		{
			[self.ormmaDelegate adDidExpand:self];
		}
		
		// Step 9: setup state changed event
		newState = @"expanded";
		
		// Step 10: update our internal state
		if ( [animationID isEqualToString:kAnimationKeyResize] )
		{
			self.currentState = ORMMAViewStateResized;
		}
		else
		{
			self.currentState = ORMMAViewStateExpanded;
			
			// now that we've expanded, also add the force close button
			NSString *buttonImage = @"close";
			if ( [UIScreen instancesRespondToSelector:@selector(scale)] ) 
			{
				CGFloat scale = [[UIScreen mainScreen] scale];
				if ( scale > 1.0 ) 
				{
					buttonImage = @"close@2x";
				}
			}
			NSString *imagePath = [m_ormmaBundle pathForResource:buttonImage
														  ofType:@"png"];
			NSLog( @"Close Button Image: %@", imagePath );
			UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
			NSLog( @"Loaded Image: %@", image );
			m_closeButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
			[m_closeButton setBackgroundImage:image
									 forState:UIControlStateNormal];
			[m_closeButton addTarget:self
							  action:@selector(closeButtonPressed:)
					forControlEvents:UIControlEventTouchUpInside];
			CGFloat y = ( m_expandedView.frame.origin.y + kCloseButtonVerticalOffset );
			CGFloat x = ( m_expandedView.frame.origin.x + m_expandedView.frame.size.width - ( 28 + kCloseButtonHorizontalOffset ) );
			CGRect f = CGRectMake( x,
								   y,
								   28,
								   28 );
			[self logFrame:f text:@"Button Frame"];
			m_closeButton.frame = f;
			[m_expandedView.superview addSubview:m_closeButton];
		}
	}

	// Final Step: send state changed event
	NSLog( @"STATE CHANGE TO %@", newState );
	[self executeJavaScript:@"window.OrmmaBridge.stateChanged( '%@' );", newState];
	
	// Notify the ad of it's current size
	CGFloat w = self.frame.size.width;
	CGFloat h = self.frame.size.height;
	NSLog( @"AD RESIZED TO %f x %f", w, h );
	[self executeJavaScript:@"window.OrmmaBridge.sizeChanged( %f, %f );", w, h];
}



#pragma mark -
#pragma mark Cache Delegate

- (void)cacheFailed:(NSURL *)baseURL
		  withError:(NSError *)error
{
}


- (void)cachedCreative:(NSURL *)creativeURL
				 onURL:(NSURL *)url
				withId:(long)creativeId
{
	if ( [self.creativeURL isEqual:creativeURL] )
	{
		// now show the cached file
		m_creativeId = creativeId;
		NSURLRequest *request = [NSURLRequest requestWithURL:url];
		[m_webView loadRequest:request];
	}
}


- (void)cachedResource:(NSURL *)url
		   forCreative:(long)creativeId
{
	if ( creativeId == m_creativeId )
	{
		// TODO
	}
}


- (void)cachedResourceRetired:(NSURL *)url
				  forCreative:(long)creativeId
{
	// TODO
}


- (void)cachedResourceRemoved:(NSURL *)url
				  forCreative:(long)creativeId
{
	// TODO
}



#pragma mark -
#pragma mark Mail and SMS Composer Delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller 
		  didFinishWithResult:(MFMailComposeResult)result 
						error:(NSError*)error
{
	[self.ormmaDelegate.parentViewController dismissModalViewControllerAnimated:YES];
}


- (void)messageComposeViewController:(MFMessageComposeViewController *)controller 
				 didFinishWithResult:(MessageComposeResult)result
{
	[self.ormmaDelegate.parentViewController dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark General Actions

- (void)closeButtonPressed:(id)sender
{
	// the user wants to close the expanded window
	[self closeAd:m_expandedView];
}


- (void)blockingViewTouched:(id)sender
{
	// Restore the ad to it's default size
	[self closeAd:m_webView];
}


#pragma mark -
#pragma mark Utility Methods

- (NSInteger)angleFromOrientation:(UIDeviceOrientation)orientation
{
	NSInteger orientationAngle = -1;
	switch ( orientation )
	{
		case UIDeviceOrientationPortrait:
			orientationAngle = 0;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			orientationAngle = 180;
			break;
		case UIDeviceOrientationLandscapeLeft:
			orientationAngle = 270;
			break;
		case UIDeviceOrientationLandscapeRight:
			orientationAngle = 90;
			break;
		default:
			orientationAngle = -1;
			break;
	}
	return orientationAngle;
}


- (void)callSelectorOnDelegate:(SEL)selector
{
	if ( ( self.ormmaDelegate != nil ) && 
 		 ( [self.ormmaDelegate respondsToSelector:selector] ) )
	{
		[self.ormmaDelegate performSelector:selector 
								 withObject:self];
	}
}


- (void)copyFile:(NSString *)file
		  ofType:(NSString *)type
	  fromBundle:(NSBundle *)bundle
		  toPath:(NSString *)path
{
	NSString *sourcePath = [bundle pathForResource:file
											ofType:type];
	NSAssert( ( sourcePath != nil ), @"Source for file copy does not exist." );
	NSString *contents = [NSString stringWithContentsOfFile:sourcePath
												   encoding:NSUTF8StringEncoding
													  error:NULL];
	
	// make sure path exists
	
	NSString *finalPath = [NSString stringWithFormat:@"%@/%@.%@", path, 
																  file, 
																  type];
	NSLog( @"Final Path to JS: %@", finalPath );
	NSError *error;
	if ( ![contents writeToFile:finalPath
					 atomically:YES
					   encoding:NSUTF8StringEncoding
						  error:&error] )
	{
		NSLog( @"Unable to write file '%@', to '%@'. Error is: %@", sourcePath, finalPath, error );
	}
}




- (void)logFrame:(CGRect)f
			text:(NSString *)text
{
	NSLog( @"%@ :: ( %f, %f ) and ( %f x %f )", text,
												f.origin.x,
												f.origin.y,
												f.size.width,
												f.size.height );
}

@end