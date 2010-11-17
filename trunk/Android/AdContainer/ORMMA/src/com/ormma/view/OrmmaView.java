package com.ormma.view;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;

import android.R;
import android.app.Activity;
import android.content.Context;
import android.content.res.AssetManager;
import android.content.res.TypedArray;
import android.net.ConnectivityManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.AttributeSet;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.webkit.JsResult;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.RelativeLayout;
import android.widget.ViewSwitcher;

import com.ormma.controller.OrmmaAssetController;
import com.ormma.controller.OrmmaController.Dimensions;
import com.ormma.controller.OrmmaController.Properties;
import com.ormma.controller.OrmmaDisplayController;
import com.ormma.controller.OrmmaLocationController;
import com.ormma.controller.OrmmaNetworkController;
import com.ormma.controller.OrmmaSensorController;
import com.ormma.controller.OrmmaUtilityController;

public class OrmmaView extends WebView {

	private static final int MESSAGE_RESIZE = 1000;
	private static final int MESSAGE_CLOSE = 1001;
	private static final int MESSAGE_HIDE = 1002;
	private static final int MESSAGE_SHOW = 1003;
	private static final int MESSAGE_EXPAND = 1004;
	private static final int MESSAGE_ANIMATE = 1005;
	private static final String EXPAND_DIMENSIONS = "exand_initial_dimensions";
	private static final String EXPAND_URL = "expand_url";
	private static final String EXPAND_PROPERTIES = "expand_properties";
	private static final String RESIZE_WIDTH = "resize_width";
	private static final String RESIZE_HEIGHT = "resize_height";

	private static final String CURRENT_FILE = "_ormma_current";

	private OrmmaAssetController mAssetController;
	private OrmmaDisplayController mDisplayController;
	private OrmmaLocationController mLocationController;
	private OrmmaNetworkController mNetworkController;
	private OrmmaSensorController mSensorController;

	private static String mScriptPath = null;

	private enum ViewState {
		DEFAULT, RESIZED, EXPANDED, HIDDEN, LEFT_BEHIND;
	}

	private ViewState mViewState = ViewState.DEFAULT;

	// private boolean mResized = false;
	// private Dimensions mResizedDimension;
	private ViewSwitcher mViewSwitcher;
	private OrmmaViewListener mListener;
	private OrmmaView mParentAd = null;
	
	// private Properties mResizedProperties;

	public OrmmaView(Context context, OrmmaViewListener listener) {
		super(context);
		setListener(listener);
		initialize();
	}

	public void setListener(OrmmaViewListener listener) {
		mListener = listener;
	}

	public OrmmaView(Context context) {
		super(context);
		initialize();
	}

	public void setMaxSize(int w, int h) {
		mDisplayController.setMaxSize(w, h);
	}

	public interface OrmmaViewListener {
		abstract boolean onReady();

		abstract boolean onResize();

		abstract boolean onExpand();

		abstract boolean onEventFired();
	}

	public void injectJavaScript(String str) {
		super.loadUrl("javascript:" + str);
	}


	public String mDataToInject = null;
	
	public void loadUrl(String url, String dataToInject) {
		loadUrl(url, false, dataToInject);
	}

	
	@Override
	public void loadUrl(String url) {
		loadUrl(url, false, null);
	}
	
	public void loadUrl(String url, boolean dontLoad, String dataToInject) {
		mDataToInject = dataToInject;
		if (!dontLoad) {
			InputStream is = null;
			bPageFinished = false;
			try {
				URL u = new URL(url);
				String name = u.getFile();
				if (url.startsWith("file:///android_asset")) {
					int lastSep = url.lastIndexOf(java.io.File.separatorChar);

					if (lastSep >= 0) {
						name = url.substring(url.lastIndexOf(java.io.File.separatorChar) + 1);
					}
					AssetManager am = getContext().getAssets();
					is = am.open(name);
				} else {
					is = u.openStream();
				}
				url = "file://"+mAssetController.writeToDisk(is, CURRENT_FILE, true);

			} catch (MalformedURLException e) {
			} catch (IOException e) {
				e.printStackTrace();
				return;
			}
		}
		super.loadUrl(url);

	}

	private static int[] attrs = { R.attr.maxWidth, R.attr.maxHeight };

	public OrmmaView(Context context, AttributeSet set) {
		super(context, set);

		initialize();

		TypedArray a = getContext().obtainStyledAttributes(set, attrs);

		mDisplayController.setMaxSize(a.getDimensionPixelSize(0, -1), a.getDimensionPixelSize(1, -1));

		a.recycle();

	}

