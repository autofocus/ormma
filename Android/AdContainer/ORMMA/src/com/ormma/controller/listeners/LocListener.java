package com.ormma.controller.listeners;
/* License (MIT)
 * Copyright (c) 2008 Nitobi
 * website: http://phonegap.com
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * “Software”), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
import android.content.Context;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;

import com.ormma.controller.OrmmaLocationController;

public class LocListener implements LocationListener {
	
	OrmmaLocationController mOrmmaLocationController;
	private LocationManager mLocMan;
//	private Location cLoc;
	private String mProvider;
	private long mInterval;
	
	
	public LocListener(Context c, int interval, OrmmaLocationController ormmaLocationController, String provider)
	{
		mOrmmaLocationController = ormmaLocationController;
		mLocMan = (LocationManager) c.getSystemService(Context.LOCATION_SERVICE);
		mProvider = provider;
		mInterval = interval;
	}
	
	
	public void onProviderDisabled(String provider) {
		mOrmmaLocationController.fail();
	}



	public void onStatusChanged(String provider, int status, Bundle extras) {
		if(status == 0)
		{
			mOrmmaLocationController.fail();
		}
	}


	public void onLocationChanged(Location location) {
		mOrmmaLocationController.success(location);
	}

	public void stop()
	{
		mLocMan.removeUpdates(this);
	}


	@Override
	public void onProviderEnabled(String provider) {
		// TODO Auto-generated method stub
		
	}


	public void start() {
		mLocMan.requestLocationUpdates(mProvider, mInterval, 0, this);		
	}
	
}
