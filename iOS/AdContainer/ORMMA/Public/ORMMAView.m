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
#import "ORMMAWebBrowserViewController.h"
#import "UIDevice-ORMMA.h"
#import <EventKit/EventKit.h>



@interface ORMMAView () <UIWebViewDelegate,
						 ORMMAJavascriptBridgeDelegate,
						 ORMMALocalServerDelegate>

@property( nonatomic, retain, readwrite ) NSError *lastError;
@property( nonatomic, assign, readwrite ) ORMMAViewState currentState;
@property( nonatomic, retain ) ORMMAWebBrowserViewController *webBrowser;


- (void)commonInitialization;

- (void)loadDefaultHTMLStub;
- (NSString *)processHTMLStubUsingFragment:(NSString *)fragment;

- (NSInteger)angleFromOrientation:(UIDeviceOrientation)orientation;

+ (void)copyFile:(NSString *)file
		  ofType:(NSString *)type
	  fromBundle:(NSBundle *)bundle
		  toPath:(NSString *)path;

- (void)closeButtonPressed:(id)sender;
- (void)blockingViewTouched:(id)sender;

- (void)logFrame:(CGRect)frame
			text:(NSString *)text;

//- (NSString *)usingWebView:(UIWebView *)webView
//		 executeJavascript:(NSString *)javascript, ...;

- (NSString *)usingWebView:(UIWebView *)webView
		 executeJavascript:(NSString *)javascript
			   withVarArgs:(va_list)varargs;


- (void)injectJavaScriptIntoWebView:(UIWebView *)webView;
- (void)injectORMMAJavaScriptIntoWebView:(UIWebView *)webView;
- (void)injectORMMAStateIntoWebView:(UIWebView *)webView;
- (void)injectJavaScriptFile:(NSString *)fileName
				 intoWebView:(UIWebView *)webView;

- (void)fireAdWillShow;
- (void)fireAdDidShow;
- (void)fireAdWillHide;
- (void)fireAdDidHide;
- (void)fireAdWillClose;
- (void)fireAdDidClose;
- (void)fireAdWillResizeToSize:(CGSize)size;
- (void)fireAdDidResizeToSize:(CGSize)size;
- (void)fireAdWillExpandToFrame:(CGRect)frame;
- (void)fireAdDidExpandToFrame:(CGRect)frame;
- (void)fireAppShouldSuspend;
- (void)fireAppShouldResume;

@end




@implementation ORMMAView


#pragma mark -
#pragma mark Statics

static ORMMALocalServer *s_localServer;
static NSBundle *s_ormmaBundle;
static NSString *s_standardHTMLStub;
static NSString *s_standardJSStub;
//static NSString *s_publicAPI;
//static NSString *s_nativeAPI;


#pragma mark -
#pragma mark Constants

NSString * const kAdContentToken    = @"<!--AD-CONTENT-->";

NSString * const kAnimationKeyExpand = @"expand";
NSString * const kAnimationKeyCloseExpanded = @"closeExpanded";

NSString * const kInitialORMMAPropertiesFormat = @"{ state: '%@'," \
												   " network: '%@',"\
												   " size: { width: %f, height: %f },"\
												   " maxSize: { width: %f, height: %f },"\
												   " screenSize: { width: %f, height: %f },"\
												   " defaultPosition: { x: %f, y: %f, width: %f, height: %f },"\
												   " orientation: %i,"\
												   " supports: [ 'level-1', 'level-2', 'orientation', 'network', 'screen', 'shake', 'size', 'tilt'%@ ] }";


#pragma mark -
#pragma mark Properties

@synthesize ormmaDelegate = m_ormmaDelegate;
@synthesize htmlStub = m_htmlStub;
@synthesize creativeURL = m_creativeURL;
@synthesize lastError = m_lastError;
@synthesize currentState = m_currentState;
@synthesize maxSize = m_maxSize;
@synthesize webBrowser = m_webBrowser;

