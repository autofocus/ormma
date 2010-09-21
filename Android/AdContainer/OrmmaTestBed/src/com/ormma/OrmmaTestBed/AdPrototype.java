package com.ormma.OrmmaTestBed;

import com.ormma.R;
import com.ormma.view.OrmmaView;

import android.app.Activity;
import android.os.Bundle;

public class AdPrototype extends Activity {
    private OrmmaView mAdView;

	/** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        mAdView = (OrmmaView) findViewById(R.id.ad);
        mAdView.loadUrl("file:///android_asset/www/ad.html");
	
    }
}