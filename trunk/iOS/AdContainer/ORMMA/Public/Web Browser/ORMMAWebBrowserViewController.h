//
//  ORMMAWebBrowserViewController.h
//  ORMMA
//
//  Created by Robert Hedin on 11/4/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import <UIKit/UIKit.h>




@protocol ORMMAWebBrowserViewControllerDelegate;



@interface ORMMAWebBrowserViewController : UIViewController <UIWebViewDelegate>
{
@private
	// the delegate for this browser
	id<ORMMAWebBrowserViewControllerDelegate> m_browserDelegate;
	
	// user interface components
	NSURL *m_url;
	UIWebView *m_webView;
	UIView *m_browserNavigationBar;
	UIButton *m_backButton;
	UIButton *m_forwardButton;
	UIButton *m_refreshButton;
	UIActivityIndicatorView *m_pageLoadingIndicator;
	UIButton *m_closeButton;
}
@property( nonatomic, retain ) IBOutlet UIWebView *webView;
@property( nonatomic, retain ) IBOutlet UIView *browserNavigationBar;
@property( nonatomic, retain ) IBOutlet UIButton *backButton;
@property( nonatomic, retain ) IBOutlet UIButton *forwardButton;
@property( nonatomic, retain ) IBOutlet UIButton *refreshButton;
@property( nonatomic, retain ) IBOutlet UIActivityIndicatorView *pageLoadingIndicator;
@property( nonatomic, retain ) IBOutlet UIButton *closeButton;

// the ORMMA view
@property( nonatomic, assign ) id<ORMMAWebBrowserViewControllerDelegate> browserDelegate;

// the URL to load
@property( nonatomic, copy ) NSURL *URL;

// properties to control the various navigation buttons
@property( nonatomic, assign ) BOOL backButtonEnabled;
@property( nonatomic, assign ) BOOL forwardButtonEnabled;
@property( nonatomic, assign ) BOOL refreshButtonEnabled;
@property( nonatomic, assign ) BOOL closeButtonEnabled;


// returns an auto-released instance of a new controller
+ (ORMMAWebBrowserViewController *)ormmaWebBrowserViewController;


// button actions
- (IBAction)backButtonPressed:(id)sender;
- (IBAction)forwardButtonPressed:(id)sender;
- (IBAction)refreshButtonPressed:(id)sender;
- (IBAction)closeButtonPressed:(id)sender;

@end







@protocol ORMMAWebBrowserViewControllerDelegate <NSObject>

@required
- (void)doneWithBrowser;

@optional
- (BOOL)shouldLoadRequest:(NSURLRequest *)request
			   forBrowser:(ORMMAWebBrowserViewController *)browserController;

@end
