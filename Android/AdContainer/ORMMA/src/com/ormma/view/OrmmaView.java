package com.ormma.view;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;

import android.content.Context;
import android.content.res.AssetManager;
import android.net.ConnectivityManager;
import android.os.Handler;
import android.os.Message;
import android.util.AttributeSet;
import android.util.Log;
import android.view.View;
import android.webkit.JsResult;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import com.ormma.controller.OrmmaAssetController;
import com.ormma.controller.OrmmaDisplayController;
import com.ormma.controller.OrmmaLocationController;
import com.ormma.controller.OrmmaNetworkController;
import com.ormma.controller.OrmmaController.Dimensions;
import com.ormma.controller.OrmmaController.Properties;

public class OrmmaView extends WebView {

	private static final int MESSAGE_RESIZE = 1000;
	private static final int MESSAGE_CLOSE = 1001;
	private static final int MESSAGE_HIDE = 1002;
	private static final int MESSAGE_SHOW = 1003;


	private OrmmaAssetController mAssetController;
	private OrmmaDisplayController mDisplayController;
	private OrmmaLocationController mLocationController;
	private OrmmaNetworkController mNetworkController;

//	private boolean mResized = false;
	private Dimensions mResizedDimension;

//	private Properties mResizedProperties;

	public OrmmaView(Context context) {
		super(context);
		initialize();
	}

	// private void load(InputStream is){
	// try{
	// InputStreamReader isr = new InputStreamReader(is);
	// BufferedReader br = new BufferedReader(isr);
	// char[] buffer = new char[BUFFER_SIZE];
	// StringBuffer page = new StringBuffer(BUFFER_SIZE);
	// int read;
	// while ((read = br.read(buffer,0,1024)) >0) {
	// String readData = String.valueOf(buffer,0,read);
	// page.append(readData);
	// buffer = new char[BUFFER_SIZE];
	// }
	// loadDataWithBaseURL(mAssetController.getAssetPath(), page.toString(),
	// "text/html", "UTF-8", null);
	// }
	// catch (MalformedURLException ex) {
	// System.err.println(ex);
	// }
	// catch (IOException ex) {
	// System.err.println(ex);
	// }
	// }


	@Override
	public void loadUrl(String url) {
		InputStream is = null;
		try {
			URL u = new URL(url);
			String name = u.getFile();
			if (url.startsWith("file:///android_asset")) {
				int lastSep = url.lastIndexOf(java.io.File.separatorChar);
				
				if (lastSep >=0){
					name = url.substring(url.lastIndexOf(java.io.File.separatorChar)+1);
				}
				AssetManager am = getContext().getAssets();
				is = am.open(name);
			} else {
				is = u.openStream();
			}
			url = "file://"+mAssetController.writeToDisk(is, name);
		} catch (MalformedURLException e) {
		} catch (IOException e) {
			e.printStackTrace();
			return;
		}
		super.loadUrl(url);
	}

	public OrmmaView(Context context, AttributeSet attrs) {
		super(context, attrs);
		initialize();
	}

	private Handler mHandler = new Handler() {
		@Override
		public void handleMessage(Message msg) {
			switch (msg.what) {
			case MESSAGE_RESIZE: {
				layout(mResizedDimension.left, mResizedDimension.top, mResizedDimension.right, mResizedDimension.bottom);
				break;
			}
			case MESSAGE_CLOSE: {
				requestLayout();
				break;
			}
			case MESSAGE_HIDE: {
				setVisibility(View.INVISIBLE);
				break;
			}
			case MESSAGE_SHOW: {
				setVisibility(View.VISIBLE);
				break;
			}
			}
			super.handleMessage(msg);
		}
	};

	// @Override
	// protected void onLayout(boolean changed, int l, int t, int r, int b) {
	// Configuration cfg = getContext().getResources().getConfiguration();
	// if (cfg.keyboardHidden == Configuration.KEYBOARDHIDDEN_NO && mResized &&
	// l!= mResizedDimension.left && t!= mResizedDimension.top && r!=
	// mResizedDimension.right && b!= mResizedDimension.bottom){
	// layout(mResizedDimension.left, mResizedDimension.top,
	// mResizedDimension.right, mResizedDimension.bottom);
	// super.onLayout(true, mResizedDimension.left, mResizedDimension.top,
	// mResizedDimension.right, mResizedDimension.bottom);
	// }
	// else
	// super.onLayout(changed, l, t, r, b);
	// }

