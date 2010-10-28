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

@protocol ORMMAViewDelegate;
@protocol ORMMAJavascriptBridgeDelegate;



typedef enum ORMMAViewStateEnum
{
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
	ORMMALocalServer *m_localServer;
	NSError *m_lastError;
	BOOL m_adVisible;
	NSBundle *m_ormmaBundle;

	UIWebView *m_webView;
	CGRect m_defaultFrame;
	
	UIWebView *m_expandedView;
	CGRect m_initialFrame;
	UIButton *m_closeButton;
	UIButton *m_blockingView;
	
	NSURL *m_creativeURL;
	long m_creativeId;
	
	BOOL m_applicationReady;
}
@property( nonatomic, assign ) id<ORMMAViewDelegate> ormmaDelegate;
@property( nonatomic, copy ) NSString *htmlStub;
@property( nonatomic, copy ) NSURL *creativeURL;
@property( nonatomic, retain, readonly ) NSError *lastError;
@property( nonatomic, assign, readonly ) ORMMAViewState currentState;


- (void)loadCreative:(NSURL *)url;

- (void)loadHTMLCreative:(NSString *)htmlFragment
			 creativeURL:(NSURL *)url;


// used to force an ad to revert to its default state
- (void)restoreToDefaultState;

@end




@protocol ORMMAViewDelegate <NSObject>

@required

// retrieves the owning view controller
- (UIViewController *)parentViewController;


@optional

// called when an ad fails to load
- (void)adFailedToLoad:(ORMMAView *)adView;

// Called just before to an ad is displayed
- (void)adWillShow:(ORMMAView *)adView
		 isDefault:(BOOL)defaultAd;

// Called just after to an ad is displayed
- (void)adDidShow:(ORMMAView *)adView
		isDefault:(BOOL)defaultAd;

// Called just before to an ad is Hidden
- (void)adWillHide:(ORMMAView *)adView
		 isDefault:(BOOL)defaultAd;

// Called just after to an ad is Hidden
- (void)adDidHide:(ORMMAView *)adView
		isDefault:(BOOL)defaultAd;

// Called just before to an ad expanding
- (void)adWillExpand:(ORMMAView *)adView;

// Called just after to an ad expanding
- (void)adDidExpand:(ORMMAView *)adView;

// Called just before an ad closes
- (void)adWillClose:(ORMMAView *)adView;

// Called just after an ad closes
- (void)adDidClose:(ORMMAView *)adView;

// called when the ad will begin heavy content (usually when the ad goes full screen)
- (void)appWillSuspendForAd:(ORMMAView *)adView;

// called when the ad is finished with it's heavy content (usually when the ad returns from full screen)
- (void)appWillResumeFromAd:(ORMMAView *)adView;

@end
