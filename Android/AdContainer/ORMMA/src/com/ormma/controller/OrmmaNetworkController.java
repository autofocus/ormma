package com.ormma.controller;

import android.content.Context;
import android.content.IntentFilter;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;

import com.ormma.controller.util.OrmmaNetworkBroadcastReceiver;
import com.ormma.view.OrmmaView;

public class OrmmaNetworkController extends OrmmaController {
	private ConnectivityManager mConnectivityManager;
	private int mNetworkListenerCount;
	private OrmmaNetworkBroadcastReceiver mBroadCastReceiver;
	private IntentFilter mFilter;

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

	public void startNetworkListener() {
		if (mNetworkListenerCount == 0) {
			mBroadCastReceiver = new OrmmaNetworkBroadcastReceiver(this);
			mFilter = new IntentFilter();
			mFilter.addAction(ConnectivityManager.CONNECTIVITY_ACTION);

		}
		mNetworkListenerCount++;
		mContext.registerReceiver(mBroadCastReceiver, mFilter);
	}

	public void stopNetworkListener() {
		mNetworkListenerCount--;
		if (mNetworkListenerCount == 0){			
			mContext.unregisterReceiver(mBroadCastReceiver);
			mBroadCastReceiver = null;
			mFilter = null;

		}
	}

	public void onConnectionChanged() {
		mOrmmaView.injectJavaScript("Ormma.gotNetworkChange(\"" + getNetwork() + "\")");		
	}

}