	WebViewClient mWebViewClient = new WebViewClient() {
		@Override
		public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
			// TODO Auto-generated method stub
			Log.d("AdView", "error:" + description);
			super.onReceivedError(view, errorCode, description, failingUrl);
		}

		public void onPageFinished(WebView view, String url) {

			String scriptPath = mAssetController.copyTextFromJarIntoAssetDir("/js/OrmmaAdController.js",
					"/js/OrmmaAdController.js");

			loadUrl("javascript:	" + "{ var body = document.getElementsByTagName('head').item(0);"
					+ "script = document.createElement('script');" + "script.src = \"" + scriptPath + "\";"
					+ "script.type = 'text/javascript';" + "body.appendChild(script)" + "}");
		}

		public void onLoadResource(WebView view, String url) {
			if (url.startsWith("ormma://")) {
				url = "file:///data/data/com.ormma.OrmmaTestBed/files/tmp/abc.jpg";// mAssetController.getRealPath(url);
			}
			super.onLoadResource(view, url);
		};

	};

	WebChromeClient mWebChromeClient = new WebChromeClient() {
		@Override
		public boolean onJsAlert(WebView view, String url, String message, JsResult result) {
			Log.d("OrmmaView", message);
			return super.onJsAlert(view, url, message, result);
		}
	};

	private void initialize() {

		getSettings().setJavaScriptEnabled(true);

		mAssetController = new OrmmaAssetController(this, this.getContext());
		mDisplayController = new OrmmaDisplayController(this, this.getContext());
		mLocationController = new OrmmaLocationController(this, this.getContext());
		mNetworkController = new OrmmaNetworkController(this, this.getContext());

		addJavascriptInterface(mAssetController, "ORMMAAssetsControllerBridge");
		addJavascriptInterface(mDisplayController, "ORMMADisplayControllerBridge");
		addJavascriptInterface(mLocationController, "ORMMALocationControllerBridge");
		addJavascriptInterface(mNetworkController, "ORMMANetworkControllerBridge");

		setWebViewClient(mWebViewClient);

		setWebChromeClient(mWebChromeClient);
	}

	public void resize(Dimensions dimension, Properties properties) {
		mResizedDimension = dimension;
//		mResized = true;
//		mResizedProperties = properties;
		mHandler.sendEmptyMessage(MESSAGE_RESIZE);
	}

//	private AnimationSet getResizeAnimation() {
//		AnimationSet resizeAnimation = new AnimationSet(true);
//		Animation a = new TranslateAnimation(Animation.ABSOLUTE, mResizedDimension.left, Animation.ABSOLUTE,
//				mResizedDimension.top);
//		// a.setFillAfter(true);
//		resizeAnimation.addAnimation(a);
//		resizeAnimation.setFillAfter(true);
//		a.setAnimationListener(new AnimationListener() {
//
//			@Override
//			public void onAnimationStart(Animation animation) {
//				// TODO Auto-generated method stub
//
//			}
//
//			@Override
//			public void onAnimationRepeat(Animation animation) {
//				OrmmaView.this.requestLayout();
//
//			}
//
//			@Override
//			public void onAnimationEnd(Animation animation) {
//				android.view.ViewGroup.LayoutParams x = getLayoutParams();
//				x.height = mResizedDimension.bottom - mResizedDimension.top;
//				x.width = mResizedDimension.right - mResizedDimension.left;
//				requestLayout();
//
//			}
//		});
//		return resizeAnimation;
//	}

	public void close() {
		mHandler.sendEmptyMessage(MESSAGE_CLOSE);
	}

	public void hide() {
		mHandler.sendEmptyMessage(MESSAGE_HIDE);
	}

	public void show() {
		mHandler.sendEmptyMessage(MESSAGE_SHOW);
	}

	public ConnectivityManager getConnectivityManager() {
		return (ConnectivityManager) this.getContext().getSystemService(Context.CONNECTIVITY_SERVICE);
	}

	public void dump() {
		// TODO Auto-generated method stub

	}

}