@synthesize allowLocationServices = m_allowLocationServices;


#pragma mark -
#pragma mark Initializers / Memory Management

+ (void)initialize
{
	// setup autorelease pool since this will be called outside of one
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// setup our cache
	s_localServer = [ORMMALocalServer sharedInstance];
	
	// access our bundle
	NSString *path = [[NSBundle mainBundle] pathForResource:@"ORMMA"
													 ofType:@"bundle"];
	if ( path == nil )
	{
		[NSException raise:@"Invalid Build Detected"
					format:@"Unable to find ORMMA.bundle. Make sure it is added to your resources!"];
	}
	s_ormmaBundle = [[NSBundle bundleWithPath:path] retain];
	
	// setup the default HTML Stub
	path = [s_ormmaBundle pathForResource:@"ORMMA_Standard_HTML_Stub"
								   ofType:@"html"];
	NSLog( @"HTML Stub Path is: %@", path );
	s_standardHTMLStub = [[NSString stringWithContentsOfFile:path
												   encoding:NSUTF8StringEncoding
													  error:NULL] retain];
	
	// setup the default HTML Stub
	path = [s_ormmaBundle pathForResource:@"ORMMA_Standard_JS_Stub"
								   ofType:@"html"];
	NSLog( @"JS Stub Path is: %@", path );
	s_standardJSStub = [[NSString stringWithContentsOfFile:path
												   encoding:NSUTF8StringEncoding
													  error:NULL] retain];
	
	// load the Public Javascript API
	[self copyFile:@"ormma"
			ofType:@"js"
		fromBundle:s_ormmaBundle
			toPath:s_localServer.cacheRoot];
	path = [s_ormmaBundle pathForResource:@"ormmaapi"
								   ofType:@"js"];
//	NSLog( @"Public API Path is: %@", path );
//	NSString *js = [NSString stringWithContentsOfFile:path
//											 encoding:NSUTF8StringEncoding
//												error:NULL];
//	s_publicAPI = [[js stringByAppendingString:@"; return 'OK';"] retain];
	
	// load the Native Javascript API
	[self copyFile:@"ormma-ios-bridge"
			ofType:@"js"
		fromBundle:s_ormmaBundle
			toPath:s_localServer.cacheRoot];
//	path = [s_ormmaBundle pathForResource:@"ormmaios"
//								   ofType:@"js"];
//	NSLog( @"Native API Path is: %@", path );
//	js = [NSString stringWithContentsOfFile:path
//								   encoding:NSUTF8StringEncoding
//									  error:NULL];
//	s_nativeAPI = [[js stringByAppendingString:@"; return 'OK';"] retain];
	
	// done with autorelease pool
	[pool drain];
}


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
	
	// the web view should be transparent
	m_webView.backgroundColor = [UIColor clearColor];
	
	// add the web view to the main view
	[self addSubview:m_webView];
	
	// make sure our view is also transparent
	self.backgroundColor = [UIColor clearColor];
	
	// let the OS know that we care about receiving various notifications
	m_currentDevice = [UIDevice currentDevice];
	[m_currentDevice beginGeneratingDeviceOrientationNotifications];
	m_currentDevice.proximityMonitoringEnabled = NO; // enable as-needed to conserve power
	
	// setup default maximum size based on our current frame size
	self.maxSize = self.frame.size;
	
	// set our initial state
	self.currentState = ORMMAViewStateDefault;
}


- (void)dealloc 
{
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
	[m_javascriptBridge restoreServicesToDefaultState], [m_javascriptBridge release], m_javascriptBridge = nil;
	[m_webBrowser release], m_webBrowser = nil;
    [super dealloc];
}




#pragma mark -
#pragma mark Dynamic Properties

- (UIWebView *)currentWebView
{
	if ( m_expandedView != nil )
	{
		return m_expandedView;
	}
	return m_webView;
}
		 


#pragma mark -
#pragma mark UIWebViewDelegate Methods

