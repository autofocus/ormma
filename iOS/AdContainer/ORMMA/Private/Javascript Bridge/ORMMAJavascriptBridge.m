//
//  ORMMAJavascriptBridge.m
//  RichMediaAds
//
//  Created by Robert Hedin on 9/7/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "ORMMAJavascriptBridge.h"
#import "Reachability.h"



@interface ORMMAJavascriptBridge ()

@property( nonatomic, retain ) Reachability *reachability;

- (NSDictionary *)parametersFromJSCall:(NSString *)parameterString;
- (BOOL)processCommand:(NSString *)command
			parameters:(NSDictionary *)parameters
			forWebView:(UIWebView *)webView;
- (BOOL)processCloseCommand:(NSDictionary *)parameters
				 forWebView:(UIWebView *)webView;
- (BOOL)processExpandCommand:(NSDictionary *)parameters
				  forWebView:(UIWebView *)webView;
- (BOOL)processHideCommand:(NSDictionary *)parameters
				forWebView:(UIWebView *)webView;
- (BOOL)processResizeCommand:(NSDictionary *)parameters
				  forWebView:(UIWebView *)webView;
- (BOOL)processServiceCommand:(NSDictionary *)parameters
				   forWebView:(UIWebView *)webView;
- (BOOL)processShowCommand:(NSDictionary *)parameters
				forWebView:(UIWebView *)webView;
- (BOOL)processOpenCommand:(NSDictionary *)parameters
				forWebView:(UIWebView *)webView;
- (BOOL)processRequestCommand:(NSDictionary *)parameters
				   forWebView:(UIWebView *)webView;
- (BOOL)processCalendarCommand:(NSDictionary *)parameters
					forWebView:(UIWebView *)webView;
- (BOOL)processCameraCommand:(NSDictionary *)parameters
				  forWebView:(UIWebView *)webView;
- (BOOL)processEMailCommand:(NSDictionary *)parameters
				 forWebView:(UIWebView *)webView;
- (BOOL)processPhoneCommand:(NSDictionary *)parameters
				 forWebView:(UIWebView *)webView;
- (BOOL)processSMSCommand:(NSDictionary *)parameters
			   forWebView:(UIWebView *)webView;
- (BOOL)processAddAssetCommand:(NSDictionary *)parameters
					forWebView:(UIWebView *)webView;
- (BOOL)processRemoveAssetCommand:(NSDictionary *)parameters
					   forWebView:(UIWebView *)webView;
- (BOOL)processRemoveAllAssetsCommand:(NSDictionary *)parameters
						   forWebView:(UIWebView *)webView;

- (CGFloat)floatFromDictionary:(NSDictionary *)dictionary
						forKey:(NSString *)key;
- (CGFloat)floatFromDictionary:(NSDictionary *)dictionary
						forKey:(NSString *)key
				   withDefault:(CGFloat)defaultValue; 
- (NSString *)requiredStringFromDictionary:(NSDictionary *)dictionary
									forKey:(NSString *)key;
- (BOOL)booleanFromDictionary:(NSDictionary *)dictionary
					   forKey:(NSString *)key;

@end




@implementation ORMMAJavascriptBridge


#pragma mark -
#pragma mark Constants

// the protocol to use to identify the ORMMA request
NSString * const ORMMAProtocol = @"ormma://";

NSString * const ORMMACommandShow = @"show";
NSString * const ORMMACommandHide = @"hide";
NSString * const ORMMACommandClose = @"close";

NSString * const ORMMACommandExpand = @"expand";
NSString * const ORMMACommandResize = @"resize";

NSString * const ORMMACommandAddAsset = @"addasset";
NSString * const ORMMACommandRemoveAsset = @"removeasset";
NSString * const ORMMACommandRemoveAllAssets = @"removeallassets";

NSString * const ORMMACommandCalendar = @"calendar";
NSString * const ORMMACommandCamera = @"camera";
NSString * const ORMMACommandEMail = @"email";
NSString * const ORMMACommandPhone = @"phone";
NSString * const ORMMACommandSMS = @"sms";

NSString * const ORMMACommandOpen = @"open";
NSString * const ORMMACommandRequest = @"request";

