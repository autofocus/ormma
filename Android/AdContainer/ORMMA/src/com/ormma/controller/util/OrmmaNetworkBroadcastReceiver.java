/**
 * @author jsodos
 */
package com.ormma.controller.util;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.net.ConnectivityManager;

import com.ormma.controller.OrmmaNetworkController;

/**
 * The Class OrmmaNetworkBroadcastReceiver.
 */
public class OrmmaNetworkBroadcastReceiver extends BroadcastReceiver {

	private OrmmaNetworkController mOrmmaNetworkController;

	/**
	 * Instantiates a new ormma network broadcast receiver.
	 *
	 * @param ormmaNetworkController the ormma network controller
	 */
	public OrmmaNetworkBroadcastReceiver(OrmmaNetworkController ormmaNetworkController) {
		mOrmmaNetworkController = ormmaNetworkController;
	}

	/* (non-Javadoc)
	 * @see android.content.BroadcastReceiver#onReceive(android.content.Context, android.content.Intent)
	 */
	@Override
	public void onReceive(Context context, Intent intent) {
		String action = intent.getAction();
		if (action.equals(ConnectivityManager.CONNECTIVITY_ACTION)) {
			mOrmmaNetworkController.onConnectionChanged();
		}
	}

}