- (void)webView:(UIWebView *)webView 
didFailLoadWithError:(NSError *)error
{
	NSLog( @"Failed to load URL into Web View" );
	self.lastError = error;
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(failureLoadingAd:)] ) )
	{
		[self.ormmaDelegate failureLoadingAd:self];
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
		return NO;
	}
	NSString *urlString = [url absoluteString];
	if ( [@"about:blank" isEqualToString:urlString] )
	{
		// don't bother loading the empty page
		NSLog( @"IFrame Detected" );
		return NO;
	}
	
	// not handled by ORMMA, give the delegate a chance
	if ( self.ormmaDelegate != nil )
	{
		if ( [self.ormmaDelegate respondsToSelector:@selector(shouldLoadRequest:forAd:)] )
		{
			if ( ![self.ormmaDelegate shouldLoadRequest:request
												  forAd:self] )
				{
					// container handled the call
					NSLog( @"Container handled request for: %@", request );
					return NO;
				}
		}
	}
	
	// for all other cases, just let the web view handle it
	NSLog( @"Perform Normal process for URL." );
	return YES;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	// we've finished loading the URL
	[self injectJavaScriptIntoWebView:webView];
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
	[s_localServer cacheURL:url
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
	[s_localServer cacheHTML:html
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
	// select the correct stub
	NSString *stub = self.htmlStub;
	if ( stub == nil )
	{
		// determine if the fragment is JS or not
		NSString *trimmedFragment = [fragment stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		BOOL isJS = [trimmedFragment hasPrefix:@"document.write"];
				 
	    if ( isJS )
		{
			stub = s_standardJSStub;
		}
		else
		{
			stub = s_standardHTMLStub;
		}
	}
	
	// build the string
	NSString *output = [stub stringByReplacingOccurrencesOfString:kAdContentToken
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

//- (NSString *)executeJavaScript:(NSString *)javascript, ...
//{
//	va_list args;
//	va_start( args, javascript );
//	NSString *result = [self usingWebView:(m_expandedView != nil ) ? m_expandedView : m_webView
//						executeJavascript:javascript
//							  withVarArgs:args];
//	va_end( args );
//	return result;
//}


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
	// called when the ad needs to be made visible
	[self fireAdWillShow];
	
	// Nothing special to do, other than making sure the ad is visible
	self.hidden = NO;
	self.currentState = ORMMAViewStateDefault;
	
	// notify that we're done
	[self fireAdDidShow];
	
	// notify the ad view that the state has changed
	[self usingWebView:webView
	executeJavascript:@"window.ormmaview.fireChangeEvent( { state: 'default' } );"];
}


- (void)hideAd:(UIWebView *)webView
{
	// make sure we're not already hidden
	if ( self.currentState == ORMMAViewStateHidden )
	{
		[self usingWebView:webView
		 executeJavascript:@"window.ormmaview.fireErrorEvent( 'Cannot hide if we're already hidden.', 'hide' );" ]; 
		return;
	}	
	
	// called when the ad is ready to hide
	[self fireAdWillHide];
	
	// if the ad isn't in the default state, restore it first
	[self closeAd:webView];
	
	// now hide the ad
	self.hidden = YES;
	self.currentState = ORMMAViewStateHidden;

	// notify everyone that we're done
	[self fireAdDidHide];
	
	// notify the ad view that the state has changed
	[self usingWebView:webView
	 executeJavascript:@"window.ormmaview.fireChangeEvent( { state: 'hidden', size: { width: 0, height: 0 } } );"];
}


- (void)closeAd:(UIWebView *)webView
{
	// reality check
	NSAssert( ( webView != nil ), @"Web View passed to close is NULL" );
	
	// if we're in the default state already, there is nothing to do
	if ( self.currentState == ORMMAViewStateDefault )
	{
		// default ad, nothing to do
		return;
	}
	if ( self.currentState == ORMMAViewStateHidden )
	{
		// hidden ad, nothing to do
		return;
	}
	
	// Closing the ad refers to restoring the default state, whatever tasks
	// need to be taken to achieve this state
	
	// notify the app that we're starting
	[self fireAdWillClose];
	
	// closing the ad differs based on the current state
	if ( self.currentState == ORMMAViewStateExpanded )
	{
		// make the default view visible
		m_webView.hidden = NO;
		
		// reverse the growth
		[UIView beginAnimations:kAnimationKeyCloseExpanded
						context:nil];
		[UIView setAnimationDuration:0.5];
		[UIView setAnimationDelegate:self];
		m_expandedView.frame = m_initialFrame;;
		[UIView commitAnimations];

		// more happens after the animation finishes
    }
	else
	{
		// animations for resize are delegated to the application
		
		// notify the app that we are resizing
		[self fireAdWillResizeToSize:m_defaultFrame.size];
		
		// restore the size
		self.frame = m_defaultFrame;
		
		// notify the app that we are resizing
		[self fireAdDidResizeToSize:m_defaultFrame.size];
		
		// notify the app that we're done
		[self fireAdDidClose];
		
		// update our state
		self.currentState = ORMMAViewStateDefault;
		
		// notify the client
		[self usingWebView:webView
		 executeJavascript:@"window.ormmaview.fireChangeEvent( { state: 'default', size: { width: %f, height: %f } } );", m_defaultFrame.size.width, m_defaultFrame.size.height ];
	}
}


- (void)expandTo:(CGRect)endingFrame
		 withURL:(NSURL *)url
	inWebView:(UIWebView *)webView
   blockingColor:(UIColor *)blockingColor
blockingOpacity:(CGFloat)blockingOpacity
{
	// NOTE: We can only expand if we are in the default state
	if ( self.currentState != ORMMAViewStateDefault )
	{
		// Already Expanded
		[self usingWebView:webView
		 executeJavascript:@"window.ormmaview.fireErrorEvent( 'Can only expand from the default state.', 'expand' );" ]; 
		return;
	}
	
	// when put into the expanded state, we are showing a URI in a completely
	// new frame. This frame is attached directly to the key window at the
	// initial location specified, and will animate to a new location.
	
	// Notify the native app that we're preparing to expand
	[self fireAdWillExpandToFrame:endingFrame];
	
	// get the key window
	UIApplication *app = [UIApplication sharedApplication];
	UIWindow *keyWindow = [app keyWindow];
	
	// determine the initial (translated) frame
	m_initialFrame = [self convertRect:self.frame
								toView:keyWindow];
								
	// create the blocker view and add it to the window
	CGRect f = keyWindow.frame;
	UIApplication *a = [UIApplication sharedApplication];
	if ( !a.statusBarHidden )
	{
	   // status bar is visible
	   //f.origin.y += 20;
	   //f.size.height -= 20;
	   endingFrame.origin.y -= 20;
	}
	m_blockingView = [[UIView alloc] initWithFrame:f];
	m_blockingView.backgroundColor = blockingColor;
	m_blockingView.alpha = blockingOpacity;
	[keyWindow addSubview:m_blockingView];
	
	// create the new ad View
	m_expandedView = [[UIWebView alloc] initWithFrame:m_initialFrame];
	m_expandedView.clipsToBounds = YES;
	m_expandedView.delegate = self;
	//m_expandedView.scalesPageToFit = YES;
	if ( url == nil )
	{
	   // no url passed, reload default ad
	   url = m_webView.request.URL;
	}
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[m_expandedView loadRequest:request];
	[keyWindow addSubview:m_expandedView];
	
	// make the default web view hidden
	m_webView.hidden = YES; 
	
	// Animate the new web view to the correct size and position
	[UIView beginAnimations:kAnimationKeyExpand
					context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelegate:self];
	m_expandedView.frame = endingFrame;
	[UIView commitAnimations];
	
	// more happens after the animation completes
}


- (void)resizeToWidth:(CGFloat)width
			   height:(CGFloat)height
			inWebView:(UIWebView *)webView
{
	// resize must work within the view hierarchy; all the ORMMA ad view does
	// is modify the frame size while leaving the containing application to 
	// determine how this should be presented (animations).
	
	// note: we can only resize if we are in the default state and only to the
	//       limit specified by the maxSize value.
	
	// verify that we can resize
	if ( m_currentState != ORMMAViewStateDefault )
	{
		// we can't resize an expanded ad
		[self usingWebView:webView
		 executeJavascript:@"window.ormmaview.fireErrorEvent( 'Cannot resize an ad that is not in the default state.', 'resize' );" ]; 
		return;
	}
	
	// Make sure the resize honors our limits
	if ( ( height > self.maxSize.height ) ||
		 ( width > self.maxSize.width ) ) 
	{
		// we can't resize outside our limits
		[self usingWebView:webView
		 executeJavascript:@"window.ormmaview.fireErrorEvent( 'Cannot resize an ad larger than allowed.', 'resize' );" ]; 
		return;
	}
	
	// store the original frame
	m_defaultFrame = CGRectMake( self.frame.origin.x, 
								 self.frame.origin.y,
								 self.frame.size.width,
								 self.frame.size.height );
	
	// determine the final frame
	CGSize size = { width, height };
	
	// notify the application that we are starting to resize
	[self fireAdWillResizeToSize:size];
	
	// now update the size
	CGRect newFrame = CGRectMake( self.frame.origin.x, 
								  self.frame.origin.y, 
								  width,
								  height );
	self.frame = newFrame;
	
	// notify the application that we are done resizing
	[self fireAdDidResizeToSize:size];
	
	// update our state
	self.currentState = ORMMAViewStateResized;
	
	// send state changed event
	[self usingWebView:webView
	 executeJavascript:@"window.ormmaview.fireChangeEvent( { state: 'resized', size: { width: %f, height: %f } } );", width, height ];
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
		
		// if we're expanded, our view hierarchy is going to be strange
		// and the modal dialog may come up "under" the expanded web view
		// let's hide it while the modal is up
		m_expandedView.hidden = YES;
		m_blockingView.hidden = YES;
		
		// display the modal dialog
		vc.mailComposeDelegate = self;
		[self.ormmaDelegate.ormmaViewController presentModalViewController:vc
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
			
			// if we're expanded, our view hierarchy is going to be strange
			// and the modal dialog may come up "under" the expanded web view
			// let's hide it while the modal is up
			m_expandedView.hidden = YES;
			m_blockingView.hidden = YES;
		
			// now show the dialog
			[self.ormmaDelegate.ormmaViewController presentModalViewController:vc
																	   animated:YES];
		}
	}
}


- (void)placeCallTo:(NSString *)phoneNumber
{
   NSString *urlString = [NSString stringWithFormat:@"tel:%@", phoneNumber];
   NSURL *url = [NSURL URLWithString:urlString];
   NSLog( @"Executing: %@", url );
   [[UIApplication sharedApplication] openURL:url]; 
}


- (void)addEventToCalanderForDate:(NSDate *)date
						withTitle:(NSString *)title
						 withBody:(NSString *)body
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];

    EKEvent *event  = [EKEvent eventWithEventStore:eventStore];
    event.title = title;
	event.notes = body;

    event.startDate = date;
    event.endDate   = [[NSDate alloc] initWithTimeInterval:600 
												 sinceDate:event.startDate];

    NSError *err;
    [event setCalendar:[eventStore defaultCalendarForNewEvents]];
    [eventStore saveEvent:event 
					 span:EKSpanThisEvent 
					error:&err];       
}

