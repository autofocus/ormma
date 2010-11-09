//
//  TWCRichAdView.h
//  RichMediaAds
//
//  Created by Robert Hedin on 9/7/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>


@class ORMMAJavascriptBridge;
@class ORMMALocalServer;
@class ORMMAWebBrowserViewController;

@protocol ORMMAViewDelegate;
@protocol ORMMAJavascriptBridgeDelegate;




typedef enum ORMMAViewStateEnum
{
	ORMMAViewStateHidden = -1,
	ORMMAViewStateDefault = 0,
	ORMMAViewStateResized,
	ORMMAViewStateExpanded
} ORMMAViewState;



@interface ORMMAView : UIView <MFMailComposeViewControllerDelegate,
							   MFMessageComposeViewControllerDelegate>
{
@private
	UIDevice *m_currentDevice;
	ORMMAJavascriptBridge *m_javascriptBridge;
	id<ORMMAViewDelegate> m_ormmaDelegate;
	NSString *m_htmlStub;
	ORMMAViewState m_currentState;
	NSError *m_lastError;
	BOOL m_adVisible;
	
	// for resize
	CGSize m_maxSize;

	UIWebView *m_webView;
	CGRect m_defaultFrame;
	
	UIWebView *m_expandedView;
	CGRect m_initialFrame;
	UIButton *m_blockingView;
	
	ORMMAWebBrowserViewController *m_webBrowser;
	
	NSURL *m_creativeURL;
	long m_creativeId;
	
	BOOL m_applicationReady;
}
@property( nonatomic, assign ) id<ORMMAViewDelegate> ormmaDelegate;
@property( nonatomic, copy ) NSString *htmlStub;
@property( nonatomic, copy ) NSURL *creativeURL;
@property( nonatomic, retain, readonly ) NSError *lastError;
@property( nonatomic, assign, readonly ) ORMMAViewState currentState;
@property( nonatomic, assign ) CGSize maxSize;


- (void)loadCreative:(NSURL *)url;

- (void)loadHTMLCreative:(NSString *)htmlFragment
			 creativeURL:(NSURL *)url;


// used to force an ad to revert to its default state
- (void)restoreToDefaultState;


- (void)doneWithBrowser;


@end




@protocol ORMMAViewDelegate <NSObject>

@required

// retrieves the owning view controller
- (UIViewController *)ormmaViewController;


@optional

// called to allow the application to execute javascript on the creative at the
// time the creative is loaded
- (NSString *)onLoadJavaScriptForAd:(ORMMAView *)adView;

// called when an ad fails to load
- (void)failureLoadingAd:(ORMMAView *)adView;

// Called before the ad is resized in place to allow the parent application to
// animate things if desired.
- (void)willResizeAd:(ORMMAView *)adView
			  toSize:(CGSize)size;

// Called after the ad is resized in place to allow the parent application to
// animate things if desired.
- (void)didResizeAd:(ORMMAView *)adView
			  toSize:(CGSize)size;



// Called just before to an ad is displayed
- (void)adWillShow:(ORMMAView *)adView;

// Called just after to an ad is displayed
- (void)adDidShow:(ORMMAView *)adView;

// Called just before to an ad is Hidden
- (void)adWillHide:(ORMMAView *)adView;

// Called just after to an ad is Hidden
- (void)adDidHide:(ORMMAView *)adView;

// Called just before an ad expands
- (void)willExpandAd:(ORMMAView *)adView
			 toFrame:(CGRect)frame;

// Called just after an ad expands
- (void)didExpandAd:(ORMMAView *)adView
			toFrame:(CGRect)frame;

// Called just before an ad closes
- (void)adWillClose:(ORMMAView *)adView;

// Called just after an ad closes
- (void)adDidClose:(ORMMAView *)adView;

// called when the ad will begin heavy content (usually when the ad goes full screen)
- (void)appShouldSuspendForAd:(ORMMAView *)adView;

// called when the ad is finished with it's heavy content (usually when the ad returns from full screen)
- (void)appShouldResumeFromAd:(ORMMAView *)adView;

@end