NSString * const ORMMACommandService = @"service";




#pragma mark -
#pragma mark Properties

@synthesize bridgeDelegate = m_bridgeDelegate;
@synthesize reachability = m_reachability;
@synthesize motionManager = m_motionManager;



#pragma mark -
#pragma mark Initializers / Memory Management

- (ORMMAJavascriptBridge *)init
{
	if ( ( self = [super init] ) )
	{
		// set ourselves up for location based services
		m_locationManager = [[CLLocationManager alloc] init];
        m_locationManager.delegate = self;
		m_locationManager.desiredAccuracy = kCLLocationAccuracyBest;
		
		// check for the availability of Core Motion
		if ( NSClassFromString( @"CMMotionManager" ) != nil )
		{
			self.motionManager = [[CMMotionManager alloc] init];
		}

		// make sure to register for the events that we care about
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self
							   selector:@selector(orientationChanged:)
								   name:UIDeviceOrientationDidChangeNotification
								 object:nil];
		[notificationCenter addObserver:self
							   selector:@selector(reachabilityStateChanged:)
								   name:kReachabilityChangedNotification
								 object:nil];
		[notificationCenter addObserver:self 
							   selector:@selector(keyboardWillShow:) 
								   name:UIKeyboardWillShowNotification
								 object:nil];
		[notificationCenter addObserver:self 
							   selector:@selector(keyboardWillHide:) 
								   name:UIKeyboardWillHideNotification
								 object:nil];	}
	return self;
}


- (void)dealloc
{
	// stop listening for notifications
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self];
	
	[self restoreServicesToDefaultState];
	
	[m_timer invalidate], m_timer = nil;
	m_bridgeDelegate = nil;
	m_accelerometer.delegate = nil,[m_accelerometer release], m_accelerometer = nil;
	[m_locationManager release], m_locationManager = nil;
	[self.motionManager stopGyroUpdates], self.motionManager = nil;
	[super dealloc];
}



#pragma mark -
#pragma mark Process

- (BOOL)processURL:(NSURL *)url
		forWebView:(UIWebView *)webView
{
	NSString *workingUrl = [url absoluteString];
	if ( [workingUrl hasPrefix:ORMMAProtocol] )
	{
		// the URL is intended for the bridge, so process it
		NSString *workingCall = [workingUrl substringFromIndex:ORMMAProtocol.length];
		
		// get the command
		NSRange r = [workingCall rangeOfString:@"?"];
		if ( r.location == NSNotFound )
		{
			// just a command
			return [self processCommand:workingCall 
							 parameters:nil
							 forWebView:webView];
		}
		NSString *command = [[workingCall substringToIndex:r.location] lowercaseString];
		NSString *parameterValues = [workingCall substringFromIndex:( r.location + 1 )];
		NSDictionary *parameters = [self parametersFromJSCall:parameterValues];
		NSLog( @"ORMMA Command: %@, %@", command, parameters );
		
		// let the callee know
		return [self processCommand:command 
						 parameters:parameters
						 forWebView:webView];
	}
	
	// not intended for the bridge
	return NO;
}


- (NSDictionary *)parametersFromJSCall:(NSString *)parameterString
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	
	// find the start of our parameters
	NSArray *parameterList = [parameterString componentsSeparatedByString:@"&"];
	for ( NSString *parameterEntry in parameterList )
	{
		NSArray *kvp = [parameterEntry componentsSeparatedByString:@"="];
		NSString *key = [kvp objectAtIndex:0];
		NSString *encodedValue = [kvp objectAtIndex:1];
		NSString *value = [encodedValue stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];;
		[parameters setObject:value forKey:key];
	}
	
	return parameters;
}


