/**
 * @author jsodos
 */
package com.ormma.controller.util;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import com.ormma.controller.OrmmaDisplayController;

/**
 * The Class OrmmaConfigurationBroadcastReceiver.
 */
public class OrmmaConfigurationBroadcastReceiver extends BroadcastReceiver {

	private OrmmaDisplayController mOrmmaDisplayController;
	
	/**
	 * The m last orientation.
	 */
	private int mLastOrientation;

	/**
	 * Instantiates a new ormma configuration broadcast receiver.
	 *
	 * @param ormmaDisplayController the ormma display controller
	 */
	public OrmmaConfigurationBroadcastReceiver(OrmmaDisplayController ormmaDisplayController) {
		mOrmmaDisplayController = ormmaDisplayController;
		mLastOrientation = mOrmmaDisplayController.getOrientation();
	}

	/* (non-Javadoc)
	 * @see android.content.BroadcastReceiver#onReceive(android.content.Context, android.content.Intent)
	 */
	@Override
	public void onReceive(Context context, Intent intent) {
		String action = intent.getAction();
		if (action.equals(Intent.ACTION_CONFIGURATION_CHANGED)) {
			int orientation = mOrmmaDisplayController.getOrientation();
			if (orientation != mLastOrientation) {
				mLastOrientation = orientation;
				mOrmmaDisplayController.onOrientationChanged(mLastOrientation);
			}
		}
	}

}
