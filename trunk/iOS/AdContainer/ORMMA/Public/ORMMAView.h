//
//  TWCRichAdView.h
//  RichMediaAds
//
//  Created by Robert Hedin on 9/7/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import <UIKit/UIKit.h>


@class DeferredObjectSelector;
@class ORMMAJavascriptBridge;
@class FileSystemCache;

@protocol ORMMAViewDelegate;
@protocol ORMMAJavascriptBridgeDelegate;



typedef enum ORMMAViewStateEnum
{
	ORMMAViewStateDefault = 0,
	ORMMAViewStateResized,
	ORMMAViewStateFullScreen
} ORMMAViewState;



@interface ORMMAView : UIView
{
@private
	UIWebView *m_webView;
//	UIWebView *m_resizedWebView;
	CGRect m_finalFrame;
	UIButton *m_blockingView;
	id<ORMMAViewDelegate> m_ormmaDelegate;
	
	ORMMAViewState m_currentState;
	
	NSString *m_htmlStub;
	
	CGRect m_unexpandedFrame;
	UIView *m_originalParentView;
	
	BOOL m_adVisible;
	
	DeferredObjectSelector *m_deferredShowAnimationSelector;
	DeferredObjectSelector *m_deferredHideAnimationSelector;
	
	ORMMAJavascriptBridge *m_javascriptBridge;
	
	UIDevice *m_currentDevice;
	
	FileSystemCache *m_cache;
	
	NSError *m_lastError;
	
	NSInteger m_originalParentTag;
	NSInteger m_parentTag;
	CGRect m_originalFrame;
}
@property( nonatomic, assign ) id<ORMMAViewDelegate> ormmaDelegate;
@property( nonatomic, copy ) NSString *htmlStub;
@property( nonatomic, retain, readonly ) NSError *lastError;
@property( nonatomic, assign, readonly ) ORMMAViewState currentState;


- (void)loadAd:(NSURL *)url;

- (void)loadHTMLAd:(NSString *)htmlFragment
		   baseURL:(NSURL *)baseURL;


// used to force an ad to revert to its default state
- (void)restoreToDefaultState;

@end




@protocol ORMMAViewDelegate <NSObject>

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
