/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "ORMMAAVPlayer.h"
#include <objc/runtime.h>

@implementation ORMMAAVPlayer
@synthesize delegate;
@synthesize ormmaPlayer;

-(void)playAudio:(NSURL *)audioURL attachTo:(UIView*)parentView autoPlay:(BOOL)autoplay showControls:(BOOL)showcontrols repeat:(BOOL)autorepeat playInline:(BOOL)Inline fullScreenMode:(BOOL)isFullScreen autoExit:(BOOL)exit
{
	playingAudio = YES;
	oldStyle = [UIApplication sharedApplication].statusBarStyle;
	self.backgroundColor = [UIColor blackColor];

	
	if ([self.ormmaPlayer respondsToSelector:@selector(loadState)]) 
	{
		is3XDevice = NO;
		avPlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:audioURL];
		self.ormmaPlayer = avPlayer.moviePlayer;
		
		self.ormmaPlayer.controlStyle = showcontrols ? MPMovieControlStyleFullscreen : MPMovieControlStyleNone;
		self.ormmaPlayer.repeatMode = autorepeat ? MPMovieRepeatModeOne : MPMovieRepeatModeNone;	
		self.ormmaPlayer.shouldAutoplay = autoplay;
		self.ormmaPlayer.view.frame = [self bounds];
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(moviePlayerLoadStateChanged:) 
													 name:MPMoviePlayerLoadStateDidChangeNotification 
												   object:nil];		
		[self.ormmaPlayer prepareToPlay];
	}
	else 
	{
		is3XDevice = YES;
		self.ormmaPlayer = [[MPMoviePlayerController alloc] initWithContentURL:audioURL];
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(moviePreloadDidFinish:) 
													 name:MPMoviePlayerContentPreloadDidFinishNotification 
												   object:nil];
		
		self.ormmaPlayer.movieControlMode = showcontrols ? MPMovieControlModeDefault : MPMovieControlModeHidden; 	
		self.ormmaPlayer.backgroundColor	= [UIColor blackColor];	
		
		m_playerViewController = nil;
		id internal;
		object_getInstanceVariable(self.ormmaPlayer, "_internal", (void**)&internal);
		object_getInstanceVariable(internal, "_videoViewController", (void**)&m_playerViewController);
		m_playerViewController.view.frame = [self bounds];
	}


	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(moviePlayBackDidFinish:) 
												 name:MPMoviePlayerPlaybackDidFinishNotification 
											   object:nil];
	
	

	
	
	
	autoPlay = autoplay;
	exitOnComplete = exit;
	inlinePlayer = Inline;
}

-(void)playVideo:(NSURL *)videoURL attachTo:(UIView*)parentView autoPlay:(BOOL)autoplay showControls:(BOOL)showcontrols repeat:(BOOL)autorepeat fullScreenMode:(BOOL)isFullScreen autoExit:(BOOL)exit
{
	playingAudio = NO;
	oldStyle = [UIApplication sharedApplication].statusBarStyle;
	inlinePlayer = NO;
	self.backgroundColor = [UIColor blackColor];
	ormmaPlayer = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
	ormmaPlayer.scalingMode = MPMovieScalingModeAspectFit;

	if ([ormmaPlayer respondsToSelector:@selector(loadState)]) 
	{
		is3XDevice = NO;
		
		ormmaPlayer.controlStyle = showcontrols ? MPMovieControlStyleFullscreen : MPMovieControlStyleNone;
		ormmaPlayer.repeatMode = autorepeat ? MPMovieRepeatModeOne : MPMovieRepeatModeNone;	
		ormmaPlayer.shouldAutoplay = autoplay;
		ormmaPlayer.view.frame = [self bounds];
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(moviePlayerLoadStateChanged:) 
													 name:MPMoviePlayerLoadStateDidChangeNotification 
												   object:nil];	
		[ormmaPlayer prepareToPlay];
	}
	else 
	{
		is3XDevice = YES;
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(moviePreloadDidFinish:) 
													 name:MPMoviePlayerContentPreloadDidFinishNotification 
												   object:nil];
		
		ormmaPlayer.movieControlMode = showcontrols ? MPMovieControlModeDefault : MPMovieControlModeHidden; 	
		ormmaPlayer.backgroundColor	= [UIColor blackColor];	
		
		m_playerViewController = nil;
		id internal;
		object_getInstanceVariable(self.ormmaPlayer, "_internal", (void**)&internal);
		object_getInstanceVariable(internal, "_videoViewController", (void**)&m_playerViewController);
	}

	
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(moviePlayBackDidFinish:) 
												 name:MPMoviePlayerPlaybackDidFinishNotification 
											   object:nil];
	
	

	autoPlay = autoplay;
	exitOnComplete = exit;
}

