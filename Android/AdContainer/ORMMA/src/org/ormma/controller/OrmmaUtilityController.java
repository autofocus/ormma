/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */
package org.ormma.controller;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import android.R;
import android.app.AlertDialog;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.text.TextUtils;
import android.util.Log;
import android.widget.ListAdapter;
import android.widget.SimpleAdapter;
import android.widget.Toast;

import org.ormma.view.OrmmaView;

/**
 * The Class OrmmaUtilityController.  Main ormma controller.  initiates the others.
 */
public class OrmmaUtilityController extends OrmmaController {

	/**
	 * The Constant TAG.
	 */
	private static final String TAG = "OrmmaUtilityController";
	
	//other controllers
	private OrmmaAssetController mAssetController;
	private OrmmaDisplayController mDisplayController;
	private OrmmaLocationController mLocationController;
	private OrmmaNetworkController mNetworkController;
	private OrmmaSensorController mSensorController;

	/**
	 * Instantiates a new ormma utility controller.
	 *
	 * @param adView the ad view
	 * @param context the context
	 */
	public OrmmaUtilityController(OrmmaView adView, Context context) {
		
		super(adView, context);
		
		mAssetController = new OrmmaAssetController(adView, context);
		mDisplayController = new OrmmaDisplayController(adView, context);
		mLocationController = new OrmmaLocationController(adView, context);
		mNetworkController = new OrmmaNetworkController(adView, context);
		mSensorController = new OrmmaSensorController(adView, context);

		adView.addJavascriptInterface(mAssetController, "ORMMAAssetsControllerBridge");
		adView.addJavascriptInterface(mDisplayController, "ORMMADisplayControllerBridge");
		adView.addJavascriptInterface(mLocationController, "ORMMALocationControllerBridge");
		adView.addJavascriptInterface(mNetworkController, "ORMMANetworkControllerBridge");
		adView.addJavascriptInterface(mSensorController, "ORMMASensorControllerBridge");
	}


	/**
	 * Inits the controller.  injects state info
	 *
	 * @param density the density
	 */
	public void init(float density) {
		String injection = "window.ormmaview.fireChangeEvent({ state: \'default\'," + " network: \'"
				+ mNetworkController.getNetwork() + "\'," + " size: " + mDisplayController.getSize() + ","
				+ " maxSize: " + mDisplayController.getMaxSize() + "," + " screenSize: "
				+ mDisplayController.getScreenSize() + "," + " defaultPosition: { x:"
				+ (int) (mOrmmaView.getLeft() / density) + ", y: " + (int) (mOrmmaView.getTop() / density)
				+ ", width: " + (int) (mOrmmaView.getWidth() / density) + ", height: "
				+ (int) (mOrmmaView.getHeight() / density) + " }," + " orientation:"
				+ mDisplayController.getOrientation() + "," + getSupports() + " });";

		mOrmmaView.injectJavaScript(injection);

	}