- (BOOL)processCommand:(NSString *)command
			parameters:(NSDictionary *)parameters
			forWebView:(UIWebView *)webView
{
	NSLog( @"Validating Command: %@", command );
	BOOL processed = NO;
	if ( [command isEqualToString:ORMMACommandClose] )
	{
		// process close
		processed = [self processCloseCommand:parameters
								   forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandExpand] )
	{
		// process hide
		processed = [self processExpandCommand:parameters
									forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandHide] )
	{
		// process hide
		processed = [self processHideCommand:parameters
							 forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandResize] )
	{
		// process resize
		processed = [self processResizeCommand:parameters
							   forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandService] )
	{
		// process service
		processed = [self processServiceCommand:parameters
								forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandShow] )
	{
		// process show
		processed = [self processShowCommand:parameters
								  forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandAddAsset] )
	{
		// process show
		processed = [self processAddAssetCommand:parameters
									  forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandRemoveAsset] )
	{
		// process show
		processed = [self processRemoveAssetCommand:parameters
										 forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandRemoveAllAssets] )
	{
		// process show
		processed = [self processRemoveAllAssetsCommand:parameters
											 forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandOpen] )
	{
		// process show
		processed = [self processOpenCommand:parameters
								  forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandRequest] )
	{
		// process show
		processed = [self processRequestCommand:parameters
									 forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandCalendar] )
	{
		// process show
		processed = [self processCalendarCommand:parameters
									  forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandCamera] )
	{
		// process show
		processed = [self processCameraCommand:parameters
									forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandEMail] )
	{
		// process show
		processed = [self processEMailCommand:parameters
								   forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandPhone] )
	{
		// process show
		processed = [self processPhoneCommand:parameters
								   forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandSMS] )
	{
		// process show
		processed = [self processSMSCommand:parameters
								 forWebView:webView];
	}
	
	if ( processed ) 
	{
		// notify JS that we've completed the last request
		[self.bridgeDelegate executeJavaScript:@"window.OrmmaBridge.nativeCallComplete();"];
		NSLog( @"Processing complete." );
	}
	else
	{
		NSLog( @"Unknown Command: %@", command );
	}
	
	return processed;
}


- (BOOL)processShowCommand:(NSDictionary *)parameters
				forWebView:(UIWebView *)webView
{
	NSLog( @"Processing SHOW Command..." );
	[self.bridgeDelegate showAd:webView];
	return YES;
}


- (BOOL)processHideCommand:(NSDictionary *)parameters
				forWebView:(UIWebView *)webView
{
	NSLog( @"Processing HIDE Command..." );
	[self.bridgeDelegate hideAd:webView];
	return YES;
}


- (BOOL)processCloseCommand:(NSDictionary *)parameters
				 forWebView:(UIWebView *)webView
{
	NSLog( @"Processing CLOSE Command..." );
	[self.bridgeDelegate closeAd:webView];
	return YES;
}


- (BOOL)processExpandCommand:(NSDictionary *)parameters
				  forWebView:(UIWebView *)webView
{
	NSLog( @"Processing EXPAND Command..." );
	
	// account for status bar, if needed
	CGFloat yDelta = 0;
	UIApplication *app = [UIApplication sharedApplication];
	if ( !app.statusBarHidden )
	{
		yDelta = app.statusBarFrame.size.height;
	}
	
	// ok, to make it easy on the client, we don't require them to give us all
	// the values all the time.
	// basicallly we're going to take the current real frame information from
	// the ad (translated to window space coordinates) and set both the initial
	// and final values to this information. Then for each data point we receive
	// from the client, we override the appropriate value.
	// this allows the client to say things like "using the current ad position,
	// expand the ad's height to 300px"
	CGRect f = [self.bridgeDelegate getAdFrameInWindowCoordinates];
	CGFloat x1 = f.origin.x;
	CGFloat y1 = f.origin.y;
	CGFloat w1 = f.size.width;
	CGFloat h1 = f.size.height;
	CGFloat x2 = x1;
	CGFloat y2 = y1;
	CGFloat w2 = w1;
	CGFloat h2 = h1;	
	
	// now get the sizes as specified by the creative
	x1 = [self floatFromDictionary:parameters
								   forKey:@"x1"
							   withDefault:x1];
	y1 = [self floatFromDictionary:parameters
								   forKey:@"y1"
							   withDefault:y1];
	w1 = [self floatFromDictionary:parameters
								   forKey:@"w1"
							   withDefault:w1];
	h1 = [self floatFromDictionary:parameters
								   forKey:@"h1"
							   withDefault:h1];
	x2 = [self floatFromDictionary:parameters
									forKey:@"x2"
							   withDefault:x2];
	y2 = [self floatFromDictionary:parameters
									forKey:@"y2"
							   withDefault:y2];
	w2 = [self floatFromDictionary:parameters
									forKey:@"w2"
							   withDefault:w2];
	h2 = [self floatFromDictionary:parameters
									forKey:@"h2"
							   withDefault:h2];
	NSString *urlString = [parameters valueForKey:@"url"];
	NSURL *url = [NSURL URLWithString:urlString];
	NSLog( @"Expanding from ( %f, %f ) ( %f x %f ) to ( %f, %f ) ( %f x %f ) showing %@", x1, y1, w1, h1, x2, y2, w2, h2, url );
	CGRect f1 = CGRectMake( x1, ( y1 + yDelta ), w1, h1 );
	CGRect f2 = CGRectMake( x2, ( y2 + yDelta ), w2, h2 );
	[self.bridgeDelegate expandFrom:f1
								 to:f2
							withURL:url
						inWebView:webView];
	return YES;
}