- (CGRect)getAdFrameInWindowCoordinates
{
	CGRect frame = [self convertRect:self.frame toView:self.window];
	return frame;
}


- (void)openBrowser:(UIWebView *)webView
	  withUrlString:(NSString *)urlString
		 enableBack:(BOOL)back
	  enableForward:(BOOL)forward
	  enableRefresh:(BOOL)refresh;
{
	// if the browser is already open, change the URL
	NSLog( @"Open Browser" );
	NSURL *url = [NSURL URLWithString:urlString];
	if ( self.webBrowser != nil )
	{
		// Redirect
		NSLog( @"Redirecting browser to new URL: %@", urlString );
		self.webBrowser.URL = url;
		return;
	}
	
	// notify the app that it should stop work
	[self fireAppShouldSuspend];

	// display the web browser
	NSLog( @"Create Web Browser" );
	self.webBrowser = [[[ORMMAWebBrowserViewController alloc] initWithNibName:@"ORMMAWebBrowserViewController"
																	   bundle:s_ormmaBundle] autorelease];
	NSLog( @"Web Browser created: %@", self.webBrowser );
	self.webBrowser.browserDelegate = self;
	self.webBrowser.backButtonEnabled = back;
	self.webBrowser.forwardButtonEnabled = forward;
	self.webBrowser.refreshButtonEnabled = refresh;
	self.webBrowser.URL = url;
	[self.ormmaDelegate.ormmaViewController presentModalViewController:self.webBrowser
															   animated:YES];
}


