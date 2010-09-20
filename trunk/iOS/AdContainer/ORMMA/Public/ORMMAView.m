//
//  TWCRichAdView.m
//  RichMediaAds
//
//  Created by Robert Hedin on 9/7/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import "ORMMAView.h"
#import "DeferredObjectSelector.h"
#import "ORMMAJavascriptBridge.h"
#import "UIDevice-Hardware.h"
#import "EventKit/EventKit.h"
#import "FileSystemCache.h"



@interface ORMMAView () <UIWebViewDelegate,
						 ORMMAJavascriptBridgeDelegate,
						 FileSystemCacheDelegate>

@property( nonatomic, retain ) UIView *originalParentView;
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

- (void)blockingViewTouched:(id)sender;

@end




@implementation ORMMAView


#pragma mark -
#pragma mark Constants

NSString * const kAdContentToken    = @"<!--AD-CONTENT-->";
NSString * const kCacheRootToken    = @"<!--CACHE-ROOT-->";



#pragma mark -
#pragma mark Properties

@synthesize originalParentView = m_originalParentView;
@synthesize ormmaDelegate = m_ormmaDelegate;
@synthesize htmlStub = m_htmlStub;
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
	m_cache = [FileSystemCache sharedInstance];
	
	// create our bridge object
	m_javascriptBridge = [[ORMMAJavascriptBridge alloc] init];
	m_javascriptBridge.bridgeDelegate = self;
	
	// it's up to the client to set any resizing policy for this container
	
	// store the original frame for later use if the ad should expand
	m_unexpandedFrame = self.frame;
	
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
	NSBundle *ormmaBundle = [NSBundle bundleWithPath:path];
		
	// setup the default HTML Stub
	path = [ormmaBundle pathForResource:@"ORMMA_Standard_HTML_Stub"
								 ofType:@"html"];
	NSLog( @"Stub Path is: %@", path );
	self.htmlStub = [NSString stringWithContentsOfFile:path
											  encoding:NSUTF8StringEncoding
												 error:NULL];
	
	// make sure the standard Javascript files are updated
	[self copyFile:@"ORMMA_Abstraction_Layer_iOS"
			ofType:@"js"
		fromBundle:ormmaBundle
			toPath:m_cache.cacheRoot];
	[self copyFile:@"ORMMA_Javascript_API"
			ofType:@"js"
		fromBundle:ormmaBundle
			toPath:m_cache.cacheRoot];
}


