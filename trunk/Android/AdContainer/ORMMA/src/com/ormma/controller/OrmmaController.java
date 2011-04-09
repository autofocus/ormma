/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */
package com.ormma.controller;

import java.lang.reflect.Field;
import java.lang.reflect.Type;

import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.os.Parcel;
import android.os.Parcelable;

import com.ormma.controller.util.NavigationStringEnum;
import com.ormma.controller.util.TransitionStringEnum;
import com.ormma.view.OrmmaView;

/**
 * Abstract class fort all controller objects
 * Controller objects implent pieces of the java/javascript interface
 */
public abstract class OrmmaController {

	//view it is attached to
	protected OrmmaView mOrmmaView;
	//context it is in
	protected Context mContext;

	//class types for converting JSON
	private static final String STRING_TYPE = "class java.lang.String";
	private static final String INT_TYPE = "int";
	private static final String BOOLEAN_TYPE = "boolean";
	private static final String FLOAT_TYPE = "float";
	private static final String NAVIGATION_TYPE = "class com.ormma.NavigationStringEnum";
	private static final String TRANSITION_TYPE = "class com.ormma.TransitionStringEnum";


	/**
	 * The Class Dimensions.  Holds dimensions coming from javascript
	 */
	public static class Dimensions extends ReflectedParcelable {

		/**
		 * Instantiates a new dimensions.
		 */
		public Dimensions() {
			x = -1;
			y = -1;
			width = -1;
			height = -1;
		};

		/**
		 * The Constant CREATOR.
		 */
		public static final Parcelable.Creator<Dimensions> CREATOR = new Parcelable.Creator<Dimensions>() {
			public Dimensions createFromParcel(Parcel in) {
				return new Dimensions(in);
			}

			public Dimensions[] newArray(int size) {
				return new Dimensions[size];
			}
		};

		/**
		 * Instantiates a new dimensions from a parcel.
		 *
		 * @param in the in
		 */
		protected Dimensions(Parcel in) {
			super(in);
		}

		/**
		 * The dimenstion values
		 */
		public int x, y, width, height;

	}

	/**
	 * The Class Properties for holding properties coming from javascript
	 */
	public static class Properties extends ReflectedParcelable {
		
		/**
		 * Instantiates a new properties from a parcel
		 *
		 * @param in the in
		 */
		protected Properties(Parcel in) {
			super(in);
		}

		/**
		 * Instantiates a new properties.
		 */
		public Properties() {
			useBackground = false;
			backgroundColor = 0;
			backgroundOpacity = 0;
			isModal = true;
		};

		/**
		 * The Constant CREATOR.
		 */
		public static final Parcelable.Creator<Properties> CREATOR = new Parcelable.Creator<Properties>() {
			public Properties createFromParcel(Parcel in) {
				return new Properties(in);
			}

			public Properties[] newArray(int size) {
				return new Properties[size];
			}
		};
		
		//property values
		public boolean useBackground;
		public int backgroundColor;
		public float backgroundOpacity;
		public boolean isModal;
	}

	/**
	 * Instantiates a new ormma controller.
	 *
	 * @param adView the ad view
	 * @param context the context
	 */
	public OrmmaController(OrmmaView adView, Context context) {
		mOrmmaView = adView;
		mContext = context;
	}

	/**
	 * Constructs an object from json via reflection
	 *
	 * @param json the json
	 * @param c the class to convert into
	 * @return the instance constructed
	 * @throws IllegalAccessException the illegal access exception
	 * @throws InstantiationException the instantiation exception
	 * @throws NumberFormatException the number format exception
	 * @throws NullPointerException the null pointer exception
	 */
	protected static Object getFromJSON(JSONObject json, Class<?> c) throws IllegalAccessException,
			InstantiationException, NumberFormatException, NullPointerException {
		Field[] fields = null;
		fields = c.getFields();
		Object obj = c.newInstance();

		for (int i = 0; i < fields.length; i++) {
			Field f = fields[i];
			String name = f.getName();
			String JSONName = name.replace('_', '-');
			Type type = f.getType();
			String typeStr = type.toString();
			try {
				if (typeStr.equals(INT_TYPE)) {
					String value;
					value = json.getString(JSONName);
					int iVal;
					if (value.startsWith("#")) {
						iVal = Integer.parseInt(value.substring(1), 16);
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
			} catch (JSONException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

		}
		return obj;
	}

	/**
	 * The Class ReflectedParcelable.
	 */
	public static class ReflectedParcelable implements Parcelable {

		/**
		 * Instantiates a new reflected parcelable.
		 */
		public ReflectedParcelable() {

		}

		/* (non-Javadoc)
		 * @see android.os.Parcelable#describeContents()
		 */
		@Override
		public int describeContents() {
			return 0;
		}

		/**
		 * Instantiates a new reflected parcelable.
		 *
		 * @param in the in
		 */
		protected ReflectedParcelable(Parcel in) {
			Field[] fields = null;
			Class<?> c = this.getClass();
			fields = c.getFields();
			try {
				Object obj = c.newInstance();
				for (int i = 0; i < fields.length; i++) {
					Field f = fields[i];
					Class<?> type = f.getType();
					if (type.isEnum()) {
						String typeStr = type.toString();
						if (typeStr.equals(NAVIGATION_TYPE)) {
							f.set(obj, NavigationStringEnum.fromString(in.readString()));
						} else if (typeStr.equals(TRANSITION_TYPE)) {
							f.set(obj, TransitionStringEnum.fromString(in.readString()));
						}
					} else
						f.set(obj, in.readValue(null));
				}
			} catch (IllegalArgumentException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (IllegalAccessException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (InstantiationException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

		}

		/* (non-Javadoc)
		 * @see android.os.Parcelable#writeToParcel(android.os.Parcel, int)
		 */
		@Override
		public void writeToParcel(Parcel out, int flags) {
			Field[] fields = null;
			Class<?> c = this.getClass();
			fields = c.getFields();
			try {
				for (int i = 0; i < fields.length; i++) {
					Field f = fields[i];
					Class<?> type = f.getType();
					if (type.isEnum()) {
						String typeStr = type.toString();
						if (typeStr.equals(NAVIGATION_TYPE)) {
							out.writeString(((NavigationStringEnum) f.get(this)).getText());
						} else if (typeStr.equals(TRANSITION_TYPE)) {
							out.writeString(((TransitionStringEnum) f.get(this)).getText());
						}
					} else
						out.writeValue(f.get(this));
				}
			} catch (IllegalArgumentException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (IllegalAccessException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

		}
	}

	/**
	 * Stop all listeners.
	 */
	public abstract void stopAllListeners();

}
