package com.ormma.controller.util;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.net.ConnectivityManager;

import com.ormma.controller.OrmmaNetworkController;

public class OrmmaNetworkBroadcastReceiver extends BroadcastReceiver {


	private OrmmaNetworkController mOrmmaNetworkController;

	public OrmmaNetworkBroadcastReceiver(OrmmaNetworkController ormmaNetworkController) {
		mOrmmaNetworkController = ormmaNetworkController;
	}

	@Override
	public void onReceive(Context context, Intent intent) {
		String action = intent.getAction();
		if (action.equals(ConnectivityManager.CONNECTIVITY_ACTION)){
			mOrmmaNetworkController.onConnectionChanged();
			}
		}
	

}