- (BOOL)processResizeCommand:(NSDictionary *)parameters
				  forWebView:(UIWebView *)webView
{
	NSLog( @"Processing RESIZE Command..." );
	
	// get the new bounds
	CGFloat w = [self floatFromDictionary:parameters
								   forKey:@"w"];
	CGFloat h = [self floatFromDictionary:parameters
								   forKey:@"h"];
	[self.bridgeDelegate resizeToWidth:w
								height:h
							 inWebView:webView];
	return YES;
}


- (BOOL)processAddAssetCommand:(NSDictionary *)parameters
					forWebView:(UIWebView *)webView
{
	NSLog( @"Processing ADD ASSET Command..." );
	return YES;
}


- (BOOL)processRemoveAssetCommand:(NSDictionary *)parameters
					   forWebView:(UIWebView *)webView
{
	NSLog( @"Processing REMOVE ASSET Command..." );
	return YES;
}


- (BOOL)processRemoveAllAssetsCommand:(NSDictionary *)parameters
						   forWebView:(UIWebView *)webView
{
	NSLog( @"Processing REMOVE ALL ASSETS Command..." );
	return YES;
}

	
- (BOOL)processOpenCommand:(NSDictionary *)parameters
				forWebView:(UIWebView *)webView
{
	NSLog( @"Processing OPEN Command..." );
	return YES;
}


- (BOOL)processRequestCommand:(NSDictionary *)parameters
				   forWebView:(UIWebView *)webView
{
	NSLog( @"Processing REQUEST Command..." );
	return YES;
}


- (BOOL)processCalendarCommand:(NSDictionary *)parameters
					forWebView:(UIWebView *)webView
{
	NSLog( @"Processing CALENDAR Command..." );
	return YES;
}


- (BOOL)processCameraCommand:(NSDictionary *)parameters
				  forWebView:(UIWebView *)webView
{
	NSLog( @"Processing CAMERA Command..." );
	return YES;
}


- (BOOL)processEMailCommand:(NSDictionary *)parameters
				 forWebView:(UIWebView *)webView
{
	NSLog( @"Processing EMAIL Command..." );
	NSString *to = [self requiredStringFromDictionary:parameters 
											   forKey:@"to"];
	NSString *subject = [self requiredStringFromDictionary:parameters 
													forKey:@"subject"];
	NSString *body = [self requiredStringFromDictionary:parameters 
												 forKey:@"body"];
	BOOL html = [self booleanFromDictionary:parameters 
									 forKey:@"html"];
	if ( ( body != nil ) && 
		 ( to != nil ) && 
		 ( subject != nil ) )
	{
		[self.bridgeDelegate sendEMailTo:to
							 withSubject:subject
								withBody:body
								  isHTML:html];
	}
	return YES;
}


- (BOOL)processPhoneCommand:(NSDictionary *)parameters
				 forWebView:(UIWebView *)webView
{
	NSLog( @"Processing PHONE Command..." );
	return YES;
}


