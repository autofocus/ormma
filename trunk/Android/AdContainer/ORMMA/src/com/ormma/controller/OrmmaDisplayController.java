package com.ormma.controller;

import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.Uri;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Surface;
import android.view.View;
import android.view.WindowManager;

import com.ormma.controller.util.OrmmaConfigurationBroadcastReceiver;
import com.ormma.view.OrmmaView;

public class OrmmaDisplayController extends OrmmaController {

	private WindowManager mWindowManager;
	private boolean bMaxSizeSet = false;
	private int mMaxWidth = -1;
	private int mMaxHeight = -1;
	private OrmmaConfigurationBroadcastReceiver mBroadCastReceiver;
	private IntentFilter mFilter;
	private int mOrientationListenerCount = 0;
	private float mDensity;

	public OrmmaDisplayController(OrmmaView adView, Context c) {
		super(adView, c);
		DisplayMetrics metrics = new DisplayMetrics();
		((Activity) mContext).getWindowManager().getDefaultDisplay().getMetrics(metrics);
		mDensity = metrics.density;
		mWindowManager = (WindowManager) c.getSystemService(Context.WINDOW_SERVICE);
	}

	public void resize(int width, int height) {
		Log.d("xxx", "resize:"+width+","+height+","+mDensity);
		if (((mMaxHeight > 0) && (height > mMaxHeight)) || ((mMaxWidth > 0) && (width > mMaxWidth))) {
			mOrmmaView.injectJavaScript("OrmmaAdController.fireError(\"Maximum size exceeded\", \"resize\")");
		} else
			mOrmmaView.resize((int)(mDensity*width), (int)(mDensity*height));

	}

	public void open(String url) {
		Intent i = new Intent(Intent.ACTION_VIEW, Uri.parse(url.toString()));
		mContext.startActivity(i);
	}

	public void expand(String dimensions, String URL, String properties) {

		try {
			Dimensions d = (Dimensions) getFromJSON(new JSONObject(dimensions), Dimensions.class);
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
			
			mOrmmaView.expand(d, URL, (Properties) getFromJSON(new JSONObject(properties), Properties.class));
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

	public void close() {
		mOrmmaView.close();
	}

	public void hide() {
		mOrmmaView.hide();
	}

	public void show() {
		mOrmmaView.show();
	}

	public boolean isVisible() {
		return (mOrmmaView.getVisibility() == View.VISIBLE);
	}

	public String dimensions() {
		return "{ \"top\" :" + mOrmmaView.getTop()*mDensity + "," + "\"left\" :" + mOrmmaView.getLeft()*mDensity + "," + "\"bottom\" :"
				+ mOrmmaView.getBottom()*mDensity + "," + "\"right\" :" + mOrmmaView.getRight()*mDensity + "}";
	}

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

	public String getScreenSize() {
		DisplayMetrics metrics = new DisplayMetrics();
		mWindowManager.getDefaultDisplay().getMetrics(metrics);

		return "{ \"width\": " + metrics.widthPixels + ", " + "\"height\": " + metrics.heightPixels + "}";
	}

	public String getSize() {
		return "{ \"width\": " + mOrmmaView.getWidth()*mDensity + ", " + "\"height\": " + mOrmmaView.getHeight()*mDensity + "}";
	}

	public String getMaxSize() {
		if (bMaxSizeSet)
			return "{ \"width\": " + mMaxWidth + ", " + "\"height\": " + mMaxHeight + "}";
		else
			return getScreenSize();
	}

	public void setMaxSize(int w, int h) {
		bMaxSizeSet = true;
		mMaxWidth = w;
		mMaxHeight = h;
	}

	public void startOrientationListener() {
		if (mOrientationListenerCount == 0) {
			mBroadCastReceiver = new OrmmaConfigurationBroadcastReceiver(this);
			mFilter = new IntentFilter();
			mFilter.addAction(Intent.ACTION_CONFIGURATION_CHANGED);
		}
		mOrientationListenerCount++;
		mContext.registerReceiver(mBroadCastReceiver, mFilter);
	}

	public void stopOrientationListener() {
		mOrientationListenerCount--;
		if (mOrientationListenerCount == 0){			
			mContext.unregisterReceiver(mBroadCastReceiver);
			mBroadCastReceiver = null;
			mFilter = null;
		}
	}

	public void onOrientationChanged(int orientation) {
		mOrmmaView.injectJavaScript("Ormma.gotOrientationChange(" + orientation + ")");

	}
}
