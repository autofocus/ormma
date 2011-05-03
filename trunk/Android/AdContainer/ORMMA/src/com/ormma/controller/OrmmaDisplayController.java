/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */
package com.ormma.controller;

import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Surface;
import android.view.View;
import android.view.WindowManager;

import com.ormma.controller.util.OrmmaConfigurationBroadcastReceiver;
import com.ormma.view.OrmmaView;

/**
 * The Class OrmmaDisplayController.  A ormma controller for handling display related operations
 */
public class OrmmaDisplayController extends OrmmaController {

	//tag for logging
	private static final String LOG_TAG = "OrmmaDisplayController";
	
	private WindowManager mWindowManager;
	private boolean bMaxSizeSet = false;
	private int mMaxWidth = -1;
	private int mMaxHeight = -1;
	private OrmmaConfigurationBroadcastReceiver mBroadCastReceiver;
	private float mDensity;
	
	/**
	 * Instantiates a new ormma display controller.
	 *
	 * @param adView the ad view
	 * @param c the context
	 */
	public OrmmaDisplayController(OrmmaView adView, Context c) {
		super(adView, c);
		DisplayMetrics metrics = new DisplayMetrics();
		mWindowManager = (WindowManager) c.getSystemService(Context.WINDOW_SERVICE);
		mWindowManager.getDefaultDisplay().getMetrics(metrics);
		mDensity = metrics.density;

	}

	/**
	 * Resize the view.
	 *
	 * @param width the width
	 * @param height the height
	 */
	public void resize(int width, int height) {
		if (((mMaxHeight > 0) && (height > mMaxHeight)) || ((mMaxWidth > 0) && (width > mMaxWidth))) {
			mOrmmaView.injectJavaScript("OrmmaAdController.fireError(\"Maximum size exceeded\", \"resize\")");
		} else
			mOrmmaView.resize((int) (mDensity * width), (int) (mDensity * height));

	}

	/**
	 * Open a browser
	 *
	 * @param url the url
	 * @param back show the back button
	 * @param forward show the forward button
	 * @param refresh show the refresh button
	 */
	public void open(String url, boolean back, boolean forward, boolean refresh) {
		mOrmmaView.open(url, back, forward, refresh);

	}
	
	/**Open map
	 * @param url - map url
	 * @param fullscreen - boolean indicating whether map to be launched in full screen
	 */
	public void openMap(String url, boolean fullscreen) {
		mOrmmaView.openMap(url, fullscreen);
	}
	

	/**
	 * Play audio
	 * @param url - audio url to be played
	 * @param autoPlay - if audio should play immediately
	 * @param controls - should native player controls be visible
	 * @param loop - should video start over again after finishing
	 * @param position - should audio be included with ad content
	 * @param startStyle - normal/full screen (if audio should play in native full screen mode)
	 * @param stopStyle - normal/exit (exit if player should exit after audio stops)
	 */
	public void playAudio(String url, boolean autoPlay, boolean controls, boolean loop, boolean position, String startStyle, String stopStyle) {
		mOrmmaView.playAudio(url, autoPlay, controls, loop, position, startStyle, stopStyle);
	}
	
	
	/**
	 * Play video
	 * @param url - video url to be played
	 * @param audioMuted - should audio be muted
	 * @param autoPlay - should video play immediately
	 * @param controls  - should native player controls be visible
	 * @param loop - should video start over again after finishing
	 * @param position - top and left coordinates of video in pixels if video should play inline
	 * @param startStyle - normal/fullscreen (if video should play in native full screen mode)
	 * @param stopStyle - normal/exit (exit if player should exit after video stops)
	 */
	public void playVideo(String url, boolean audioMuted, boolean autoPlay, boolean controls, boolean loop, int[] position, String startStyle, String stopStyle) {
		Dimensions d = null;
		if(position[0] != -1) {
			d = new Dimensions();
			d.x = position[0];
			d.y = position[1];
			d.width = position[2];
			d.height = position[3];
			d = getDeviceDimensions(d);
		}		
		mOrmmaView.playVideo(url, audioMuted, autoPlay, controls, loop, d, startStyle, stopStyle);
	}

	/**
	 * Get Device dimensions
	 * @param d - dimensions received from java script
	 * @return
	 */
	private Dimensions getDeviceDimensions(Dimensions d){
		d.width *= mDensity;
		d.height *= mDensity;
		d.x *= mDensity;
		d.y *= mDensity;
		if (d.height < 0)
			d.height = mOrmmaView.getHeight();
		if (d.width < 0)
			d.width = mOrmmaView.getWidth();
		int loc[] = new int[2];
		mOrmmaView.getLocationInWindow(loc);
		if (d.x < 0)
			d.x = loc[0];
		if (d.y < 0) {
			int topStuff = 0;// ((Activity)mContext).findViewById(Window.ID_ANDROID_CONTENT).getTop();
			d.y = loc[1] - topStuff;
		}
		return d;
	}
	