- (BOOL)processSMSCommand:(NSDictionary *)parameters
			   forWebView:(UIWebView *)webView
{
	NSLog( @"Processing SMS Command..." );
	
	NSString *to = [self requiredStringFromDictionary:parameters 
											   forKey:@"to"];
	NSString *body = [self requiredStringFromDictionary:parameters 
												 forKey:@"body"];
	if ( ( body != nil ) && 
		 ( to != nil ) )
	{
		[self.bridgeDelegate sendSMSTo:to
							  withBody:body];
	}
	return YES;
}


- (BOOL)processServiceCommand:(NSDictionary *)parameters
				   forWebView:(UIWebView *)webView
{
	NSLog( @"Processing SERVICE Command..." );
	
	// determine the desired service and state
	NSString *eventName = [parameters valueForKey:@"name"];
	NSString *desiredState = [parameters valueForKey:@"enabled"];
	BOOL enabled = ( [@"yes" isEqualToString:desiredState] );
	
	if ( [@"ready" isEqualToString:eventName] ) // application ready
	{
		if ( enabled )
		{
			// client is requesting notification when the app is ready
			// if we're ready at the point this is registered, just go ahead
			// and fire the event
			[self.bridgeDelegate applicationReadyNotificationRequestReceived];
		}
	}	
	else if ( [@"tiltChange" isEqualToString:eventName] ) // accelerometer
	{
		if ( enabled )
		{
			m_accelerometerEnableCount++;
			if ( m_accelerometer == nil )
			{
				m_accelerometer = [[UIAccelerometer sharedAccelerometer] retain];
				m_accelerometer.updateInterval = .1;
				m_accelerometer.delegate = self;
			}
		}
		else
		{
			if ( m_accelerometerEnableCount > 0 )
			{
				m_accelerometerEnableCount--;
				if ( m_accelerometerEnableCount == 0 )
				{
					m_accelerometer.delegate = nil, [m_accelerometer release], m_accelerometer = nil;
				}
			}
		}
	}
	else if ( [@"headingChange" isEqualToString:eventName] ) // compass
	{
		if ( [CLLocationManager headingAvailable] )
		{
			if ( enabled )
			{
				m_compassEnableCount++;
				if ( m_compassEnableCount == 1 )
				{
					[m_locationManager startUpdatingHeading];
				}
			}
			else
			{
				if ( m_compassEnableCount > 0 )
				{
					m_compassEnableCount--;
					if ( m_compassEnableCount == 0 )
					{
						[m_locationManager stopUpdatingHeading];
					}
				}
			}
		}
	}
	else if ( [@"locationChange" isEqualToString:eventName] ) // Location Based Services
	{
		if ( [CLLocationManager locationServicesEnabled] )
		{
			if ( enabled )
			{
				m_locationEnableCount++;
				if ( m_locationEnableCount == 1 )
				{
					[m_locationManager startUpdatingLocation];
				}
			}
			else
			{
				if ( m_locationEnableCount > 0 )
				{
					m_locationEnableCount++;
					if ( m_locationEnableCount == 0 )
					{
						[m_locationManager stopUpdatingLocation];
					}
				}
			}
		}
	}
	else if ( [@"networkChange" isEqualToString:eventName] ) // Reachability / Network
	{
		if ( enabled )
		{
			m_networkEnableCount++;
			if ( self.reachability == nil )
			{
				self.reachability = [Reachability reachabilityForInternetConnection];
			}
			[self.reachability startNotifier];
		}
		else
		{
			if ( m_networkEnableCount > 0 )
			{
				m_networkEnableCount--;
				if ( m_networkEnableCount == 0 )
				{
					[self.reachability stopNotifier];
					self.reachability = nil;
				}
			}
		}
	}
	else if ( [@"rotationChange" isEqualToString:eventName] ) // gyroscope
	{
		if ( self.motionManager != nil )
		{
			if ( enabled )
			{
				m_gyroscopeEnableCount++;
				if ( m_timer == nil )
				{
					m_timer = [NSTimer scheduledTimerWithTimeInterval:0.1 
															   target:self
															 selector:@selector(timerFired)
															 userInfo:nil 
															  repeats:YES];
					[self.motionManager startGyroUpdates];
				}
			}
			else
			{
				if ( m_gyroscopeEnableCount > 0 )
				{
					m_gyroscopeEnableCount--;
					if ( m_gyroscopeEnableCount == 0 )
					{
						[self.motionManager stopGyroUpdates];
					}
				}
			}
		}
	}
	
	// anything else is not something that we need to enable or disable
	
	return YES;
}


