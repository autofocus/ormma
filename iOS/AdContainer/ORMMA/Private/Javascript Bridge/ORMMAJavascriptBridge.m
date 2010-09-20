//
//  ORMMAJavascriptBridge.m
//  RichMediaAds
//
//  Created by Robert Hedin on 9/7/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import "ORMMAJavascriptBridge.h"
#import "Reachability.h"



@interface ORMMAJavascriptBridge ()

@property( nonatomic, retain ) Reachability *reachability;

- (NSDictionary *)parametersFromJSCall:(NSString *)parameterString;
- (BOOL)processCommand:(NSString *)command
			parameters:(NSDictionary *)parameters
			forWebView:(UIWebView *)webView;
- (BOOL)processShowCommand:(NSDictionary *)parameters
				forWebView:(UIWebView *)webView;
- (BOOL)processHideCommand:(NSDictionary *)parameters
				forWebView:(UIWebView *)webView;
- (BOOL)processCloseCommand:(NSDictionary *)parameters
				 forWebView:(UIWebView *)webView;
- (BOOL)processResizeCommand:(NSDictionary *)parameters
				  forWebView:(UIWebView *)webView;
- (BOOL)processServiceCommand:(NSDictionary *)parameters
				   forWebView:(UIWebView *)webView;

- (CGFloat)floatFromDictionary:(NSDictionary *)dictionary
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

NSString * const ORMMACommandResize = @"resize";

