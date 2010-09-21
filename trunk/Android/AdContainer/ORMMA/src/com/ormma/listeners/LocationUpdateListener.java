package com.ormma.listeners;

import com.ormma.view.OrmmaView;

import android.content.Context;
import android.location.Location;
import android.location.LocationManager;


public class LocationUpdateListener {

	OrmmaView mAdView;
	final int INTERVAL = 1000;
	
	private LocationManager mLocMan;
	private LocListener mGps;
	private LocListener mNetwork;
	
	
	
	public LocationUpdateListener(OrmmaView adView, Context context){
		mAdView = adView;
		mLocMan = (LocationManager) context.getSystemService(Context.LOCATION_SERVICE);
		
		if (mLocMan.getProvider(LocationManager.GPS_PROVIDER) != null)
			mGps = new LocListener(context, INTERVAL, this,LocationManager.GPS_PROVIDER);
		if (mLocMan.getProvider(LocationManager.NETWORK_PROVIDER) != null)
			mNetwork = new LocListener(context, INTERVAL, this,LocationManager.GPS_PROVIDER);
		mAdView = adView;
	
		}
	
	void success(Location loc)
	{
		String ret =
		"{ \"lat\": " + loc.getLatitude() + ", " + "\"long\": " + loc.getLongitude() + "}";
		mAdView.loadUrl("javascript:OrmmaAdController.locationChanged(" + ret + ")");
	}
	
	void fail()
	{
		mAdView.loadUrl("javascript:errored('loc')");
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