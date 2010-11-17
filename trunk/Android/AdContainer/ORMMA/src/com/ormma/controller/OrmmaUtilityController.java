package com.ormma.controller;

import java.util.HashMap;

import android.app.Activity;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.telephony.SmsManager;
import android.text.TextUtils;
import android.util.Log;

import com.ormma.view.OrmmaView;

public class OrmmaUtilityController extends OrmmaController {

	static HashMap<String, Boolean> mFeatureMap = null;

	public OrmmaUtilityController(OrmmaView adView, Context context) {
		super(adView, context);
		setFeatureMap();
	}

	private synchronized void setFeatureMap() {
		if (mFeatureMap == null) {
			mFeatureMap = new HashMap<String, Boolean>();

			mFeatureMap.put("network", true);
			mFeatureMap.put("orientation", true);
			mFeatureMap.put("screen", true);
			boolean p = (mContext.checkCallingOrSelfPermission(android.Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED)
					|| (mContext.checkCallingOrSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED);
			mFeatureMap.put("heading", p);
			mFeatureMap.put("location", p);
			p = mContext.checkCallingOrSelfPermission(android.Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED;
			mFeatureMap.put("sms", p);
			p = mContext.checkCallingOrSelfPermission(android.Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED;
			mFeatureMap.put("phone", p);
			p = ((mContext.checkCallingOrSelfPermission(android.Manifest.permission.WRITE_CALENDAR) == PackageManager.PERMISSION_GRANTED) &&
				(mContext.checkCallingOrSelfPermission(android.Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED));
			mFeatureMap.put("calendar", p);

			//p = mContext.checkCallingOrSelfPermission(android.Manifest.permission.) == PackageManager.PERMISSION_GRANTED;
			mFeatureMap.put("email", true);

		}

	}

	public boolean supports(String feature) {
		return mFeatureMap.get(feature);
	}

	public void ready() {
		mOrmmaView.injectJavaScript("Ormma.setState(\"" + mOrmmaView.getState() + "\");");
		mOrmmaView.injectJavaScript("ORMMAReady()");
	}

	public void sendSMS(String recipient, String body) {
		if (supports("sms")) {
			SmsManager sms = SmsManager.getDefault();
			sms.sendTextMessage(recipient, null, body, null, null);
		} else {
			mOrmmaView.injectJavaScript("Ormma.fireError(\"sendSMS\",\"SMS not available\")");
		}

	}

	public void sendMail(String recipient, String subject, String body) {
		if (supports("email")) {

			Intent i = new Intent(Intent.ACTION_SEND);
			i.setType("plain/text");
			i.putExtra(android.content.Intent.EXTRA_EMAIL, new String[]{ recipient});
			i.putExtra(android.content.Intent.EXTRA_SUBJECT, subject);
			i.putExtra(android.content.Intent.EXTRA_TEXT, body);
			mContext.startActivity(i);
		} else {
			mOrmmaView.injectJavaScript("Ormma.fireError(\"sendMail\",\"Email not available\")");
		}
	}

	private String createTelUrl(String number) {
		if (TextUtils.isEmpty(number)) {
			return null;
		}

		StringBuilder buf = new StringBuilder("tel:");
		buf.append(number);
		return buf.toString();
	}

	public void makeCall(String number) {
		if (supports("phone")) {

			String url = createTelUrl(number);
			if (url == null) {
				mOrmmaView.injectJavaScript("Ormma.fireError(\"makeCall\",\"Bad Phone Number\")");
			}
			Intent i = new Intent(Intent.ACTION_CALL, Uri.parse(url.toString()));
			mContext.startActivity(i);
		} else {
			mOrmmaView.injectJavaScript("Ormma.fireError(\"makeCall\",\"CALLS not available\")");
		}

	}

	public void createEvent(String date, String title, String body) {
		if (supports("calendar")) {
			String[] projection = new String[] { "_id", "name" };
			Uri calendars = Uri.parse("content://calendar/calendars");
			     
			Cursor managedCursor =
			   ((Activity)mContext).managedQuery(calendars, projection,
			   "selected=1", null, null);
//			 String calName; 
			 String calId; 

			if (managedCursor!= null && managedCursor.moveToFirst()) {
//				 int nameColumn = managedCursor.getColumnIndex("name"); 
				 int idColumn = managedCursor.getColumnIndex("_id");
//				    calName = managedCursor.getString(nameColumn);
				    calId = managedCursor.getString(idColumn);
				}
			else {
				mOrmmaView.injectJavaScript("Ormma.fireError(\"createEvent\",\"Could not find a local calendar\")");
				return;
			}
			ContentValues event = new ContentValues();
			event.put("calendar_id", calId);
//			event.put("title", title);
//			event.put("description", body);
//			Long ldate = Long.parseLong(date);
//			event.put("dtstart", ldate);
			event.put("calendar_id", calId);
			event.put("title", "Event Title");
			event.put("description", "Event Desc");
			event.put("eventLocation", "Event Location");
			long startTime = System.currentTimeMillis()+1000*60*60*10;
			long endTime = System.currentTimeMillis()+1000*60*60*20;
			event.put("dtstart", startTime);
			event.put("dtend", endTime);
			
			
			Uri eventsUri = Uri.parse("content://calendar/events");
		    mContext.getContentResolver().insert(eventsUri, event);
		    Log.d("xxx","made event!");
//				mOrmmaView.injectJavaScript("Ormma.fireError(\"createEvent\",\"Could not parse date\")");
			
		} else {
			mOrmmaView.injectJavaScript("Ormma.fireError(\"createEvent\",\"Calendar not available\")");
		}

	}
	
	
	
}