NSString * const ORMMACommandAddAsset = @"addasset";
NSString * const ORMMACommandRemoveAsset = @"removeasset";
NSString * const ORMMACommandRemoveAllAssets = @"removeallassets";

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
	}
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
	if ( [command isEqualToString:ORMMACommandShow] )
	{
		// process show
		processed = [self processShowCommand:parameters
							 forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandHide] )
	{
		// process hide
		processed = [self processHideCommand:parameters
							 forWebView:webView];
	}
	else if ( [command isEqualToString:ORMMACommandClose] )
	{
		// process close
		processed = [self processCloseCommand:parameters
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
		// process resize
		processed = [self processServiceCommand:parameters
								forWebView:webView];
	}
	
	if ( processed ) 
	{
		// notify JS that we've completed the last request
		NSString *js = @"ormmaNativeBridge.nativeCallComplete(); return 'OK';";
		[self.bridgeDelegate executeJavaScript:js];
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


- (BOOL)processResizeCommand:(NSDictionary *)parameters
				  forWebView:(UIWebView *)webView
{
	NSLog( @"Processing RESIZE Command..." );
	
	// get the location and bounds
	CGFloat x = [self floatFromDictionary:parameters
								   forKey:@"x"];
	CGFloat y = [self floatFromDictionary:parameters
								   forKey:@"y"];
	CGFloat w = [self floatFromDictionary:parameters
								   forKey:@"w"];
	CGFloat h = [self floatFromDictionary:parameters
								   forKey:@"h"];
	CGRect f = CGRectMake( x, y, w, h );
	[self.bridgeDelegate resizeTo:f
						inWebView:webView];
	return YES;
}


- (BOOL)processServiceCommand:(NSDictionary *)parameters
				   forWebView:(UIWebView *)webView
{
	NSLog( @"Processing SERVICE Command..." );
	
	// determine the desired service and state
	NSString *service = [parameters valueForKey:@"name"];
	NSString *desiredState = [parameters valueForKey:@"enabled"];
	BOOL enabled = ( [@"yes" isEqualToString:desiredState] );
	
	if ( [@"tiltChange" isEqualToString:service] ) // accelerometer
	{
		if ( enabled )
		{
			if ( m_accelerometer == nil )
			{
				m_accelerometer = [[UIAccelerometer sharedAccelerometer] retain];
				m_accelerometer.updateInterval = .1;
				m_accelerometer.delegate = self;
			}
		}
		else
		{
			m_accelerometer.delegate = nil, [m_accelerometer release], m_accelerometer = nil;
		}
		m_accelerometerEnabled = enabled;
	}
	else if ( [@"headingChange" isEqualToString:service] ) // compass
	{
		if ( [CLLocationManager headingAvailable] )
		{
			if ( enabled )
			{
				[m_locationManager startUpdatingHeading];
			}
			else
			{
				[m_locationManager stopUpdatingHeading];
			}
			m_compassEnabled = enabled;
		}
	}
	else if ( [@"locationChange" isEqualToString:service] ) // Location Based Services
	{
		if ( [CLLocationManager locationServicesEnabled] )
		{
			if ( enabled )
			{
				[m_locationManager startUpdatingLocation];
			}
			else
			{
				[m_locationManager stopUpdatingLocation];
			}
			m_locationEnabled = enabled;
		}
	}
	else if ( [@"networkChange" isEqualToString:service] ) // Reachability / Network
	{
		if ( enabled )
		{
			if ( self.reachability == nil )
			{
				self.reachability = [Reachability reachabilityForInternetConnection];
			}
			[self.reachability startNotifier];
		}
		else
		{
			[self.reachability stopNotifier];
			self.reachability = nil;
		}
		m_networkEnabled = enabled;
	}
	else if ( [@"rotationChange" isEqualToString:service] ) // gyroscope
	{
		if ( self.motionManager != nil )
		{
			if ( enabled )
			{
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
				[self.motionManager stopGyroUpdates];
			}
			m_gyroscopeEnabled = enabled;
		}
	}
	
	// anything else is not something that we need to enable or disable
	
	return YES;
}


// restore to default state
- (void)restoreServicesToDefaultState
{
	// accelerometer monitoring
	if ( m_accelerometerEnabled )
	{
		m_accelerometer.delegate = nil, [m_accelerometer release], m_accelerometer = nil;
		m_accelerometerEnabled = NO;
	}
	
	// compass monitoring
	if ( m_compassEnabled )
	{
		[m_locationManager stopUpdatingHeading];
		m_compassEnabled = NO;
	}
	
	// gyroscope monitoring
	if ( m_gyroscopeEnabled )
	{
		[m_timer invalidate], m_timer = nil;
		[self.motionManager stopGyroUpdates];
		m_gyroscopeEnabled = NO;
	}
	
	// location monitoring
	if ( m_locationEnabled )
	{
		[m_locationManager stopUpdatingLocation];
		m_locationEnabled = NO;
	}
	
	// network monitoring
	if ( m_networkEnabled )
	{
		if ( self.reachability != nil )
		{
			[self.reachability stopNotifier];
			self.reachability = nil;
		}
		m_networkEnabled = NO;
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
	NSString *js = [NSString stringWithFormat:@"ormmaNativeBridge.orientationChanged( %i );", orientationAngle];
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
	NSString *js = [NSString stringWithFormat:@"ormmaNativeBridge.networkChanged( %@ );", state];
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
	NSString *js = [NSString stringWithFormat:@"ormmaNativeBridge.acceleration( %f, %f, %f );", acceleration.x,
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
	NSString *js = [NSString stringWithFormat:@"ormmaNativeBridge.rotation( %f, %f, %f );", data.rotationRate.x, 
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
	NSString *jsFormat = @"ormmaNativeBridge.locationChanged( %f, %f, %f, %f, %f, '%@', %f, %f );";
	NSString *js = [NSString stringWithFormat:jsFormat, newLocation.coordinate.latitude, 
														newLocation.coordinate.longitude, 
														newLocation.altitude,
														newLocation.horizontalAccuracy,
														newLocation.verticalAccuracy,
														ts,
														newLocation.speed,
														newLocation.course];
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
	NSString *js = [NSString stringWithFormat:@"ormmaNativeBridge.headingChanged( %f, %f, %f, '%@' );", newHeading.magneticHeading,
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
	NSString *stringValue = [dictionary valueForKey:key];
	CGFloat value = [stringValue floatValue];
	return value;
}

@end