	private Handler mHandler = new Handler() {

		private int mOldHeight;
		private int mOldWidth;

		@Override
		public void handleMessage(Message msg) {
			Bundle data = msg.getData();
			switch (msg.what) {
			case MESSAGE_RESIZE: {
				mViewState = ViewState.RESIZED;
				ViewGroup.LayoutParams lp = getLayoutParams();
				mOldHeight = lp.height;
				mOldWidth = lp.width;

				lp.height = data.getInt(RESIZE_HEIGHT, lp.height);
				lp.width = data.getInt(RESIZE_WIDTH, lp.width);
				Log.d("xxx","viewrs:"+lp.height+","+lp.width);
				requestLayout();
				break;
			}
			case MESSAGE_CLOSE: {
				switch (mViewState) {
				case RESIZED:
					ViewGroup.LayoutParams lp = getLayoutParams();
					lp.height = mOldHeight;
					lp.width = mOldWidth;
					requestLayout();
					break;
				case EXPANDED:
					mParentAd.closeExpanded(mExpandedFrame);
					break;
			}

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
			case MESSAGE_ANIMATE: {
				mViewSwitcher.showNext();
				break;
			}
			case MESSAGE_EXPAND: {
				mViewState = ViewState.LEFT_BEHIND;
				expandInUIThread((Dimensions) data.getParcelable(EXPAND_DIMENSIONS), data.getString(EXPAND_URL),
						(Properties) data.getParcelable(EXPAND_PROPERTIES));
				break;
			}

			}
			super.handleMessage(msg);
		}
	};

	WebViewClient mWebViewClient = new WebViewClient() {
		@Override
		public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
			// TODO Auto-generated method stub
			Log.d("AdView", "error:" + description);
			super.onReceivedError(view, errorCode, description, failingUrl);
		}

		@Override
		public void onPageFinished(WebView view, String url) {
			((OrmmaView) view).onPageFinished();
		}

		@Override
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
	private ViewGroup mExpandedFrame;
	private boolean bPageFinished = false;
	private AnimationHelper mAnimationHelper;
	private Object mUtilityController;

	private void initialize() {
		
		
		bPageFinished = false;

		getSettings().setJavaScriptEnabled(true);

		mAssetController = new OrmmaAssetController(this, this.getContext());
		mDisplayController = new OrmmaDisplayController(this, this.getContext());
		mLocationController = new OrmmaLocationController(this, this.getContext());
		mNetworkController = new OrmmaNetworkController(this, this.getContext());
		mUtilityController = new OrmmaUtilityController(this, this.getContext());
		mSensorController = new OrmmaSensorController(this, this.getContext());
		mAnimationHelper = new AnimationHelper();

		addJavascriptInterface(mAssetController, "ORMMAAssetsControllerBridge");
		addJavascriptInterface(mDisplayController, "ORMMADisplayControllerBridge");
		addJavascriptInterface(mLocationController, "ORMMALocationControllerBridge");
		addJavascriptInterface(mNetworkController, "ORMMANetworkControllerBridge");
		addJavascriptInterface(mUtilityController, "ORMMAUtilityControllerBridge");
		addJavascriptInterface(mSensorController, "ORMMASensorControllerBridge");

		setWebViewClient(mWebViewClient);

		setWebChromeClient(mWebChromeClient);
		setScriptPath();
	}
	
	
	private synchronized void setScriptPath(){
		if (mScriptPath == null){
			mScriptPath = mAssetController.copyTextFromJarIntoAssetDir("/js/OrmmaAdController.js",
			"/js/OrmmaAdController.js");	
		}
	}

	protected void closeExpanded(View expandedFrame) {
		((ViewGroup)((Activity) getContext()).getWindow().getDecorView()).removeView(expandedFrame);
		requestLayout();
		mViewState = ViewState.DEFAULT;
		injectJavaScript("Ormma.unexpand()");
		requestLayout();
	}

	protected void onPageFinished() {

		// injectJavaScript("ready()");

		if (mDataToInject != null){
			injectJavaScript(mDataToInject);
		}
		
		
		
		String injection = "{ var body = document.getElementsByTagName('head').item(0);"
		+ "script = document.createElement('script');" + "script.src = \"" + mScriptPath + "\";"
//		+ "alert(\"" + mScriptPath + "\");"
		+ "script.type = 'text/javascript';"
		+ "body.appendChild(script);" 
		+ "}";
		
		
		injectJavaScript(injection);
		
		
		//injectJavaScript("ORMMAReady()");
		// synchronized (mSync) {
		// bPageFinished = true;
		// if (mPageFinishedHandler != null) {
		// mPageFinishedHandler.onPageFinished();
		// }
		// }

	}

	public String getState(){
		return mViewState.toString().toLowerCase();
	}
	
	public void resize(int width, int height) {
		Message msg = mHandler.obtainMessage(MESSAGE_RESIZE);

		Bundle data = new Bundle();
		data.putInt(RESIZE_WIDTH, width);
		data.putInt(RESIZE_HEIGHT, height);
		msg.setData(data);

		mHandler.sendMessage(msg);
	}

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

	public void expand(Dimensions dimensions, String URL, Properties properties) {
		Message msg = mHandler.obtainMessage(MESSAGE_EXPAND);

		Bundle data = new Bundle();
		data.putParcelable(EXPAND_DIMENSIONS, dimensions);
		data.putString(EXPAND_URL, URL);
		data.putParcelable(EXPAND_PROPERTIES, properties);
		msg.setData(data);

		mHandler.sendMessage(msg);
	}

	private void expandInUIThread(Dimensions dimensions, String URL, Properties properties) {
		boolean dontLoad = false;
		if (URL == null || URL.equals("undefined")) {
			URL = getUrl();
			dontLoad = true;
		}
		mExpandedFrame = new RelativeLayout(getContext());
//		ColorDrawable cd = new ColorDrawable(properties.background_color);
//		cd.setAlpha((int) (properties.background_opacity*255));
//		mExpandedFrame.setBackgroundDrawable(cd);
		mExpandedFrame.setBackgroundColor(properties.background_color);
		android.widget.RelativeLayout.LayoutParams adLp = new RelativeLayout.LayoutParams(dimensions.width,
				dimensions.height);
		adLp.leftMargin = dimensions.x;
		adLp.topMargin = dimensions.y;

		android.view.WindowManager.LayoutParams lp = new WindowManager.LayoutParams(ViewGroup.LayoutParams.FILL_PARENT,
				ViewGroup.LayoutParams.FILL_PARENT);

		OrmmaView expandedView = new OrmmaView(getContext());
		expandedView.loadExpandedUrl(URL, this, mExpandedFrame, dontLoad);
		mExpandedFrame.addView(expandedView, adLp);

		((ViewGroup)((Activity) getContext()).getWindow().getDecorView()).addView(mExpandedFrame, lp);
	}

	private void loadExpandedUrl(String Url, OrmmaView parentAd, ViewGroup expandedFrame, boolean dontLoad) {
		mParentAd = parentAd;
		mExpandedFrame = expandedFrame;
		mViewState = ViewState.EXPANDED;
		loadUrl(Url, dontLoad, mDataToInject);
	}

	class PageFinishedHandler {
		ViewSwitcher mParentView;

		public PageFinishedHandler(ViewSwitcher viewSwitcher) {
			mParentView = viewSwitcher;
		}

		public void onPageFinished() {
			mParentView.setVisibility(VISIBLE);
			mParentView.setInAnimation(mAnimationHelper.getExpandInAnimation());
			mParentView.setOutAnimation(mAnimationHelper.getExpandOutAnimation());
			mHandler.sendEmptyMessage(MESSAGE_ANIMATE);
		}
	}


	public boolean isPageFinished() {
		return bPageFinished;
	}

//	private void insertOrmma(InputStream in) throws IOException {
//
//		BufferedReader reader = new BufferedReader(new InputStreamReader(in));
//
//		try {
//			if (insertOrmmaPass1(reader)) {
//				in.reset();
//				insertOrmmaPass2(reader);
//			}
//		} catch (NoSuchAlgorithmException e) {
//			// TODO Auto-generated catch block
//			e.printStackTrace();
//		}
//		reader.close();
//	}
//
//	private boolean insertOrmmaPass1(BufferedReader reader) throws IOException {
//
//		boolean fragment = true;
//		boolean inHTML = false;
//
//		MessageDigest digest;
//		try {
//			digest = java.security.MessageDigest.getInstance("MD5");
//		} catch (NoSuchAlgorithmException e) {
//			e.printStackTrace();
//		}
//		
//		File out = new File(getContext().getFilesDir(), CURRENT_FILE);
//		out.createNewFile();
//
//		PrintWriter writer = new PrintWriter(new FileWriter(out, false));
//
//		String line = null;
//		while ((line = reader.readLine()) != null) {
//			digest.update(line.getBytes());
//			writer.println(line);
//		}
//		writer.close();
//		return fragment;
//	}
//
//	private void insertOrmmaPass2(BufferedReader reader) throws IOException {
//		File out = new File(getContext().getFilesDir(), CURRENT_FILE);
//		out.createNewFile();
//
//		PrintWriter writer = new PrintWriter(new FileWriter(out, false));
//		String line = null;
//
//		writer.println("<HTML>");
//		writer.println("<HEAD>");
//		writer.println("<script type=\"text/javascript\" src=\"" + mScriptPath + "\"></script>");
//		writer.println("</HEAD>");
//		writer.println("<BODY>");
//		while ((line = reader.readLine()) != null) {
//			writer.println(line);
//		}
//		writer.println("</BODY>");
//		writer.println("</HTML>");
//
//		writer.close();
//	}

}