	/**
	 * Expand the view
	 *
	 * @param dimensions the dimensions to expand to
	 * @param URL the uRL
	 * @param properties the properties for the expansion
	 */
	public void expand(String dimensions, String URL, String properties) {

		try {
			Dimensions d = (Dimensions) getFromJSON(new JSONObject(dimensions), Dimensions.class);
			mOrmmaView.expand(getDeviceDimensions(d), URL, (Properties) getFromJSON(new JSONObject(properties), Properties.class));
		} catch (NumberFormatException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (NullPointerException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (InstantiationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (JSONException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	/**
	 * Close the view
	 */
	public void close() {
		mOrmmaView.close();
	}

	/**
	 * Hide the view
	 */
	public void hide() {
		mOrmmaView.hide();
	}

	/**
	 * Show the view
	 */
	public void show() {
		mOrmmaView.show();
	}

	/**
	 * Checks if is visible.
	 *
	 * @return true, if is visible
	 */
	public boolean isVisible() {
		return (mOrmmaView.getVisibility() == View.VISIBLE);
	}

	/**
	 * Dimensions.
	 *
	 * @return the string
	 */
	public String dimensions() {
		return "{ \"top\" :" + (int) (mOrmmaView.getTop() / mDensity) + "," + "\"left\" :"
				+ (int) (mOrmmaView.getLeft() / mDensity) + "," + "\"bottom\" :"
				+ (int) (mOrmmaView.getBottom() / mDensity) + "," + "\"right\" :"
				+ (int) (mOrmmaView.getRight() / mDensity) + "}";
	}

	/**
	 * Gets the orientation.
	 *
	 * @return the orientation
	 */
	public int getOrientation() {
		int orientation = mWindowManager.getDefaultDisplay().getOrientation();
		int ret = -1;
		switch (orientation) {
		case Surface.ROTATION_0:
			ret = 0;
			break;

		case Surface.ROTATION_90:
			ret = 90;
			break;

		case Surface.ROTATION_180:
			ret = 180;
			break;

		case Surface.ROTATION_270:
			ret = 270;
			break;
		}
		return ret;
	}

	/**
	 * Gets the screen size.
	 *
	 * @return the screen size
	 */
	public String getScreenSize() {
		DisplayMetrics metrics = new DisplayMetrics();
		mWindowManager.getDefaultDisplay().getMetrics(metrics);

		return "{ width: " + (int) (metrics.widthPixels / metrics.density) + ", " + "height: "
				+ (int) (metrics.heightPixels / metrics.density) + "}";
	}

	/**
	 * Gets the size.
	 *
	 * @return the size
	 */
	public String getSize() {
		return mOrmmaView.getSize();
	}

	/**
	 * Gets the max size.
	 *
	 * @return the max size
	 */
	public String getMaxSize() {
		if (bMaxSizeSet)
			return "{ width: " + mMaxWidth + ", " + "height: " + mMaxHeight + "}";
		else
			return getScreenSize();
	}

	/**
	 * Sets the max size.
	 *
	 * @param w the w
	 * @param h the h
	 */
	public void setMaxSize(int w, int h) {
		bMaxSizeSet = true;
		mMaxWidth = w;
		mMaxHeight = h;
	}

	/**
	 * On orientation changed.
	 *
	 * @param orientation the orientation
	 */
	public void onOrientationChanged(int orientation) {
		String script = "window.ormmaview.fireChangeEvent({ orientation: " + orientation + "});";
		Log.d(LOG_TAG, script );
		mOrmmaView.injectJavaScript(script);
	}

	/**
	 * Log html.
	 *
	 * @param html the html
	 */
	public void logHTML(String html) {
		Log.d(LOG_TAG, html);
	}

	/* (non-Javadoc)
	 * @see com.ormma.controller.OrmmaController#stopAllListeners()
	 */
	@Override
	public void stopAllListeners() {
		stopConfigurationListener();
		mBroadCastReceiver = null;
	}

	public void stopConfigurationListener() {
		try {
			mContext.unregisterReceiver(mBroadCastReceiver);
		} catch (Exception e) {
		}
	}
	
	public void startConfigurationListener() {
		try {
			if(mBroadCastReceiver == null) 
				mBroadCastReceiver = new OrmmaConfigurationBroadcastReceiver(this);
			mContext.registerReceiver(mBroadCastReceiver, new IntentFilter(Intent.ACTION_CONFIGURATION_CHANGED));
		}catch(Exception e) {
		}
	}
}
