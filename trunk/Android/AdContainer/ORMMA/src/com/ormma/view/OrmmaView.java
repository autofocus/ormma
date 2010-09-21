package com.ormma.view;


import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;

import android.content.Context;
import android.content.res.Configuration;
import android.location.LocationManager;
import android.net.ConnectivityManager;
import android.os.Handler;
import android.os.Message;
import android.os.StatFs;
import android.util.AttributeSet;
import android.util.Log;
import android.view.View;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.view.animation.AnimationSet;
import android.view.animation.ScaleAnimation;
import android.view.animation.TranslateAnimation;
import android.view.animation.Animation.AnimationListener;
import android.webkit.JsResult;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import com.ormma.controller.OrmmaController;
import com.ormma.controller.OrmmaController.Dimensions;
import com.ormma.controller.OrmmaController.Properties;
import com.ormma.listeners.LocationUpdateListener;

public class OrmmaView extends WebView {

	private static final int MESSAGE_RESIZE = 1000;
	private static final int MESSAGE_CLOSE = 1001;
	private static final int MESSAGE_HIDE = 1002;
	private static final int MESSAGE_SHOW = 1003;
	
	private OrmmaController mAdController;     
	private Handler mHandler;
	
	private boolean mResized = false;
	private Dimensions mResizedDimension;

	private Properties mResizedProperties;
	private Object mLocationListener;
	
	public OrmmaView(Context context) {
		super(context);
		// TODO Auto-generated constructor stub
	}

//	@Override
//	protected void onLayout(boolean changed, int l, int t, int r, int b) {
//		Configuration cfg = getContext().getResources().getConfiguration();
//		if (cfg.keyboardHidden == Configuration.KEYBOARDHIDDEN_NO && mResized && l!= mResizedDimension.left && t!= mResizedDimension.top && r!= mResizedDimension.right && b!= mResizedDimension.bottom){
//			layout(mResizedDimension.left, mResizedDimension.top, mResizedDimension.right, mResizedDimension.bottom);
//			super.onLayout(true, mResizedDimension.left, mResizedDimension.top, mResizedDimension.right, mResizedDimension.bottom);
//		}
//		else
//			super.onLayout(changed, l, t, r, b);
//	}
	
	
	
	public OrmmaView(Context context, AttributeSet attrs) {
		super(context, attrs);
		loadUrl("file:///android_asset/www/ad.html");
		getSettings().setJavaScriptEnabled(true);
		mAdController = new OrmmaController(this);
		addJavascriptInterface(mAdController, "ORMMAControllerBridge");
		setBackgroundColor(0xFFFFFFFF);
		mHandler = new Handler(){
			@Override
			public void handleMessage(Message msg) {
				switch (msg.what){
					case MESSAGE_RESIZE:
					{
						layout(mResizedDimension.left, mResizedDimension.top, mResizedDimension.right, mResizedDimension.bottom);
						break;
					}
					case MESSAGE_CLOSE:
					{
						requestLayout();
						break;
					}
					case MESSAGE_HIDE:
					{
						setVisibility(View.INVISIBLE);
						break;
					}
					case MESSAGE_SHOW:
					{
						setVisibility(View.VISIBLE);
						break;
					}

					

				}
				super.handleMessage(msg);
			}
		};
		//new AccelListener(context, this).start(1000);
		setWebViewClient(new WebViewClient(){
			@Override
			public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
				// TODO Auto-generated method stub
				Log.d("AdView","error:"+description);
				super.onReceivedError(view, errorCode, description, failingUrl);
			}
		});
		setWebChromeClient(new WebChromeClient(){
			@Override
			public boolean onJsAlert(WebView view, String url, String message, JsResult result) {
				Log.d("OrmmaView", message);
				return super.onJsAlert(view, url, message, result);
			}
		});
	}

	public OrmmaView(Context context, AttributeSet attrs, int defStyle) {
		super(context, attrs, defStyle);
		// TODO Auto-generated constructor stub
	}


	public void resize(Dimensions dimension, Properties properties) {
		mResizedDimension = dimension;
		mResized = true;
		mResizedProperties = properties;
		mHandler.sendEmptyMessage(MESSAGE_RESIZE);
	}
	
	private AnimationSet getResizeAnimation(){
		AnimationSet resizeAnimation = new AnimationSet(true);
		Animation a = new TranslateAnimation(Animation.ABSOLUTE, mResizedDimension.left,
				Animation.ABSOLUTE, mResizedDimension.top);
//		a.setFillAfter(true);
		resizeAnimation.addAnimation(a);
		resizeAnimation.setFillAfter(true);
		a.setAnimationListener(new AnimationListener() {
			
			@Override
			public void onAnimationStart(Animation animation) {
				// TODO Auto-generated method stub
				
			}
			
			@Override
			public void onAnimationRepeat(Animation animation) {
				OrmmaView.this.requestLayout();
				
			}
			
			@Override
			public void onAnimationEnd(Animation animation) {
				android.view.ViewGroup.LayoutParams x = getLayoutParams();
				x.height = mResizedDimension.bottom - mResizedDimension.top; 
				x.width = mResizedDimension.right - mResizedDimension.left;
				requestLayout();

			}
		});
		return resizeAnimation;
	}

	public FileOutputStream getAssetOutputString(String asset) throws FileNotFoundException {
		int lastSep = asset.lastIndexOf(java.io.File.separatorChar);
		String path = "/";
		String name = asset;

		
		if (lastSep >=0){
			path = asset.substring(0, asset.lastIndexOf(java.io.File.separatorChar));
			name = asset.substring(asset.lastIndexOf(java.io.File.separatorChar)+1);
		}
		//File dir = this.getContext().getDir(path, 0);
		File filesDir = this.getContext().getFilesDir();
		File newDir = new File (filesDir.getPath() +java.io.File.separator + path);
		newDir.mkdirs();
		File file = new File(newDir,name);
		return new FileOutputStream(file);
	}

	public int cacheRemaining() {
		File filesDir = this.getContext().getFilesDir();
		StatFs stats = new StatFs(filesDir.getPath());
		int free =  stats.getFreeBlocks() * stats.getBlockSize();
		return free;
	}

	public void close() {
		mHandler.sendEmptyMessage(MESSAGE_CLOSE);
	}

	public void hide() {
		mHandler.sendEmptyMessage(MESSAGE_HIDE);
	}

	public void removeAsset(String asset) {
		int lastSep = asset.lastIndexOf(java.io.File.separatorChar);
		String path = "/";
		String name = asset;

		
		if (lastSep >=0){
			path = asset.substring(0, asset.lastIndexOf(java.io.File.separatorChar));
			name = asset.substring(asset.lastIndexOf(java.io.File.separatorChar)+1);
		}

		File filesDir = this.getContext().getFilesDir();
		File newDir = new File (filesDir.getPath() +java.io.File.separator + path);
		File file = new File(newDir,name);
		file.delete();
	}

	public void show() {
		mHandler.sendEmptyMessage(MESSAGE_SHOW);		
	}

	public LocationManager getLocationMananger() {
		return (LocationManager) this.getContext().getSystemService(Context.LOCATION_SERVICE);
	}

	public ConnectivityManager getConnectivityManager() {
		return (ConnectivityManager) this.getContext().getSystemService(Context.CONNECTIVITY_SERVICE);
	}

	public WindowManager getWindowManager() {
		return (WindowManager) this.getContext().getSystemService(Context.WINDOW_SERVICE);
	}

	public void startLocationListener() {
		mLocationListener = new LocationUpdateListener(this, this.getContext());
	}

}