// restore to default state
- (void)restoreServicesToDefaultState
{
	// accelerometer monitoring
	if ( m_accelerometerEnableCount > 0 )
	{
		m_accelerometer.delegate = nil, [m_accelerometer release], m_accelerometer = nil;
		m_accelerometerEnableCount = 0;
	}
	
	// compass monitoring
	if ( m_compassEnableCount > 0 )
	{
		[m_locationManager stopUpdatingHeading];
		m_compassEnableCount = 0;
	}
	
	// gyroscope monitoring
	if ( m_gyroscopeEnableCount > 0 )
	{
		[m_timer invalidate], m_timer = nil;
		[self.motionManager stopGyroUpdates];
		m_gyroscopeEnableCount = 0;
	}
	
	// location monitoring
	if ( m_locationEnableCount > 0 )
	{
		[m_locationManager stopUpdatingLocation];
		m_locationEnableCount = 0;
	}
	
	// network monitoring
	if ( m_networkEnableCount > 0 )
	{
		if ( self.reachability != nil )
		{
			[self.reachability stopNotifier];
			self.reachability = nil;
		}
		m_networkEnableCount = 0;
	}
}


#pragma mark -
#pragma mark Notification Center Dispatch Methods

- (void)orientationChanged:(NSNotification *)notification
{
	UIDevice *device = [UIDevice currentDevice];
	UIDeviceOrientation orientation = device.orientation;
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
	NSString *js = [NSString stringWithFormat:@"window.OrmmaBridge.orientationChanged( %i );", orientationAngle];
	[self.bridgeDelegate executeJavaScript:js];
}


- (void)reachabilityStateChanged:(NSNotification *)notification
{
	NSString *state = @"offline";
	Reachability *r = (Reachability *)notification.object;
	if ( [r isReachableViaWWAN] )
	{
		state = @"cell";
	}
	else if ( [r isReachableViaWiFi] )
	{
		state = @"wifi";
	}
	NSString *js = [NSString stringWithFormat:@"window.OrmmaBridge.networkChanged( '%@' );", state];
	[self.bridgeDelegate executeJavaScript:js];
}


- (void)keyboardWillShow:(NSNotification *)notification
{
	NSString *js = @"window.OrmmaBridge.keyboardChanged( true );";
	[self.bridgeDelegate executeJavaScript:js];
}


- (void)keyboardWillHide:(NSNotification *)notification
{
	NSString *js = @"window.OrmmaBridge.keyboardChanged( false );";
	[self.bridgeDelegate executeJavaScript:js];
}



#pragma mark -
#pragma mark Accelerometer Delegete

- (void)accelerometer:(UIAccelerometer *)accelerometer 
		didAccelerate:(UIAcceleration *)acceleration
{
	NSLog( @"Acceleration Data Available: %f, %f, %f", acceleration.x,
													   acceleration.y,
													   acceleration.z );
	NSString *js = [NSString stringWithFormat:@"window.OrmmaBridge.acceleration( %f, %f, %f );", acceleration.x,
																								acceleration.y,
																								acceleration.z];
	[self.bridgeDelegate executeJavaScript:js];
}


#pragma mark -
#pragma mark Timer Handler

- (void)timerFired
{
	// get the current gyroscope data
	CMGyroData *data = self.motionManager.gyroData;
	NSLog( @"Gyroscope Data Available: %f, %f, %f", data.rotationRate.x, 
													data.rotationRate.y, 
													data.rotationRate.z );
	NSString *js = [NSString stringWithFormat:@"window.OrmmaBridge.rotation( %f, %f, %f );", data.rotationRate.x, 
																							data.rotationRate.y, 
																							data.rotationRate.z];
	[self.bridgeDelegate executeJavaScript:js];
}