#pragma mark -
#pragma mark Web Browser Control

- (void)doneWithBrowser
{
	[self.ormmaDelegate.ormmaViewController dismissModalViewControllerAnimated:YES];
	self.webBrowser = nil;

	// notify the app that it should start work
	[self fireAppShouldResume];
}



#pragma mark -
#pragma mark Animation View Delegate

- (void)animationDidStop:(NSString *)animationID 
				finished:(NSNumber *)finished 
				 context:(void *)context
{
	if ( [animationID isEqualToString:kAnimationKeyCloseExpanded] )
	{
		// finish the close expanded function
		
		// remove the blocker view from the view hierarcy
		[m_blockingView removeFromSuperview], m_blockingView = nil;
		
		// remove the expanded view
		[m_expandedView removeFromSuperview], m_expandedView = nil;
		
		// now notify the app that we're done
		[self fireAdDidClose];
		
		// update our internal state
		self.currentState = ORMMAViewStateDefault;
		
		// Final Step: send state changed event
		[self usingWebView:m_webView
		 executeJavascript:@"window.ormmaview.fireChangeEvent( { state: 'default', size: { width: %f, height: %f } } );", self.frame.size.width, self.frame.size.height ];
	}
	else
	{
		// finish the expand function

		// notify the app that we're done
		[self fireAdDidExpandToFrame:m_expandedView.frame];
		
		// update our internal state
		self.currentState = ORMMAViewStateExpanded;
	}
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
	// close the dialog
	[self.ormmaDelegate.ormmaViewController dismissModalViewControllerAnimated:YES];
	
	// redisplay the expanded view if necessary
	m_expandedView.hidden = NO;
	m_blockingView.hidden = NO;
}