	/**
	 * Gets the supports object.  Examines application permissions
	 *
	 * @return the supports
	 */
	private String getSupports() {
		String supports = "supports: [ 'level-1', 'level-2', 'screen', 'orientation', 'network'";

		boolean p = mLocationController.allowLocationServices() &&
				((mContext.checkCallingOrSelfPermission(android.Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED)
				|| (mContext.checkCallingOrSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED));
		if (p)
			supports += ", 'location'";
		
		p = mContext.checkCallingOrSelfPermission(android.Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED;
		if (p)
			supports += ", 'sms'";
		
		p = mContext.checkCallingOrSelfPermission(android.Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED;
		if (p)
			supports += ", 'phone'";
		
		p = ((mContext.checkCallingOrSelfPermission(android.Manifest.permission.WRITE_CALENDAR) == PackageManager.PERMISSION_GRANTED) && (mContext
				.checkCallingOrSelfPermission(android.Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED));
		if (p)
			supports += ", 'calendar'";
				
		supports += ", 'video'";
		
		supports += ", 'audio'";

		supports += ", 'map'";
		
		supports += ", 'email' ]";
		return supports;

	}

	/**
	 * Ready.
	 */
	public void ready() {
		mOrmmaView.injectJavaScript("Ormma.setState(\"" + mOrmmaView.getState() + "\");");
		mOrmmaView.injectJavaScript("ORMMAReady();");
	}

	/**
	 * Send an sms.
	 *
	 * @param recipient the recipient
	 * @param body the body
	 */
	public void sendSMS(String recipient, String body) {
		Intent sendIntent = new Intent(Intent.ACTION_VIEW);
		sendIntent.putExtra("address", recipient);
		sendIntent.putExtra("sms_body", body);
		sendIntent.setType("vnd.android-dir/mms-sms");
		sendIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		mContext.startActivity(sendIntent);
	}

	/**
	 * Send an email.
	 *
	 * @param recipient the recipient
	 * @param subject the subject
	 * @param body the body
	 */
	public void sendMail(String recipient, String subject, String body) {
		Intent i = new Intent(Intent.ACTION_SEND);
		i.setType("plain/text");
		i.putExtra(android.content.Intent.EXTRA_EMAIL, new String[] { recipient });
		i.putExtra(android.content.Intent.EXTRA_SUBJECT, subject);
		i.putExtra(android.content.Intent.EXTRA_TEXT, body);
		i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		mContext.startActivity(i);
	}

	/**
	 * Creates the tel url.
	 *
	 * @param number the number
	 * @return the string
	 */
	private String createTelUrl(String number) {
		if (TextUtils.isEmpty(number)) {
			return null;
		}

		StringBuilder buf = new StringBuilder("tel:");
		buf.append(number);
		return buf.toString();
	}

	/**
	 * Make call.
	 *
	 * @param number the number
	 */
	public void makeCall(String number) {
		String url = createTelUrl(number);
		if (url == null) {
			mOrmmaView.injectJavaScript("Ormma.fireError(\"makeCall\",\"Bad Phone Number\")");
		}
		Intent i = new Intent(Intent.ACTION_CALL, Uri.parse(url.toString()));
		i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		mContext.startActivity(i);

	}

	/**
	 * Creates a calendar event.
	 *
	 * @param date the date
	 * @param title the title
	 * @param body the body
	 */
	public void createEvent(final String date, final String title, final String body) {
		final ContentResolver cr = mContext.getContentResolver();
		Cursor cursor;
		final String[] cols = new String[] { "_id", "displayName", "_sync_account" };
		
		if (Integer.parseInt(Build.VERSION.SDK) == 8) // 2.2 or higher
			cursor = cr.query(Uri.parse("content://com.android.calendar/calendars"),
					cols, null, null, null);
		else
			cursor = cr.query(Uri.parse("content://calendar/calendars"), 
					cols, null, null, null);
		
		if (!cursor.moveToFirst()) {
			// No CalendarID found
			cursor.close();
			return;
		}
			
		if(cursor.getCount() == 1){
			addCalendarEvent(cursor.getInt(0), date, title, body);
		}
		else{
			final List<Map<String, String>> entries = new ArrayList<Map<String,String>>();

			for (int i = 0; i < cursor.getCount(); i++) {
				Map<String,String> entry = new HashMap<String, String>();
				entry.put("ID", cursor.getString(0));
				entry.put("NAME", cursor.getString(1));
				entry.put("EMAILID", cursor.getString(2));
				entries.add(entry);
				cursor.moveToNext();
			}

			AlertDialog.Builder builder = new AlertDialog.Builder(mContext);
			builder.setTitle("Choose Calendar");
			ListAdapter adapter = new SimpleAdapter(mContext, 
					entries, 
					android.R.layout.two_line_list_item,
					new String[] {"NAME", "EMAILID"},
					new int[] {R.id.text1, R.id.text2});
			
			
			builder.setSingleChoiceItems(adapter, -1, new DialogInterface.OnClickListener() {
				@Override
				public void onClick(DialogInterface dialog, int which) {
					Map<String, String> entry = entries.get(which);
					addCalendarEvent(Integer.parseInt(entry.get("ID")), date, title, body);
					dialog.cancel();
				}

			});

			builder.create().show();
		}
		cursor.close();
		
	}
	
	/**
	 * Add event into Calendar 
	 * 
	 * @param calendarID the callId
	 * @param date the date
	 * @param title the title
	 * @param body the body
	 */
	private void addCalendarEvent(final int callId, final String date, final String title, final String body) {
		final ContentResolver cr = mContext.getContentResolver();
		long dtStart = Long.parseLong(date);
		long dtEnd = dtStart + 60 * 1000 * 60;
		ContentValues cv = new ContentValues();
		cv.put("calendar_id", callId);
		cv.put("title", title);
		cv.put("description", body);
		cv.put("dtstart", dtStart);
		cv.put("hasAlarm", 1);
		cv.put("dtend", dtEnd);

		Uri newEvent;
		if (Integer.parseInt(Build.VERSION.SDK) == 8)
			newEvent = cr.insert(Uri.parse("content://com.android.calendar/events"), cv);
		else
			newEvent = cr.insert(Uri.parse("content://calendar/events"), cv);

		if (newEvent != null) {
			long id = Long.parseLong(newEvent.getLastPathSegment());
			ContentValues values = new ContentValues();
			values.put("event_id", id);
			values.put("method", 1);
			values.put("minutes", 15); // 15 minutes
			if (Integer.parseInt(Build.VERSION.SDK) == 8)
				cr.insert(Uri.parse("content://com.android.calendar/reminders"), values);
			else
				cr.insert(Uri.parse("content://calendar/reminders"), values);
		}

		Toast.makeText(mContext, "Event added to calendar", Toast.LENGTH_SHORT).show();
	}
	

	/**
	 * Copy text from jar into asset dir.
	 *
	 * @param alias the alias
	 * @param source the source
	 * @return the string
	 */
	public String copyTextFromJarIntoAssetDir(String alias, String source) {
		return mAssetController.copyTextFromJarIntoAssetDir(alias, source);
	}

	/**
	 * Sets the max size.
	 *
	 * @param w the w
	 * @param h the h
	 */
	public void setMaxSize(int w, int h) {
		mDisplayController.setMaxSize(w, h);
	}

	/**
	 * Write to disk wrapping with ormma stuff.
	 *
	 * @param is the iinput stream
	 * @param currentFile the file to write to
	 * @param storeInHashedDirectory store in a directory based on a hash of the input
	 * @param injection and additional javascript to insert
	 * @param bridgePath the path the ormma javascript bridge
	 * @param ormmaPath the ormma javascript
	 * @return the string
	 * @throws IllegalStateException the illegal state exception
	 * @throws IOException Signals that an I/O exception has occurred.
	 */
	public String writeToDiskWrap(InputStream is, String currentFile, boolean storeInHashedDirectory, String injection, String bridgePath,
			String ormmaPath) throws IllegalStateException, IOException {
		return mAssetController.writeToDiskWrap(is, currentFile, storeInHashedDirectory, injection, bridgePath, ormmaPath);
	}

	/**
	 * Activate a listener
	 *
	 * @param event the event
	 */
	public void activate(String event) {
		if (event.equalsIgnoreCase(Defines.Events.NETWORK_CHANGE)) {
			mNetworkController.startNetworkListener();
		}else if (mLocationController.allowLocationServices() && event.equalsIgnoreCase(Defines.Events.LOCATION_CHANGE)) {
			mLocationController.startLocationListener();
		}else if (event.equalsIgnoreCase(Defines.Events.SHAKE)) {
			mSensorController.startShakeListener();
		}else if (event.equalsIgnoreCase(Defines.Events.TILT_CHANGE)) {
			mSensorController.startTiltListener();
		}else if (event.equalsIgnoreCase(Defines.Events.HEADING_CHANGE)) {
			mSensorController.startHeadingListener();
		}else if (event.equalsIgnoreCase(Defines.Events.ORIENTATION_CHANGE)) {
			mDisplayController.startConfigurationListener();
		}
		
		// Log.d(TAG,"activate"+event);
	}

	/**
	 * Deactivate a listener
	 *
	 * @param event the event
	 */
	public void deactivate(String event) {
		if (event.equalsIgnoreCase(Defines.Events.NETWORK_CHANGE)) {
			mNetworkController.stopNetworkListener();
		} else if (event.equalsIgnoreCase(Defines.Events.LOCATION_CHANGE)) {
			mLocationController.stopAllListeners();
		} else if (event.equalsIgnoreCase(Defines.Events.SHAKE)) {
			mSensorController.stopShakeListener();
		} else if (event.equalsIgnoreCase(Defines.Events.TILT_CHANGE)) {
			mSensorController.stopTiltListener();
		} else if (event.equalsIgnoreCase(Defines.Events.HEADING_CHANGE)) {
			mSensorController.stopHeadingListener();
		}else if (event.equalsIgnoreCase(Defines.Events.ORIENTATION_CHANGE)) {
			mDisplayController.stopConfigurationListener();
		}
		// Log.d(TAG,"deactivate"+event);

	}

	/**
	 * Delete old ads.
	 */
	public void deleteOldAds() {
		mAssetController.deleteOldAds();
	}

	/* (non-Javadoc)
	 * @see com.ormma.controller.OrmmaController#stopAllListeners()
	 */
	@Override
	public void stopAllListeners() {
		try {
			mAssetController.stopAllListeners();
			mDisplayController.stopAllListeners();
			mLocationController.stopAllListeners();
			mNetworkController.stopAllListeners();
			mSensorController.stopAllListeners();
		} catch (Exception e) {
		}
	}

	
	public void showAlert(final String message) {
		Log.e(TAG,message);
	}
	
}
