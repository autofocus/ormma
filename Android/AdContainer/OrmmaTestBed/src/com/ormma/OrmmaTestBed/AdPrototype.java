package com.ormma.OrmmaTestBed;
import org.ormma.view.OrmmaView;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;


public class AdPrototype extends Activity {
    private OrmmaView mAdView; 
    private Button mButton;
	/** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        mAdView = (OrmmaView) findViewById(R.id.ad);
        
     //   mAdView.setAssetController(new OrmmaAssetController(mAdView, mAdView.getContext()));
//        mAdView.loadUrl("http://10.0.2.2/3.html"); 
   	    mButton = (Button) findViewById(R.id.load);
	    mButton.setOnClickListener(new OnClickListener() {
			
			@Override
			public void onClick(View arg0) {
//				Uri uri = Uri.parse("http://v.imwx.com/v/mobile-3gp/special/15_gwc_sears_friday_pr6136.3gp");
//				Intent intent = new Intent();  
//		        intent.setAction(android.content.Intent.ACTION_VIEW);  videoOptions_480x270.html
//		        intent.setDataAndType(uri, "*/*");    http://demo.goldspotmedia.com/agencytest/test1.html
//		        startActivity(intent);   file:///android_asset/320x50Expand_480wTransparency.html
				mAdView.loadUrl("http://demo.goldspotmedia.com/agencytest/test1.html");		
				//mAdView.loadUrl("file:///android_asset/320x50Expand_480wTransparency.html");	
			}
		});
    }
    
    @Override
    protected void onSaveInstanceState(Bundle outState) {
//    	((OrmmaView)findViewById(R.id.ad)).saveState(outState); 
    	super.onSaveInstanceState(outState);
    }
    
    @Override
    protected void onRestoreInstanceState(Bundle savedInstanceState) {
//    	((OrmmaView)findViewById(R.id.ad)).restoreState(savedInstanceState); 
    	super.onRestoreInstanceState(savedInstanceState);
    }
}