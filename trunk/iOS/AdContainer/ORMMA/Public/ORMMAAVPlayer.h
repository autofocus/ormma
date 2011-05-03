/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@protocol ORMMAAVPlayerDelegate
-(void)playerCompleted;
@end

@interface ORMMAAVPlayer : UIView {
	MPMoviePlayerViewController *avPlayer;
	MPMoviePlayerController* ormmaPlayer;
	BOOL statusBarHidden;
	UIStatusBarStyle oldStyle;
	id delegate;
	BOOL exitOnComplete;
	BOOL autoPlay;
	BOOL inlinePlayer;    
	
	BOOL playingAudio;
	BOOL is3XDevice;
	UIViewController *m_playerViewController;
}
@property(nonatomic, retain) id<ORMMAAVPlayerDelegate> delegate;
@property(nonatomic, retain) MPMoviePlayerController* ormmaPlayer;

-(void)playVideo:(NSURL *)videoURL attachTo:(UIView*)parentView autoPlay:(BOOL)autoplay showControls:(BOOL)showcontrols repeat:(BOOL)autorepeat fullScreenMode:(BOOL)isFullScreen autoExit:(BOOL)exit;

-(void)playAudio:(NSURL *)audioURL attachTo:(UIView*)parentView autoPlay:(BOOL)autoplay showControls:(BOOL)showcontrols repeat:(BOOL)autorepeat playInline:(BOOL)Inline fullScreenMode:(BOOL)isFullScreen autoExit:(BOOL)exit;

@end
