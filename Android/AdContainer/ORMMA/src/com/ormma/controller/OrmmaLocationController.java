/**
 * @author jsodos
 */
package com.ormma.controller;

import java.util.Iterator;
import java.util.List;

import android.content.Context;
import android.location.Location;
import android.location.LocationManager;

import com.ormma.controller.listeners.LocListener;
import com.ormma.view.OrmmaView;

/**
 * The Class OrmmaLocationController.  Ormma controller for interacting with lbs
 */
public class OrmmaLocationController extends OrmmaController {

	private LocationManager mLocationManager;
	private boolean hasPermission = false;
	final int INTERVAL = 1000;
	private LocListener mGps;
	private LocListener mNetwork;
	private int mLocListenerCount;

	/**
	 * Instantiates a new ormma location controller.
	 *
	 * @param adView the ad view
	 * @param context the context
	 */
	public OrmmaLocationController(OrmmaView adView, Context context) {
		super(adView, context);
		try {
			mLocationManager = (LocationManager) context.getSystemService(Context.LOCATION_SERVICE);
			if (mLocationManager.getProvider(LocationManager.GPS_PROVIDER) != null)
				mGps = new LocListener(context, INTERVAL, this, LocationManager.GPS_PROVIDER);
			if (mLocationManager.getProvider(LocationManager.NETWORK_PROVIDER) != null)
				mNetwork = new LocListener(context, INTERVAL, this, LocationManager.NETWORK_PROVIDER);
			hasPermission = true;
		} catch (SecurityException e) {

		}
	}

	// public int getHeading() {
	// if (!hasPermission){
	// return -1;
	// }
	// List<String> providers = mLocationManager.getProviders(true);
	// Iterator<String> provider = providers.iterator();
	// Location lastKnown = null;
	// int bearing = -1;
	// while (provider.hasNext()) {
	// lastKnown = mLocationManager.getLastKnownLocation(provider.next());
	// if (lastKnown != null) {
	// if (lastKnown.hasBearing()) {
	// bearing = (int) lastKnown.getBearing();
	// break;
	// }
	// }
	// }
	// return bearing;
	// }

	/**
	 * Gets the location.
	 *
	 * @return the location
	 */
	public String getLocation() {
		if (!hasPermission) {
			return null;
		}
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

	/**
	 * Start location listener.
	 */
	public void startLocationListener() {
		if (mLocListenerCount == 0) {

			if (mNetwork != null)
				mNetwork.start();
			if (mGps != null)
				mGps.start();
		}
		mLocListenerCount++;
	}

	/**
	 * Stop location listener.
	 */
	public void stopLocationListener() {
		mLocListenerCount--;
		if (mLocListenerCount == 0) {

			if (mNetwork != null)
				mNetwork.stop();
			if (mGps != null)
				mGps.stop();
		}
	}

	/**
	 * Success.
	 *
	 * @param loc the loc
	 */
	public void success(Location loc) {
		String ret = "{ \"lat\": " + loc.getLatitude() + ", " + "\"long\": " + loc.getLongitude() + "}";
		mOrmmaView.injectJavaScript("OrmmaAdController.locationChanged(" + ret + ")");
	}

	/**
	 * Fail.
	 */
	public void fail() {
		mOrmmaView.injectJavaScript("OrmmaAdController.errored('loc')");
	}

	/* (non-Javadoc)
	 * @see com.ormma.controller.OrmmaController#stopAllListeners()
	 */
	@Override
	public void stopAllListeners() {
		mLocListenerCount = 0;
		try {
			mGps.stop();
		} catch (Exception e) {
		}
		try {
			mNetwork.stop();
		} catch (Exception e) {
		}
	}

}
