package com.ormma.controller;

import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.util.DisplayMetrics;
import android.view.Surface;
import android.view.View;
import android.view.WindowManager;

import com.ormma.view.OrmmaView;

public class OrmmaDisplayController extends OrmmaController{

	
	private WindowManager mWindowManager;

	public OrmmaDisplayController(OrmmaView adView, Context c) {
		super(adView, c);
		mWindowManager = (WindowManager) c.getSystemService(Context.WINDOW_SERVICE);
	}

	public void resize(String dimensions, String properties) {
		try {
			try {
				mOrmmaView.resize((Dimensions) getFromJSON(new JSONObject(dimensions), Dimensions.class),
						(Properties) getFromJSON(new JSONObject(properties), Properties.class));
			} catch (IllegalAccessException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (InstantiationException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		} catch (JSONException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (NumberFormatException e) {
			e.printStackTrace();
		} catch (NullPointerException e) {
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
		return "{ \"top\" :" + mOrmmaView.getTop() + "," + "\"left\" :" + mOrmmaView.getLeft() + "," + "\"bottom\" :"
				+ mOrmmaView.getBottom() + "," + "\"right\" :" + mOrmmaView.getRight() + "}";
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
	
}
