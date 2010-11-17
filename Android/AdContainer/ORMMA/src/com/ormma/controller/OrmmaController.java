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

public class OrmmaController {

	protected OrmmaView mOrmmaView;

	private static final String STRING_TYPE = "class java.lang.String";
	private static final String INT_TYPE = "int";
	private static final String BOOLEAN_TYPE = "boolean";
	private static final String FLOAT_TYPE = "float";
	private static final String NAVIGATION_TYPE = "class com.ormma.NavigationStringEnum";
	private static final String TRANSITION_TYPE = "class com.ormma.TransitionStringEnum";

	protected Context mContext;

	public static class Dimensions extends ReflectedParcelable {

		public Dimensions() {
			x = -1;
			y = -1;
			width = -1;
			height = -1;
		};

		public static final Parcelable.Creator<Dimensions> CREATOR = new Parcelable.Creator<Dimensions>() {
			public Dimensions createFromParcel(Parcel in) {
				return new Dimensions(in);
			}

			public Dimensions[] newArray(int size) {
				return new Dimensions[size];
			}
		};

		protected Dimensions(Parcel in) {
			super(in);
			// TODO Auto-generated constructor stub
		}

		public int x, y, width, height;

	}

	public static class Properties extends ReflectedParcelable {
		protected Properties(Parcel in) {
			super(in);
		}

		public Properties() {
			transition = TransitionStringEnum.DEFAULT;
			navigation = NavigationStringEnum.NONE;
			use_background = false;
			background_color = 0;
			background_opacity = 0;
			is_modal = true;
		};

		public static final Parcelable.Creator<Properties> CREATOR = new Parcelable.Creator<Properties>() {
			public Properties createFromParcel(Parcel in) {
				return new Properties(in);
			}

			public Properties[] newArray(int size) {
				return new Properties[size];
			}
		};
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
			} catch (JSONException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

		}
		return obj;
	}

	public static class ReflectedParcelable implements Parcelable {

		public ReflectedParcelable() {

		}

		@Override
		public int describeContents() {
			return 0;
		}

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

}
