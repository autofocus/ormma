package com.ormma.controller;


import android.content.Context;

import com.ormma.controller.listeners.AccelListener;
import com.ormma.view.OrmmaView;

public class OrmmaSensorController extends OrmmaController{

	final int INTERVAL = 1000;
	
	private AccelListener mAccel;

	private float mLastX = 0;

	private float mLastY = 0;

	private float mLastZ = 0;

	public OrmmaSensorController(OrmmaView adView, Context context) {
		super(adView, context);
		mAccel = new AccelListener(context, this);
	}

	public void startTiltListener(){
		mAccel.startTrackingTilt();
	}

	public void startShakeListener(){
		mAccel.startTrackingShake();
	}

	
	public void stopTiltListener(){
		mAccel.stopTrackingTilt();
	}

	public void stopShakeListener(){
		mAccel.stopTrackingShake();
	}

	public void startHeadingListener(){
		mAccel.startTrackingHeading();
	}

	public void stopHeadingListener(){
		mAccel.stopTrackingHeading();
	}

	
	
	void stop()
	{
	}

	public void onShake(){
		mOrmmaView.injectJavaScript("Ormma.gotShake()");		
	}
	
	public void onTilt(float x, float y, float z){
		mLastX = x;
		mLastY = y;
		mLastZ = z;	

		mOrmmaView.injectJavaScript("Ormma.gotTiltChange({ x : \"" + mLastX + "\", y : \"" + mLastY + "\", z : \"" + mLastZ + "\"})");

	}
	
	public String getTilt(){
		return ("{ x : \"" + mLastX + "\", y : \"" + mLastY + "\", z : \"" + mLastZ + "\"}");
	}

	public void onHeadingChange(float f) {
		mOrmmaView.injectJavaScript("Ormma.gotHeadingChange("+ (int)(f * (180/Math.PI)) +")");
	}
	
	public float getHeading(){
		return mAccel.getHeading();
	}
}
