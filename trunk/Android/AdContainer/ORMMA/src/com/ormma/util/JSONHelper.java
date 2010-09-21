package com.ormma.util;

import java.lang.reflect.Field;
import java.lang.reflect.Type;

import org.json.JSONException;
import org.json.JSONObject;

public class JSONHelper {
	
	private static final String STRING_TYPE = "class java.lang.String";
	private static final String INT_TYPE = "int";
	private static final String LONG_TYPE = "long";
	private static final String BOOLEAN_TYPE = "boolean";

	
	private static final String DIMENSION_KEY_TOP = "top";
	private static final String DIMENSION_KEY_LEFT = "left";
	private static final String DIMENSION_KEY_RIGHT = "right";
	private static final String DIMENSION_KEY_BOTTOM = "bottom";
	
	public static class Dimensions{
		public int top, left, bottom, right;
	}
	
	
	public static Object getFromJSON(JSONObject json, Class<?> c) throws IllegalAccessException, InstantiationException, JSONException {
		Field[] fields = null;
		fields = c.getFields();
		Object obj = c.newInstance() ;
				
		for (int i = 0; i < fields.length; i++) {
			Field f = fields[i];
			String name = f.getName();
			Type type = f.getType();
			String typeStr = type.toString();
			if (typeStr.equals(INT_TYPE)) {
				int value = json.getInt(name); 
				f.set(obj, value);
			} else if (typeStr.equals(STRING_TYPE)) {
				String value = json.getString(name);
				f.set(obj, value);
			}
			else if (typeStr.equals(BOOLEAN_TYPE)) {
				boolean value = json.getBoolean(name);
				f.set(obj, value);
			}
			
		}
		return obj;
	}
	
	public static class Properties{
		public int transition;
	}
}
