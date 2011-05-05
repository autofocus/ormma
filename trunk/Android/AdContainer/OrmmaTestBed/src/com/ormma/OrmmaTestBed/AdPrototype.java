/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */
package com.ormma.OrmmaTestBed;


import org.ormma.view.OrmmaView;

import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;

import com.google.android.maps.MapActivity;



public class AdPrototype extends MapActivity {
    private OrmmaView mAdView; 
    private Button mButton;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        mAdView = (OrmmaView) findViewById(R.id.ad);
     
   	    mButton = (Button) findViewById(R.id.load);
	    mButton.setOnClickListener(new OnClickListener() {
			
			@Override
			public void onClick(View arg0) {
//				Uri uri = Uri.parse("http://v.imwx.com/v/mobile-3gp/special/15_gwc_sears_friday_pr6136.3gp");
//			    videoOptions_480x270.html
//		        http://demo.goldspotmedia.com/agencytest/test1.html
//		        file:///android_asset/320x50Expand_480wTransparency.html
				mAdView.loadUrl("http://demo.goldspotmedia.com/agencytest/test1.html");		
			}
		});
    }
    
    @Override
    protected void onSaveInstanceState(Bundle outState) {
    	super.onSaveInstanceState(outState);
    }
    
    @Override
    protected void onRestoreInstanceState(Bundle savedInstanceState) {
    	super.onRestoreInstanceState(savedInstanceState);
    }

	protected boolean isRouteDisplayed() {
		return false;
	}
}