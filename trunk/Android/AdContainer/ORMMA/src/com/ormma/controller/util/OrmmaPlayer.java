package com.ormma.controller.util;

import android.content.Context;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.MediaPlayer.OnCompletionListener;
import android.media.MediaPlayer.OnErrorListener;
import android.media.MediaPlayer.OnPreparedListener;
import android.net.Uri;
import android.view.ViewGroup;
import android.widget.MediaController;
import android.widget.VideoView;

import com.ormma.controller.OrmmaController.PlayerProperties;

/**
 * 
 * Player class to play audio and video
 *
 */

public class OrmmaPlayer extends VideoView implements OnCompletionListener, OnErrorListener, OnPreparedListener {

	private PlayerProperties playProperties;
	private Context ctx;
	private AudioManager aManager;
	private OrmmaPlayerListener listener;
	private int mutedVolume;
	/**
	 * 
	 * @param context - Current context
	 * @param properties - player properties
	 */
	public OrmmaPlayer(Context context, PlayerProperties properties) {
		super(context);
		ctx = context;
		playProperties = properties;
		aManager = (AudioManager) ctx.getSystemService(Context.AUDIO_SERVICE);
	}

	/**
	 * Play audio
	 * @param url - audio url
	 */
	public void playAudio(String url) {
		loadContent(url);
	}

	/**
	 * Show player control
	 */
	void displayControl() {
		
		if (playProperties.showControl())
			setMediaController(new MediaController(ctx));
	}
	
	/**
	 * Load audio/video content
	 * @param url - audio/video url
	 */
	void loadContent(String url){
		
		url = url.trim();
		
		url = OrmmaUtils.convert(url);
		if(url == null && listener != null){
			removeView();
			listener.onError();
			return;
		}
		
		setVideoURI(Uri.parse(url));
		displayControl();
		startContent();
	}

	/**
	 * Play start
	 */
	void startContent() {
		
		setOnCompletionListener(this);
		setOnErrorListener(this);
		setOnPreparedListener(this);
		
		if (playProperties.isAutoPlay())
			start();
	}

	/**
	 * Play video
	 * @param url - video url
	 */
	public void playVideo(String url) {	

		if (playProperties.doMute()) {
			mutedVolume = aManager.getStreamVolume(AudioManager.STREAM_MUSIC);
			aManager.setStreamMute(AudioManager.STREAM_MUSIC, true);
		}
		loadContent(url);
	}

	/**
	 * Unmute audio
	 */
	void unMute() {
		aManager.setStreamMute(AudioManager.STREAM_MUSIC, false);
		aManager.setStreamVolume(AudioManager.STREAM_MUSIC, mutedVolume, AudioManager.FLAG_PLAY_SOUND);
	}

	/**
	 * Set callback listener
	 * @param listener - callback listener
	 */
	public void setListener(OrmmaPlayerListener listener) {
		this.listener = listener;
	}

	@Override
	public void onCompletion(MediaPlayer mp) {
		if (playProperties.doLoop())
			start();
		else if (playProperties.exitOnComplete()) {
			
			mp.stop();
			removeView();
			if (playProperties.doMute())
				unMute();
			if (listener != null)
				listener.onComplete();
		}
	}
	
	@Override
	public boolean onError(MediaPlayer mp, int what, int extra) {		
		removeView();
		if(listener != null)
			listener.onError();
		return false;
	}

	@Override
	public void onPrepared(MediaPlayer mp) {
		if(listener != null)
			listener.onPrepared();
		}		

	/**
	 * Remove player from parent
	 */
	void removeView(){
		ViewGroup parent = (ViewGroup) getParent();
		parent.removeView(this);
	}
}
