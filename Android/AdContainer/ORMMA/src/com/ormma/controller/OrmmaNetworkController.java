/**
 * @author jsodos
 */
package com.ormma.controller;

import android.content.Context;
import android.content.IntentFilter;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;

import com.ormma.controller.util.OrmmaNetworkBroadcastReceiver;
import com.ormma.view.OrmmaView;

/**
 * The Class OrmmaNetworkController.  OrmmaController for interacting with network states
 */
public class OrmmaNetworkController extends OrmmaController {
	
	private ConnectivityManager mConnectivityManager;
	private int mNetworkListenerCount;
	private OrmmaNetworkBroadcastReceiver mBroadCastReceiver;
	private IntentFilter mFilter;

	/**
	 * Instantiates a new ormma network controller.
	 *
	 * @param adView the ad view
	 * @param context the context
	 */
	public OrmmaNetworkController(OrmmaView adView, Context context) {
		super(adView, context);
		mConnectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
	}

	/**
	 * Gets the network.
	 *
	 * @return the network
	 */
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

	/**
	 * Start network listener.
	 */
	public void startNetworkListener() {
		if (mNetworkListenerCount == 0) {
			mBroadCastReceiver = new OrmmaNetworkBroadcastReceiver(this);
			mFilter = new IntentFilter();
			mFilter.addAction(ConnectivityManager.CONNECTIVITY_ACTION);

		}
		mNetworkListenerCount++;
		mContext.registerReceiver(mBroadCastReceiver, mFilter);
	}

	/**
	 * Stop network listener.
	 */
	public void stopNetworkListener() {
		mNetworkListenerCount--;
		if (mNetworkListenerCount == 0) {
			mContext.unregisterReceiver(mBroadCastReceiver);
			mBroadCastReceiver = null;
			mFilter = null;

		}
	}

	/**
	 * On connection changed.
	 */
	public void onConnectionChanged() {
		mOrmmaView.injectJavaScript("window.ormmaview.fireChangeEvent({ network: \'" + getNetwork() + "\'});");
	}

	/* (non-Javadoc)
	 * @see com.ormma.controller.OrmmaController#stopAllListeners()
	 */
	@Override
	public void stopAllListeners() {
		mNetworkListenerCount = 0;
		try {
			mContext.unregisterReceiver(mBroadCastReceiver);
		} catch (Exception e) {
		}
	}

}
