package com.ormma.controller;

import java.io.EOFException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Field;
import java.lang.reflect.Type;
import java.util.Iterator;
import java.util.List;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.location.Location;
import android.location.LocationManager;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.util.DisplayMetrics;
import android.view.Display;
import android.view.Surface;
import android.view.View;
import android.view.WindowManager;

import com.ormma.util.JSONHelper;
import com.ormma.view.OrmmaView;

public class OrmmaController {

	OrmmaView mOrmmaView;

	private LocationManager mLocationManager;
	private ConnectivityManager mConnectivityManager;
	private WindowManager mWindowManager;

	private static final String STRING_TYPE = "class java.lang.String";
	private static final String INT_TYPE = "int";
	private static final String LONG_TYPE = "long";
	private static final String BOOLEAN_TYPE = "boolean";
	private static final String FLOAT_TYPE = "float";
	private static final String NAVIGATION_TYPE = "class com.ormma.NavigationStringEnum";
	private static final String TRANSITION_TYPE = "class com.ormma.TransitionStringEnum";

	public static class Dimensions {
		public int top, left, bottom, right;
	}

	public static class Properties {
		public TransitionStringEnum transition;
		public NavigationStringEnum navigation;
		public boolean use_background;
		public int background_color;
		public float background_opacity;
		public boolean is_modal;
	}

	public OrmmaController(OrmmaView adView) {
		mOrmmaView = adView;
		mLocationManager = adView.getLocationMananger();
		mConnectivityManager = adView.getConnectivityManager();
		mWindowManager = adView.getWindowManager();
	}

	private static Object getFromJSON(JSONObject json, Class<?> c) throws IllegalAccessException,
			InstantiationException, JSONException, NumberFormatException, NullPointerException {
		Field[] fields = null;
		fields = c.getFields();
		Object obj = c.newInstance();

		for (int i = 0; i < fields.length; i++) {
			Field f = fields[i];
			String name = f.getName();
			String JSONName = name.replace('_', '-');
			Type type = f.getType();
			String typeStr = type.toString();
			if (typeStr.equals(INT_TYPE)) {
				String value = json.getString(JSONName);
				int iVal;
				if (value.startsWith("#")) {
					iVal = Integer.parseInt(value.substring(2), 16);
				} else
					iVal = Integer.parseInt(value);

				f.set(obj, iVal);
			} else if (typeStr.equals(STRING_TYPE)) {
				String value = json.getString(JSONName);
				f.set(obj, value);
			} else if (typeStr.equals(BOOLEAN_TYPE)) {
				boolean value = json.getBoolean(JSONName);
				f.set(obj, value);
			} else if (typeStr.equals(FLOAT_TYPE)) {
				float value = Float.parseFloat(json.getString(JSONName));
				f.set(obj, value);
			} else if (typeStr.equals(NAVIGATION_TYPE)) {
				NavigationStringEnum value = NavigationStringEnum.fromString(json.getString(JSONName));
				f.set(obj, value);
			} else if (typeStr.equals(TRANSITION_TYPE)) {
				TransitionStringEnum value = TransitionStringEnum.fromString(json.getString(JSONName));
				f.set(obj, value);
			}

		}
		return obj;
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

	public void addAsset(String alias, String url) {
		HttpEntity entity = getHttpEntity(url);
		try {
			writeToDisk(entity, alias);
			String str = "javascript:OrmmaAdController.addedAsset('" + alias + "' )";
			mOrmmaView.loadUrl(str);
		} catch (Exception e) {
			e.printStackTrace();
		}
		try {
			entity.consumeContent();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	public void removeAsset(String alias) {
		mOrmmaView.removeAsset(alias);
		String str = "javascript:OrmmaAdController.assetRemoved('" + alias + "' )";
		mOrmmaView.loadUrl(str);
	}

	private HttpEntity getHttpEntity(String url)
	/**
	 * get the http entity at a given url
	 */
	{
		HttpEntity entity = null;
		try {
			DefaultHttpClient httpclient = new DefaultHttpClient();
			HttpGet httpget = new HttpGet(url);
			HttpResponse response = httpclient.execute(httpget);
			entity = response.getEntity();
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
		return entity;
	}

	public int cacheRemaining() {
		return mOrmmaView.cacheRemaining();

	}

	private void writeToDisk(HttpEntity entity, String file) throws IllegalStateException, IOException
	/**
	 * writes a HTTP entity to the specified filename and location on disk
	 */
	{
		int i = 0;
		InputStream in = entity.getContent();
		byte buff[] = new byte[1024];
		FileOutputStream out = mOrmmaView.getAssetOutputString(file);
		do {
			int numread = in.read(buff);
			if (numread <= 0)
				break;
			out.write(buff, 0, numread);
			System.out.println("numread" + numread);
			i++;
		} while (true);
		out.flush();
		out.close();
	}

	public int getHeading() {
		List<String> providers = mLocationManager.getProviders(true);
		Iterator<String> provider = providers.iterator();
		Location lastKnown = null;
		int bearing = -1;
		while (provider.hasNext()) {
			lastKnown = mLocationManager.getLastKnownLocation(provider.next());
			if (lastKnown != null) {
				if (lastKnown.hasBearing()) {
					bearing = (int) lastKnown.getBearing();
					break;
				}
			}
		}
		return bearing;
	}

	public String getLocation() {
		List<String> providers = mLocationManager.getProviders(true);
		Iterator<String> provider = providers.iterator();
		Location lastKnown = null;
		while (provider.hasNext()) {
			lastKnown = mLocationManager.getLastKnownLocation(provider.next());
			if (lastKnown != null) {
				break;
			}
		}
		if (lastKnown != null) {
			return "{ \"lat\": " + lastKnown.getLatitude() + ", " + "\"long\": " + lastKnown.getLongitude() + "}";
		} else
			return null;
	}

	public String getNetwork() {
		NetworkInfo ni = mConnectivityManager.getActiveNetworkInfo();

		if (ni == null)
			return "offline";

		switch (ni.getState()) {
		case UNKNOWN:
			return "unknown";
		case DISCONNECTED:
			return "offline";
		default:
			int type = ni.getType();
			if (type == ConnectivityManager.TYPE_MOBILE)
				return "cell";
			if (type == ConnectivityManager.TYPE_WIFI)
				return "wifi";
		}

		return "unknown";
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
	
	public void startLocationListener(){
		mOrmmaView.startLocationListener();
	}
}