- (void)messageComposeViewController:(MFMessageComposeViewController *)controller 
				 didFinishWithResult:(MessageComposeResult)result
{
	// close the dialog
	[self.ormmaDelegate.ormmaViewController dismissModalViewControllerAnimated:YES];
	
	// redisplay the expanded view if necessary
	m_expandedView.hidden = NO;
	m_blockingView.hidden = NO;
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
#pragma mark JavaScript Injection

- (void)injectJavaScriptIntoWebView:(UIWebView *)webView
{
	// check to see if we need to inject ORMMA or not
	NSLog( @"Testing Web View for ORMMA" );
	NSString *result = [self usingWebView:webView executeJavascript:@"typeof ORMMAReady"];
	if ( [result isEqualToString:@"function"] )
	{
		// the ad wants ORMMA, inject the ORMMA code
		NSLog( @"Ad requires ORMMA, inject code" );
		[self injectORMMAJavaScriptIntoWebView:webView];
		
		// now inject the current state
		[self injectORMMAStateIntoWebView:webView];
		
		// now allow the app to inject it's own javascript if needed
		if ( self.ormmaDelegate != nil )
		{
		   if ( [self.ormmaDelegate respondsToSelector:@selector(javascriptForInjection)] )
		   {
		       NSString *js = [self.ormmaDelegate javascriptForInjection];
			   [self usingWebView:webView executeJavascript:js];
		   }
		}
		
		// notify the creative that ORMMA is done
		m_applicationReady = YES;
		[self usingWebView:webView executeJavascript:@"ORMMAReady();"];
	}
	else
	{
		// Not an ORMMA ad, but let the app know the ad is visible
		[self fireAdWillShow];
		[self fireAdDidShow];
	}
}


- (void)injectORMMAJavaScriptIntoWebView:(UIWebView *)webView
{
	NSLog( @"Injecting ORMMA Javascript into creative." );
//	[self injectJavaScriptFile:@"/ormma-ios-bridge.js" intoWebView:webView];
//	[self injectJavaScriptFile:@"/ormma.js" intoWebView:webView];
}


- (void)injectJavaScriptFile:(NSString *)fileName
				 intoWebView:(UIWebView *)webView
{
	if ( [self usingWebView:webView 
		  executeJavascript:@"var ormmascr = document.createElement('script');ormmascr.src='%@';ormmascr.type='text/javascript';var ormmahd = document.getElementsByTagName('head')[0];ormmahd.appendChild(ormmascr);return 'OK';", fileName] == nil )
	{
		NSLog( @"Error injecting Javascript!" );
	}
}

- (void)injectORMMAStateIntoWebView:(UIWebView *)webView
{
	NSLog( @"Injecting ORMMA State into creative." );
	
	// setup the default state
	BOOL expanded = ( m_expandedView != nil );
	self.currentState = ORMMAViewStateDefault;
	if ( expanded )
	{
		self.currentState = ORMMAViewStateExpanded;
	}
	else
	{
		[self fireAdWillShow];
	}
	
	// add the various features the device supports
	NSMutableString *features = [NSMutableString stringWithCapacity:100];
	if ( [MFMailComposeViewController canSendMail] )
	{
		[features appendString:@", 'email'"]; 
	}
	if ( NSClassFromString( @"MFMessageComposeViewController" ) != nil )
	{
		// SMS support does exist
		if ( [MFMessageComposeViewController canSendText] ) 
		{
			[features appendString:@", 'sms'"]; 
		}
	}
	
	// allow LBS if app allows it
	if ( self.allowLocationServices )
	{
		[features appendString:@", 'email'"]; 
	}
	
	NSInteger platformType = [m_currentDevice platformType];
	switch ( platformType )
	{
		case UIDevice1GiPhone:
			[features appendString:@", 'phone'"]; 
			//[features appendString:@", 'camera'"]; 
			break;
		case UIDevice3GiPhone:
			[features appendString:@", 'phone'"]; 
			//[features appendString:@", 'camera'"]; 
			break;
		case UIDevice3GSiPhone:
			[features appendString:@", 'phone'"]; 
			//[features appendString:@", 'camera'"]; 
			break;
		case UIDevice4iPhone:
			[features appendString:@", 'phone'"]; 
			//[features appendString:@", 'camera'"]; 
			[features appendString:@", 'heading'"]; 
			[features appendString:@", 'rotation'"]; 
			break;
		case UIDevice1GiPad:
			[features appendString:@", 'heading'"]; 
			[features appendString:@", 'rotation'"]; 
			break;
		case UIDevice4GiPod:
			//[features appendString:@", 'camera'"]; 
			[features appendString:@", 'rotation'"]; 
			break;
		default:
			break;
	}
	
	// see if calendar support is available
	Class eventStore = NSClassFromString( @"EKEventStore" );
	if ( eventStore != nil )
	{
		[features appendString:@", 'calendar'"]; 
	}
	
	// setup the ad size
	UIWebView *wv = ( expanded ) ? m_expandedView : m_webView;
	CGSize size = wv.frame.size;
	
	// setup orientation
	UIDeviceOrientation orientation = m_currentDevice.orientation;
	NSInteger angle = [self angleFromOrientation:orientation];
	
	// setup the screen size
	UIDevice *device = [UIDevice currentDevice];
	CGSize screenSize = [device screenSizeForOrientation:orientation];	
	
	// get the key window
	UIApplication *app = [UIApplication sharedApplication];
	UIWindow *keyWindow = [app keyWindow];
	
	// setup the default position information (translated into window coordinates)
	CGRect defaultPosition = [self convertRect:self.frame
										toView:keyWindow];	
	
	// determine our network connectivity
	NSString *network = m_javascriptBridge.networkStatus;
	
	// build the initial properties
	NSString *properties = [NSString stringWithFormat:kInitialORMMAPropertiesFormat, ( expanded ? @"expanded" : @"default" ),
																					 network,
																					 size.width, size.height,
																					 self.maxSize.width, self.maxSize.height,
																					 screenSize.width, screenSize.height,
																					 defaultPosition.origin.x, defaultPosition.origin.y, defaultPosition.size.width, defaultPosition.size.height,
																					 angle,
																					 features];
	[self usingWebView:webView 
	 executeJavascript:@"window.ormmaview.fireChangeEvent( %@ );", properties];

	// make sure things are visible
	if ( !expanded )
	{
		[self fireAdDidShow];
	}
}


#pragma mark -
#pragma mark Delegate Helpers

- (void)fireAdWillShow
{
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(adWillShow:)] ) )
	{
		[self.ormmaDelegate adWillShow:self];
	}
}


