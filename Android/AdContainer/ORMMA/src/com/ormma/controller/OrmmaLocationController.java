package com.ormma.controller;

import java.util.Iterator;
import java.util.List;

import android.content.Context;
import android.location.Location;
import android.location.LocationManager;

import com.ormma.controller.listeners.LocListener;
import com.ormma.view.OrmmaView;

public class OrmmaLocationController extends OrmmaController{

	private LocationManager mLocationManager;
	final int INTERVAL = 1000;
	
	private LocListener mGps;
	private LocListener mNetwork;

	public OrmmaLocationController(OrmmaView adView, Context context) {
		super(adView, context);
		mLocationManager = (LocationManager) context.getSystemService(Context.LOCATION_SERVICE);
		if (mLocationManager.getProvider(LocationManager.GPS_PROVIDER) != null)
			mGps = new LocListener(context, INTERVAL, this,LocationManager.GPS_PROVIDER);
		if (mLocationManager.getProvider(LocationManager.NETWORK_PROVIDER) != null)
			mNetwork = new LocListener(context, INTERVAL, this,LocationManager.GPS_PROVIDER);

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
	public void startLocationListener(){
		mNetwork.start();
		mGps.start();
	}

	public void success(Location loc)
	{
		String ret =
		"{ \"lat\": " + loc.getLatitude() + ", " + "\"long\": " + loc.getLongitude() + "}";
		mOrmmaView.loadUrl("javascript:OrmmaAdController.locationChanged(" + ret + ")");
	}
	
	public void fail()
	{
		mOrmmaView.loadUrl("javascript:errored('loc')");
	}
	
	// This stops the listener
	void stop()
	{
		if(mGps != null)
			mGps.stop();
		if(mNetwork != null)
			mNetwork.stop();
	}

	
}