- (void)dealloc 
{
	// done with the cache
	m_cache = nil;
	
	// we're done receiving device changes
	[m_currentDevice endGeneratingDeviceOrientationNotifications];

	// free up some memory
	m_currentDevice = nil;
	[m_lastError release], m_lastError = nil;
//	[m_resizedWebView release], m_resizedWebView = nil;
	[m_webView release], m_webView = nil;
	[m_blockingView release], m_blockingView = nil;
	m_ormmaDelegate = nil;
	[m_deferredShowAnimationSelector release], m_deferredShowAnimationSelector = nil;
	[m_deferredHideAnimationSelector release], m_deferredHideAnimationSelector = nil;
	[m_htmlStub release], m_htmlStub = nil;
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
	
//	// see if this is a call from our iframe
//	NSURLRequest *request = webView.request;
//	NSURL *url = [request URL];
//	NSString *urlString = [url absoluteString];
//	NSLog( @"webViewDidFinishLoading: %@", urlString );
//	if ( ![@"about:blank" isEqualToString:urlString] )
//	{
//		// call from iFrame, nothing to do
//		NSLog( @"Called from iFrame, ignoring" );
//		return;
//	}		
	
	// check for the existence of the ORMMA objects
	// if they do not exist, then assume we're good to display
	// otherwise wait for the creative to notify us that its done.
	NSLog( @"Web View Finished Loading" );
	NSString *result = [webView stringByEvaluatingJavaScriptFromString:@"typeof ormma"];
	NSLog( @"Testing Web View for ORMMA: %@", result );
	if ( [result isEqualToString:@"object"] )
	{
		// we are ORMMA enabled
		// setup the screen size
		UIScreen *screen = [UIScreen mainScreen];
		CGSize screenSize = screen.bounds.size;	
		NSString *bss = [NSString stringWithFormat:@"ormmaNativeBridge.setBaseScreenSize( %f, %f );", screenSize.width, screenSize.height];
		[webView stringByEvaluatingJavaScriptFromString:bss];
		
		// setup orientation
		UIDeviceOrientation orientation = m_currentDevice.orientation;
		NSInteger angle = [self angleFromOrientation:orientation];
		NSString *o = [NSString stringWithFormat:@"ormmaNativeBridge.orientation = %i;", angle];
		[webView stringByEvaluatingJavaScriptFromString:o];
		
		// add the various features the device supports, common to all iOS devices
		[webView stringByEvaluatingJavaScriptFromString:@"ormmaNativeBridge.addFeature( 'email' );"];
		[webView stringByEvaluatingJavaScriptFromString:@"ormmaNativeBridge.addFeature( 'location' );"];
		[webView stringByEvaluatingJavaScriptFromString:@"ormmaNativeBridge.addFeature( 'network' );"];
		[webView stringByEvaluatingJavaScriptFromString:@"ormmaNativeBridge.addFeature( 'orientation' );"];
		[webView stringByEvaluatingJavaScriptFromString:@"ormmaNativeBridge.addFeature( 'shake' );"];
		[webView stringByEvaluatingJavaScriptFromString:@"ormmaNativeBridge.addFeature( 'size' );"];
		[webView stringByEvaluatingJavaScriptFromString:@"ormmaNativeBridge.addFeature( 'tilt' );"];
		
		// now add the features that are available on specific devices
		NSInteger platformType = [m_currentDevice platformType];
		switch ( platformType )
		{
			case UIDevice1GiPhone:
				[webView stringByEvaluatingJavaScriptFromString:@"ormmaNativeBridge.addFeature( 'phone' );"];
				break;
			case UIDevice3GiPhone:
				[webView stringByEvaluatingJavaScriptFromString:@"ormmaNativeBridge.addFeature( 'phone' );"];
				break;
			case UIDevice3GSiPhone:
				[webView stringByEvaluatingJavaScriptFromString:@"ormmaNativeBridge.addFeature( 'phone' );"];
				[webView stringByEvaluatingJavaScriptFromString:@"ormmaNativeBridge.addFeature( 'heading' );"];
				break;
			case UIDevice4iPhone:
				[webView stringByEvaluatingJavaScriptFromString:@"ormmaNativeBridge.addFeature( 'phone' );"];
				[webView stringByEvaluatingJavaScriptFromString:@"ormmaNativeBridge.addFeature( 'rotation' );"];
				break;
			case UIDevice4GiPod:
				[webView stringByEvaluatingJavaScriptFromString:@"ormmaNativeBridge.addFeature( 'rotation' );"];
				break;
			default:
				break;
		}
		
		// see if calendar support is available
		Class eventStore = NSClassFromString( @"EKEventStore" );
		if ( eventStore != nil )
		{
			[webView stringByEvaluatingJavaScriptFromString:@"ormmaNativeBridge.addFeature( 'calendar' );"];
		}
		
		// let the ad know it can start work
		NSString *js = [NSString stringWithFormat:@"ormmaNativeBridge.applicationReady();"];
		[webView stringByEvaluatingJavaScriptFromString:js];
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

- (void)loadAd:(NSURL *)url
{
	// ads loaded by URL are assumed to be complete as-is, just display it
	NSLog( @"Load Ad from URL: %@", url );
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[m_webView loadRequest:request];
}


- (void)loadHTMLAd:(NSString *)htmlFragment
		   baseURL:(NSURL *)baseURL
{
	// ads loaded by HTML fragment are assumed to need a wrapper
	// so we use the specified HTML stub and inject what we need into it
	// and write everything to the filesystem in our cache.
	NSLog( @"Load Ad fragment: %@", htmlFragment );	
	
	// first check and see if we've already cached the url
	NSString *path = [m_cache cachePathFromURL:baseURL];
	NSLog( @"Ad Cache Path is: %@", path );

	// get the final HTML and write the file to the cache
	NSString *html = [self processHTMLStubUsingFragment:htmlFragment];
	NSLog( @"Full HTML is: %@", html );
	[m_cache cacheHTML:html
			   baseURL:(NSURL *)baseURL
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
	NSString *output = [self.htmlStub stringByReplacingOccurrencesOfString:kCacheRootToken
																withString:m_cache.cacheRoot];
	output = [output stringByReplacingOccurrencesOfString:kAdContentToken
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

- (void)executeJavaScript:(NSString *)javascript
{
	[m_webView stringByEvaluatingJavaScriptFromString:javascript];
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
	NSString *js = [NSString stringWithFormat:@"ormmaNativeBridge.stateChanged( 'default' );"];
	[m_webView stringByEvaluatingJavaScriptFromString:js];
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
	NSString *js = [NSString stringWithFormat:@"ormmaNativeBridge.stateChanged( 'hidden' );"];
	[m_webView stringByEvaluatingJavaScriptFromString:js];
}


- (void)closeAd:(UIWebView *)webView
{
	// the default ad may not be closed
	if ( self.currentState == ORMMAViewStateDefault )
	{
		// default ad
		return;
	}
	// we can't close it if it's not open
	if ( webView == nil )
	{
		return;
	}
	
	// closing the ad is effectively just restoring it to the default state,
	// whether it had been resized or brought to full screen. To do this, we're
	// basically going to reverse the steps we took to take it to the modified
	// state.
	//
	// We need to determine the relative position of the original ad on the
	// screen, then we need to animate to that size and location. Upon completion
	// of the animation, we will then move ourselves back into the correct view
	// hierarchy.
	
	// Step 1: notify the app that we're starting
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(adWillClose:)] ) )
	{
		[self.ormmaDelegate adWillClose:self];
	}

	// Step 2: get the key window
	UIApplication *app = [UIApplication sharedApplication];
	UIWindow *keyWindow = [app keyWindow];
	
	// Step 3: Account for Status Bar, if it's showing
	CGFloat delta = 0;
//	if ( ![app isStatusBarHidden] )
//	{
//		CGRect sbf = [app statusBarFrame];
//		delta = sbf.size.height;
//	}
	
	// Step 3: find the original parent view
	UIView *parentView = [keyWindow viewWithTag:m_parentTag];

	// Step 4: find out the translated location of the "default" ad
	CGPoint translatedPoint = [parentView convertPoint:m_originalFrame.origin 
												toView:keyWindow];
	CGRect f = CGRectMake( translatedPoint.x, 
						   ( translatedPoint.y + delta ), 
						   self.frame.size.width, 
						   self.frame.size.height );
	NSLog( @"Start Resize Frame: ( %f, %f ) by ( %f x %f )", f.origin.x, f.origin.y, f.size.width, f.size.height );
	NSLog( @"End Resize Frame: ( %f, %f ) by ( %f x %f )", m_originalFrame.origin.x, m_originalFrame.origin.y, m_originalFrame.size.width, m_originalFrame.size.height );
	
	// Step 5: animate the expanded ad to the size of the "default" ad
	[UIView beginAnimations:@"restore"
					context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelegate:self];
	self.frame = f;
	[UIView commitAnimations];
	
	// steps 6+ happens after the animation finishes
}


- (void)resizeTo:(CGRect)newFrame
	   inWebView:(UIWebView *)webView
{
//	// NOTE: we can only expand the default view
//	if ( webView != m_webView )
//	{
//		// not resizable
//		return;
//	}
	
	// NOTE: We cannot resize if we're in full screen mode
	if ( self.currentState == ORMMAViewStateFullScreen )
	{
		// nothing to do
		return;
	}
	
	// the intent is to appear to the user that the current ad is resizing.
	// this poses some interesting issues, specifically, since it's up to the 
	// consuming application to place the ad view, we don't know where in the
	// view hierarchy we are. Additionally, since many/most containing views
	// may clip sub views to the parent's bounds, we can't just change our
	// frame.
	//
	// to get around this we're going to basically "promote" the ad view to 
	// the key window at an initial location that is identical relatve to the
	// window. Additionally, we're going to save off the current parent's tag
	// and set it to a known unique value so that we can find the original
	// parent view again when we need to restore our state. We can't simply
	// store the parent view since we don't know if the OS will release it or
	// not.
	//
	// we're also going to add a blocking view to the window so that should the
	// user attempt to touch outside the boundaries of the resized ad we will 
	// automatically restore the ad to its default state.
	
	// Step 1: Notify the native app that we're preparing to resize
	NSLog( @"Resize Step 1" );
	if ( ( self.ormmaDelegate != nil ) && 
		( [self.ormmaDelegate respondsToSelector:@selector(adWillExpand:)] ) )
	{
		[self.ormmaDelegate adWillExpand:self];
	}
	
	// Step 2: get the key window
	NSLog( @"Resize Step 2" );
	UIApplication *app = [UIApplication sharedApplication];
	UIWindow *keyWindow = [app keyWindow];
	
	// Step 3: Account for Status Bar, if it's showing
	NSLog( @"Resize Step 3" );
	CGFloat delta = 0;
	m_finalFrame = newFrame;
	if ( ![app isStatusBarHidden] )
	{
		CGRect sbf = [app statusBarFrame];
		delta = sbf.size.height;
		m_finalFrame.origin.y += delta;
	}
	
	// some actions are only necessary if we're in the default state
	if ( self.currentState == ORMMAViewStateDefault )
	{
		// Step 4: Add a blocking View to the Key Window
		NSLog( @"Resize Step 4" );
		m_blockingView = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		m_blockingView.frame = keyWindow.frame;
		[m_blockingView addTarget:self
						   action:@selector(blockingViewTouched:) 
				 forControlEvents:UIControlEventTouchUpInside];
		m_blockingView.backgroundColor = [UIColor clearColor];
		[keyWindow addSubview:m_blockingView];
		
		// Step 5: Translate the position of the active web view into the 
		//         coordinate system of the Key Window
		NSLog( @"Resize Step 5" );
		CGPoint translatedPoint = [[self superview] convertPoint:self.frame.origin 
														  toView:keyWindow];
		CGRect f = CGRectMake( translatedPoint.x, 
							   translatedPoint.y, 
							   self.frame.size.width, 
							   self.frame.size.height );
		
		// Step 6: Save the original parent window's tag and generate a new one that
		// we're sure is unique
		NSLog( @"Resize Step 6" );
		UIView *parentView = self.superview;
		m_originalParentTag = parentView.tag;
		do
		{
			// pick a random tag number
			m_parentTag = 1 + ( arc4random() % 10051967 );
		}
		while ( [keyWindow viewWithTag:m_parentTag] != nil );
		parentView.tag = m_parentTag;
		
		// Step 7: Disconnect the ad view from it's current parent (remembering
		// that it will automatically be released when removeFromSuperview is
		// called) and add it to the key window in the same relative location
		// while saving the original frame
		NSLog( @"Resize Step 7" );
		m_originalFrame = self.frame;
		self.frame = f;
		[keyWindow addSubview:self];
		
		// make sure our state is updated
		self.currentState = ORMMAViewStateResized;

		NSLog( @"Start Resize Frame: ( %f, %f ) by ( %f x %f )", f.origin.x, f.origin.y, f.size.width, f.size.height );
	}
	NSLog( @"End Resize Frame: ( %f, %f ) by ( %f x %f )", m_finalFrame.origin.x, m_finalFrame.origin.y, m_finalFrame.size.width, m_finalFrame.size.height );

	// Step 8: Animate the new web view to the correct size and position
	NSLog( @"Resize Step 8" );
	[UIView beginAnimations:@"resize"
					context:nil];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelegate:self];
	self.frame = m_finalFrame;
	[UIView commitAnimations];
	
	// Steps 9+ happens after the animation completes
	

	// The following is an alternative replacement that uses two web views
	// at the moment, there is no provision for specifying the source of the 
	// second web view, so this is not yet operable.
	
//	// when we get a resize request, we want to give the user the "impression"
//	// that we are resizing the current view, even though we're using two
//	// different views.
//	// When we do a resize, we get the key window and add a blocking view that 
//	// fully covers it; then we add a new web view sized and positioned
//	// "over" the active web view; finally we resize the new view to the
//	// desired size and position.
//	
//	// Step 0: Notify the native app that we're starting
//	if ( ( self.ormmaDelegate != nil ) && 
//		( [self.ormmaDelegate respondsToSelector:@selector(adWillExpand:)] ) )
//	{
//		[self.ormmaDelegate adWillExpand:self];
//	}
//	
//	// Step 1: Get the Key Window
//	UIApplication *app = [UIApplication sharedApplication];
//	UIWindow *keyWindow = [app keyWindow];
//	
//	// Step 2: Add a blocking View to the Key Window
//	m_blockingView = [[UIView alloc] initWithFrame:keyWindow.frame];
//	m_blockingView.userInteractionEnabled = NO;
//	m_blockingView.backgroundColor = [UIColor clearColor];
//	[keyWindow addSubview:m_blockingView];
//	
//	// Step 3: Translate the position of the active web view into the 
//	//         coordinate system of the Key Window
//	CGPoint translatedPoint = [[self superview] convertPoint:self.frame.origin 
//													  toView:keyWindow];
//	CGRect f = CGRectMake( translatedPoint.x, 
//						   translatedPoint.y, 
//						   self.frame.size.width, 
//						   self.frame.size.height );
//	m_finalFrame = newFrame;
//	
//	// Step 3a: Account for Status Bar, if it's showing
//	CGFloat delta = 0;
//	if ( ![app isStatusBarHidden] )
//	{
//		CGRect sbf = [app statusBarFrame];
//		delta = sbf.size.height;
//		m_finalFrame.origin.y += delta;
//	}
//	NSLog( @"Start Resize Frame: ( %f, %f ) by ( %f x %f )", f.origin.x, f.origin.y, f.size.width, f.size.height );
//	NSLog( @"End Resize Frame: ( %f, %f ) by ( %f x %f )", m_finalFrame.origin.x, m_finalFrame.origin.y, m_finalFrame.size.width, m_finalFrame.size.height );
//	
//	// Step 4: Add a new web view to the Key Window using the translated frame
//	m_resizedWebView = [[UIWebView alloc] initWithFrame:f];
//	m_resizedWebView.backgroundColor = [UIColor clearColor];
//	m_resizedWebView.clipsToBounds = YES;
//	NSURLRequest *request = [NSURLRequest requestWithURL:url];
//	m_resizedWebView.delegate = self;
//	[m_resizedWebView loadRequest:request];
//	[keyWindow addSubview:m_resizedWebView];
//	
//	// Step 5: Animate the new web view to the correct size and position
//	[UIView beginAnimations:@"expanded"
//					context:nil];
//	[UIView setAnimationDuration:0.5];
//	[UIView setAnimationDelegate:self];
//	m_resizedWebView.frame = m_finalFrame;
//	[UIView commitAnimations];
}



#pragma mark -
#pragma mark Animation View Delegate

- (void)animationDidStop:(NSString *)animationID 
				finished:(NSNumber *)finished 
				 context:(void *)context
{
	NSString *newState = @"unknown";
	if ( [animationID isEqualToString:@"restore"] )
	{
		// finish the close function
//		// Step 5: remove the expanded ad from the view hierarchy
//		[m_resizedWebView removeFromSuperview], m_resizedWebView = nil;
		
		// Step 5: get the key window
		UIApplication *app = [UIApplication sharedApplication];
		UIWindow *keyWindow = [app keyWindow];

		// Step 6: return the ad to the original view hierarchy
		[self retain];
		[self removeFromSuperview];
		UIView *parentView = [keyWindow viewWithTag:m_parentTag];
		[parentView addSubview:self];
		CGRect f = CGRectMake( m_originalFrame.origin.x, 
								 m_originalFrame.origin.y, 
								 m_originalFrame.size.width, 
								 m_originalFrame.size.height );
		self.frame = f;
		[self release];
		f = parentView.frame;
		
		// Step 7: remove the blocker view from the view hierarcy
		[m_blockingView removeFromSuperview], m_blockingView = nil;
		
		// Step 8: restore our saved tags
		parentView.tag = m_originalParentTag;
		m_parentTag = 0;
		
		// step 9: now notify the app that we're done
		if ( ( self.ormmaDelegate != nil ) && 
			( [self.ormmaDelegate respondsToSelector:@selector(adDidClose:)] ) )
		{
			[self.ormmaDelegate adDidClose:self];
		}
		
		// Step 10: setup state changed event
		newState = @"default";
	}
	else
	{
		// finish the resize function

		// Step 8: notify the app that we're done
		if ( ( self.ormmaDelegate != nil ) && 
			( [self.ormmaDelegate respondsToSelector:@selector(adDidExpand:)] ) )
		{
			[self.ormmaDelegate adDidExpand:self];
		}
		
		// Step 9: setup state changed event
		newState = @"expanded";
	}

	// Final Step: send state changed event
	NSLog( @"STATE CHANGE TO %@", newState );
	NSString *js = [NSString stringWithFormat:@"ormmaNativeBridge.stateChanged( '%@' );", newState];
	[m_webView stringByEvaluatingJavaScriptFromString:js];
}



#pragma mark -
#pragma mark Cache Delegate

- (void)cacheFailed:(NSURL *)baseURL
		  withError:(NSError *)error
{
}


- (void)cachedBaseURL:(NSURL *)baseURL
			   onPath:(NSString *)path
{
	// now show the cached file
	NSURL *url = [NSURL fileURLWithPath:path];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[m_webView loadRequest:request];
}



#pragma mark -
#pragma mark General Actions

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
	NSLog( @"Path to source JS: %@", sourcePath );
	NSString *contents = [NSString stringWithContentsOfFile:sourcePath
												   encoding:NSUTF8StringEncoding
													  error:NULL];
	
	NSString *finalPath = [NSString stringWithFormat:@"%@/%@.%@", path, file, type];
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

@end
