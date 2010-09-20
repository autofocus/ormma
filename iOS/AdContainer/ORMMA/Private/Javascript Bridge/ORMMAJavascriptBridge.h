//
//  ORMMAJavascriptBridge.h
//  RichMediaAds
//
//  Created by Robert Hedin on 9/7/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>



@protocol ORMMAJavascriptBridgeDelegate;

@class Reachability;

@interface ORMMAJavascriptBridge : NSObject <UIAccelerometerDelegate,
											 CLLocationManagerDelegate>
{
@private
	id<ORMMAJavascriptBridgeDelegate> m_bridgeDelegate;
	
	CLLocationManager *m_locationManager;
	Reachability *m_reachability;
	UIAccelerometer *m_accelerometer;
	CMMotionManager *m_motionManager;
	NSTimer *m_timer;

	BOOL m_accelerometerEnabled;
	BOOL m_compassEnabled;
	BOOL m_gyroscopeEnabled;
	BOOL m_locationEnabled;
	BOOL m_networkEnabled;
	BOOL m_proximityEnabled;
}
@property( nonatomic, assign ) id<ORMMAJavascriptBridgeDelegate> bridgeDelegate;



// parses the passed URL; if it is handleable by the bridge, it will be handled 
// otherwise no action will be taken
// returns- TRUE  if the URL was processed, FALSE otherwise
- (BOOL)processURL:(NSURL *)url
		forWebView:(UIWebView *)webView;


- (void)restoreServicesToDefaultState;

@end



@protocol ORMMAJavascriptBridgeDelegate

- (void)executeJavaScript:(NSString *)javascript;

- (void)showAd:(UIWebView *)webView;
- (void)hideAd:(UIWebView *)webView;
- (void)closeAd:(UIWebView *)webView;

- (void)resizeTo:(CGRect)newFrame
	   inWebView:(UIWebView *)webView;

@end