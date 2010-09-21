package com.ormma.controller;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;

import com.ormma.view.OrmmaView;

public class OrmmaNetworkController extends OrmmaController {
	private ConnectivityManager mConnectivityManager;

	public OrmmaNetworkController(OrmmaView adView, Context context) {
		super(adView, context);
		mConnectivityManager =  (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);	
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


}
