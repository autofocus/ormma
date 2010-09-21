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

import com.ormma.controller.util.NavigationStringEnum;
import com.ormma.controller.util.TransitionStringEnum;
import com.ormma.view.OrmmaView;

public class OrmmaController {

	protected OrmmaView mOrmmaView;

	private LocationManager mLocationManager;

	private static final String STRING_TYPE = "class java.lang.String";
	private static final String INT_TYPE = "int";
	private static final String LONG_TYPE = "long";
	private static final String BOOLEAN_TYPE = "boolean";
	private static final String FLOAT_TYPE = "float";
	private static final String NAVIGATION_TYPE = "class com.ormma.NavigationStringEnum";
	private static final String TRANSITION_TYPE = "class com.ormma.TransitionStringEnum";

	protected Context mContext;
	
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

	public OrmmaController(OrmmaView adView, Context context) {
		mOrmmaView = adView;
		mContext = context;
	}

	protected static Object getFromJSON(JSONObject json, Class<?> c) throws IllegalAccessException,
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






	
}