- (void) moviePreloadDidFinish:(NSNotification*)notification 
{
	// Remove observer
	[[NSNotificationCenter 	defaultCenter] removeObserver:self
											name:MPMoviePlayerContentPreloadDidFinishNotification
											object:nil];
	
	// Play the movie
	[ormmaPlayer play];	//we have to start play ... auto play is not supported
	
	if (!inlinePlayer) 
	{
		UIWindow* window = [[UIApplication sharedApplication] keyWindow];
		[window addSubview:m_playerViewController.view];	
		[window bringSubviewToFront:m_playerViewController.view];						
	}
	
}

- (void) moviePlayerLoadStateChanged:(NSNotification*)notification 
{
	if ([ormmaPlayer loadState] != MPMovieLoadStateUnknown)
	{
		[[NSNotificationCenter 	defaultCenter] removeObserver:self 
														 name:MPMoviePlayerLoadStateDidChangeNotification 
													   object:nil];
		
		if (autoPlay) 
		{
			// Play the movie
			[ormmaPlayer play];			
		}

		if (!inlinePlayer) 
		{
			UIWindow* window = [[UIApplication sharedApplication] keyWindow];
			[window addSubview:ormmaPlayer.view];	
			[window bringSubviewToFront:ormmaPlayer.view];			
		}
	}
	else 
	{
		NSLog(@"Player received unknown error");
	}
}

- (void) moviePlayBackDidFinish:(NSNotification*)notification
{
	if ([ormmaPlayer respondsToSelector:@selector(loadState)]) 
	{
		NSDictionary* userinfo = [notification userInfo];
		NSLog(@"%@",userinfo);
		NSNumber* status = [userinfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
		if ([status intValue] == MPMovieFinishReasonUserExited || (exitOnComplete && [status intValue] == MPMovieFinishReasonPlaybackEnded)) 
		{
			[[NSNotificationCenter defaultCenter] removeObserver:self
															name:MPMoviePlayerPlaybackDidFinishNotification
														  object:nil];		
			
			[ormmaPlayer stop];
			if (!inlinePlayer) 
			{
				[ormmaPlayer.view removeFromSuperview];			
			}
			
			[ormmaPlayer release];
			ormmaPlayer = nil;
			[[UIApplication sharedApplication] setStatusBarStyle:oldStyle];
			if(self.delegate)
			{
				[self.delegate playerCompleted];
			}
		}
	}
	else {
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:MPMoviePlayerPlaybackDidFinishNotification
													  object:nil];		
		
		if (playingAudio) 
		{
			if (!inlinePlayer) 	
			{
				[m_playerViewController.view removeFromSuperview];			
			}
		}
		else 
		{
			[m_playerViewController.view removeFromSuperview];			
		}

		[ormmaPlayer stop];
		[ormmaPlayer release];
		ormmaPlayer = nil;
		[[UIApplication sharedApplication] setStatusBarStyle:oldStyle];		
		if(self.delegate)
		{
			[self.delegate playerCompleted];
		}			
	}

}

- (void)dealloc {		
	if (avPlayer) 
	{
		[avPlayer release];
		avPlayer = nil;		
	}
    [super dealloc];
}

@end
