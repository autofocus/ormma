/**
 * @author jsodos
 */
package com.ormma.controller;

import android.content.Context;

import com.ormma.controller.listeners.AccelListener;
import com.ormma.view.OrmmaView;

/**
 * The Class OrmmaSensorController.  OrmmaController for interacting with sensors
 */
public class OrmmaSensorController extends OrmmaController {
	final int INTERVAL = 1000;
	private AccelListener mAccel;
	private float mLastX = 0;
	private float mLastY = 0;
	private float mLastZ = 0;

	/**
	 * Instantiates a new ormma sensor controller.
	 *
	 * @param adView the ad view
	 * @param context the context
	 */
	public OrmmaSensorController(OrmmaView adView, Context context) {
		super(adView, context);
		mAccel = new AccelListener(context, this);
	}

	/**
	 * Start tilt listener.
	 */
	public void startTiltListener() {
		mAccel.startTrackingTilt();
	}

	/**
	 * Start shake listener.
	 */
	public void startShakeListener() {
		mAccel.startTrackingShake();
	}

	/**
	 * Stop tilt listener.
	 */
	public void stopTiltListener() {
		mAccel.stopTrackingTilt();
	}

	/**
	 * Stop shake listener.
	 */
	public void stopShakeListener() {
		mAccel.stopTrackingShake();
	}

	/**
	 * Start heading listener.
	 */
	public void startHeadingListener() {
		mAccel.startTrackingHeading();
	}

	/**
	 * Stop heading listener.
	 */
	public void stopHeadingListener() {
		mAccel.stopTrackingHeading();
	}

	/**
	 * Stop.
	 */
	void stop() {
	}

	/**
	 * On shake.
	 */
	public void onShake() {
		mOrmmaView.injectJavaScript("Ormma.gotShake()");
	}

	/**
	 * On tilt.
	 *
	 * @param x the x
	 * @param y the y
	 * @param z the z
	 */
	public void onTilt(float x, float y, float z) {
		mLastX = x;
		mLastY = y;
		mLastZ = z;

		mOrmmaView.injectJavaScript("Ormma.gotTiltChange({ x : \"" + mLastX + "\", y : \"" + mLastY + "\", z : \""
				+ mLastZ + "\"})");

	}

	/**
	 * Gets the tilt.
	 *
	 * @return the tilt
	 */
	public String getTilt() {
		return ("{ x : \"" + mLastX + "\", y : \"" + mLastY + "\", z : \"" + mLastZ + "\"}");
	}

	/**
	 * On heading change.
	 *
	 * @param f the f
	 */
	public void onHeadingChange(float f) {
		mOrmmaView.injectJavaScript("Ormma.gotHeadingChange(" + (int) (f * (180 / Math.PI)) + ")");
	}

	/**
	 * Gets the heading.
	 *
	 * @return the heading
	 */
	public float getHeading() {
		return mAccel.getHeading();
	}

	/* (non-Javadoc)
	 * @see com.ormma.controller.OrmmaController#stopAllListeners()
	 */
	@Override
	public void stopAllListeners() {
		mAccel.stopAllListeners();
	}
}