- (void)fireAdDidShow
{
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(adDidShow:)] ) )
	{
		[self.ormmaDelegate adDidShow:self];
	}
}


- (void)fireAdWillHide
{
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(adWillHide:)] ) )
	{
		[self.ormmaDelegate adWillHide:self];
	}
}


- (void)fireAdDidHide
{
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(adDidHide:)] ) )
	{
		[self.ormmaDelegate adDidHide:self];
	}
}


- (void)fireAdWillClose
{
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(adWillClose:)] ) )
	{
		[self.ormmaDelegate adWillClose:self];
	}
}


- (void)fireAdDidClose
{
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(adDidClose:)] ) )
	{
		[self.ormmaDelegate adDidClose:self];
	}
}


- (void)fireAdWillResizeToSize:(CGSize)size
{
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(willResizeAd:toSize:)] ) )
	{
		[self.ormmaDelegate willResizeAd:self
								  toSize:size];
	}
}


- (void)fireAdDidResizeToSize:(CGSize)size
{
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(didResizeAd:toSize:)] ) )
	{
		[self.ormmaDelegate didResizeAd:self
								  toSize:size];
	}
}


- (void)fireAdWillExpandToFrame:(CGRect)frame
{
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(willExpandAd:toFrame:)] ) )
	{
		[self.ormmaDelegate willExpandAd:self
								 toFrame:frame];
	}
}


- (void)fireAdDidExpandToFrame:(CGRect)frame
{
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(didExpandAd:toFrame:)] ) )
	{
		[self.ormmaDelegate didExpandAd:self
								toFrame:frame];
	}
}


- (void)fireAppShouldSuspend
{
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(appShouldSuspendForAd:)] ) )
	{
		[self.ormmaDelegate appShouldSuspendForAd:self];
	}
}


- (void)fireAppShouldResume
{
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(appShouldResumeFromAd:)] ) )
	{
		[self.ormmaDelegate appShouldResumeFromAd:self];
	}
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


+ (void)copyFile:(NSString *)file
		  ofType:(NSString *)type
	  fromBundle:(NSBundle *)bundle
		  toPath:(NSString *)path
{
	NSString *sourcePath = [bundle pathForResource:file
											ofType:type];
	NSAssert( ( sourcePath != nil ), @"Source for file copy does not exist (%@)", file );
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