#pragma mark -
#pragma mark Location Manager Delegate (including Compass)

- (void)locationManager:(CLLocationManager *)manager 
	didUpdateToLocation:(CLLocation *)newLocation 
		   fromLocation:(CLLocation *)oldLocation
{
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setTimeStyle:NSDateFormatterFullStyle];
	[formatter setDateStyle:NSDateFormatterFullStyle];
	NSString *ts = [formatter stringFromDate:newLocation.timestamp];;
	NSLog( @"Location Data Available: (%f, %f, %f ), acc: %f / %f, ts: %@, speed: %f @ %f", newLocation.coordinate.latitude, 
																							newLocation.coordinate.longitude, 
																							newLocation.altitude,
																							newLocation.horizontalAccuracy,
																							newLocation.verticalAccuracy,
																							ts,
																							newLocation.speed,
																							newLocation.course );
	NSString *jsFormat = @"window.OrmmaBridge.locationChanged( %f, %f, %f );";
	NSString *js = [NSString stringWithFormat:jsFormat, newLocation.coordinate.latitude, 
														newLocation.coordinate.longitude, 
														newLocation.horizontalAccuracy];
	NSLog( @"JS: %@", js );
	[self.bridgeDelegate executeJavaScript:js];
}


- (void)locationManager:(CLLocationManager *)manager 
	   didFailWithError:(NSError *)error

{
}


- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
	// TODO: We may want to show a calibration screen based on the accuracy of 
	// the heading
	return NO;
}


- (void)locationManager:(CLLocationManager *)manager 
	   didUpdateHeading:(CLHeading *)newHeading
{ 
	NSLog( @"Heading Data Available: %f, %f, %f", newHeading.magneticHeading,
												  newHeading.trueHeading,
												  newHeading.headingAccuracy );
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setTimeStyle:NSDateFormatterFullStyle];
	[formatter setDateStyle:NSDateFormatterFullStyle];
	NSString *headingTimestamp = [formatter stringFromDate:newHeading.timestamp];;
	NSString *js = [NSString stringWithFormat:@"window.OrmmaBridge.headingChanged( %f, %f, %f, '%@' );", newHeading.magneticHeading,
																									    newHeading.trueHeading,
																									    newHeading.headingAccuracy,
																									    headingTimestamp];
	[self.bridgeDelegate executeJavaScript:js];
}


- (void)locationManager:(CLLocationManager *)manager 
		 didEnterRegion:(CLRegion *)region
{
}


- (void)locationManager:(CLLocationManager *)manager 
		  didExitRegion:(CLRegion *)region
{
}


- (void)locationManager:(CLLocationManager *)manager 
monitoringDidFailForRegion:(CLRegion *)region 
			  withError:(NSError *)error
{
}



#pragma mark -
#pragma mark Utility

- (CGFloat)floatFromDictionary:(NSDictionary *)dictionary
						forKey:(NSString *)key
{
	return [self floatFromDictionary:dictionary
							  forKey:key
						 withDefault:0.0];
}


- (CGFloat)floatFromDictionary:(NSDictionary *)dictionary
						forKey:(NSString *)key
				   withDefault:(CGFloat)defaultValue
{
	NSString *stringValue = [dictionary valueForKey:key];
	if ( stringValue == nil )
	{
		return defaultValue;
	}
	CGFloat value = [stringValue floatValue];
	return value;
}


- (BOOL)booleanFromDictionary:(NSDictionary *)dictionary
					   forKey:(NSString *)key
{
	NSString *stringValue = [dictionary valueForKey:key];
	BOOL value = [@"Y" isEqualToString:stringValue] || [@"y" isEqualToString:stringValue];
	return value;
}


- (NSString *)requiredStringFromDictionary:(NSDictionary *)dictionary
									forKey:(NSString *)key
{
	NSString *value = [dictionary objectForKey:key];
	if ( value == nil )
	{
		// error
		NSLog( @"Missing required parameter: %@", key );
		return nil;
	}
	value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ( value.length == 0 )
	{
		NSLog( @"Missing required parameter: %@", key );
		return nil;
	}
	return value;
}

@end
