/**
 * 
 * This is the view to place into a layout to implement ormma functionality.
 * It can be used either via xml or programatically
 * 
 * It is a subclass of the standard WebView which brings with it all the standard
 * functionality as well as the inherent bugs on some os versions.
 * 
 * Webviews have a tendency to leak on orientation in older versions of the android OS
 * this can be minimized by using an application context, but this will break the launching
 * of subwindows (such as alert calls from javascript)
 * 
 * 
 * @author jsodos
 */
package com.ormma.view;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Timer;
import java.util.TimerTask;

import org.apache.http.Header;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpHead;
import org.apache.http.impl.client.DefaultHttpClient;

import android.R;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.res.AssetManager;
import android.content.res.TypedArray;
import android.net.ConnectivityManager;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.GestureDetector;
import android.view.GestureDetector.SimpleOnGestureListener;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.view.ViewTreeObserver.OnGlobalLayoutListener;
import android.webkit.JsResult;
import android.webkit.WebBackForwardList;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;

import com.ormma.controller.OrmmaController.Dimensions;
import com.ormma.controller.OrmmaController.Properties;
import com.ormma.controller.OrmmaUtilityController;

/**
 * This is the view to place into a layout to implement ormma functionality. It
 * can be used either via xml or programatically
 * 
 * It is a subclass of the standard WebView which brings with it all the
 * standard functionality as well as the inherent bugs on some os versions.
 * 
 * Webviews have a tendency to leak on orientation in older versions of the
 * android OS this can be minimized by using an application context, but this
 * will break the launching of subwindows (such as alert calls from javascript)
 * 
 * It is important to not use any of the layout constants elsewhere in the same
 * view as things will get confused. Normally this is not an issue as generated
 * layout constants will not interfere.
 */
public class OrmmaView extends WebView implements OnGlobalLayoutListener {

	
	/**
	 * enum representing possible view states
	 */
	public enum ViewState {
		DEFAULT,
		RESIZED,
		EXPANDED,
		HIDDEN,
		LEFT_BEHIND,
		OPENED;
	}
	//static for accessing xml attributes
	private static int[] attrs = { R.attr.maxWidth, R.attr.maxHeight };

	
	// Messaging constants
	private static final int MESSAGE_RESIZE = 1000;
	private static final int MESSAGE_CLOSE = 1001;
	private static final int MESSAGE_HIDE = 1002;
	private static final int MESSAGE_SHOW = 1003;
	private static final int MESSAGE_EXPAND = 1004;
	private static final int MESSAGE_SEND_EXPAND_CLOSE = 1005;
	private static final int MESSAGE_OPEN = 1006;

	// Extra constants
	private static final String EXPAND_DIMENSIONS = "exand_initial_dimensions";
	private static final String EXPAND_URL = "expand_url";
	private static final String EXPAND_PROPERTIES = "expand_properties";
	private static final String RESIZE_WIDTH = "resize_width";
	private static final String RESIZE_HEIGHT = "resize_height";
	private static final String CURRENT_FILE = "_ormma_current";
	private static final String AD_PATH = "AD_PATH";

	// Debug message constant
	private static final String TAG = "OrmmaView";

	// layout constants
	protected static final int BACKGROUND_ID = 101;
	protected static final int PLACEHOLDER_ID = 100;
	public static final int ORMMA_ID = 102;

	// private constants
	private TimeOut mTimeOut; // timeout for loading a url
	private static String mScriptPath = null; // holds the path for the ormma.js
	private static String mBridgeScriptPath = null; // holds the path for the
													// ormma_bridge.js
	private boolean bPageFinished = false; // boolean flag holding the loading
											// state of a page
	private OrmmaUtilityController mUtilityController; // primary javascript
														// bridge
	private float mDensity; // screen pixel density
	private int mContentViewHeight; // height of the content
	private boolean bKeyboardOut; // state of the keyboard
	private int mDefaultHeight; // default height of the view
	private int mDefaultWidth; // default width of the view
	private int mInitLayoutHeight; // initial height of the view
	private int mInitLayoutWidth; // initial height of the view
	private int mIndex; // index of the view within its viewgroup
	private GestureDetector mGestureDetector; // gesture detector for capturing
												// unwanted gestures
	private ViewState mViewState = ViewState.DEFAULT;  //holds current view state
	private OrmmaViewListener mListener;  //listener for communicated events (back to the parent)
	public String mDataToInject = null;  //javascript to inject into the view
	private String mLocalFilePath;  //local path the the ad html


	/**
	 * Instantiates a new ormma view.
	 * 
	 * @param context
	 *            the context
	 * @param listener
	 *            the listener
	 */
	public OrmmaView(Context context, OrmmaViewListener listener) {
		super(context);
		setListener(listener);
		setScrollContainer(false);
		setVerticalScrollBarEnabled(false);
		setHorizontalScrollBarEnabled(false);
		mGestureDetector = new GestureDetector(new ScrollEater());
		initialize();
	}

	/**
	 * Sets the listener.
	 * 
	 * @param listener
	 *            the new listener
	 */
	public void setListener(OrmmaViewListener listener) {
		mListener = listener;
	}

	/**
	 * Removes the listener.
	 */
	public void removeListener() {
		mListener = null;
	}

	/**
	 * Instantiates a new ormma view.
	 * 
	 * @param context
	 *            the context
	 */
	public OrmmaView(Context context) {
		super(context);
		setScrollContainer(false);
		setVerticalScrollBarEnabled(false);
		setHorizontalScrollBarEnabled(false);
		mGestureDetector = new GestureDetector(new ScrollEater());
		initialize();
	}

	/**
	 * Sets the max size.
	 * 
	 * @param w
	 *            the width
	 * @param h
	 *            the height
	 */
	public void setMaxSize(int w, int h) {
		mUtilityController.setMaxSize(w, h);
	}

	/**
	 * The listener interface for receiving ormmaView events. The class that is
	 * interested in processing a ormmaView event implements this interface, and
	 * the object created with that class is registered with a component using
	 * the component's <code>addOrmmaViewListener<code> method. When
	 * the ormmaView event occurs, that object's appropriate
	 * method is invoked.
	 * 
	 * @see OrmmaViewEvent
	 */
	public interface OrmmaViewListener {

		/**
		 * On ready.
		 * 
		 * @return true, if successful
		 */
		abstract boolean onReady();

		/**
		 * On resize.
		 * 
		 * @return true, if successful
		 */
		abstract boolean onResize();

		/**
		 * On expand.
		 * 
		 * @return true, if successful
		 */
		abstract boolean onExpand();

		/**
		 * On expand close.
		 * 
		 * @return true, if successful
		 */
		abstract boolean onExpandClose();

		/**
		 * On resize close.
		 * 
		 * @return true, if successful
		 */
		abstract boolean onResizeClose();

		/**
		 * On event fired.
		 * 
		 * @return true, if successful
		 */
		abstract boolean onEventFired();
	}

	/**
	 * Inject java script into the view
	 * 
	 * @param str
	 *            the javascript to inject
	 */
	public void injectJavaScript(String str) {
		if (str != null)
			super.loadUrl("javascript:" + str);
	}



	/**
	 * Load a url into the view
	 * 
	 * @param url
	 *            the url
	 * @param dataToInject
	 *            any additional javascript to inject
	 */
	public void loadUrl(String url, String dataToInject) {
		loadUrl(url, false, dataToInject);
	}

	/*
	 * @see android.webkit.WebView#loadUrl(java.lang.String)
	 */
	@Override
	public void loadUrl(String url) {
		loadUrl(url, false, null);
	}

	/**
	 * Load view from html in a local file
	 * 
	 * @param f
	 *            the file
	 * @param dataToInject
	 *            any additional javascript to inject
	 */
	public void loadFile(File f, String dataToInject) {
		try {
			mDataToInject = dataToInject;
			loadInputStream(new FileInputStream(f),  dataToInject);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	/**
	 * The Class TimeOut.  A timertask for terminating the load if it takes too long
	 * If it fires three times without making progress, it will cancel the load
	 */
	class TimeOut extends TimerTask {

		int mProgress = 0;
		int mCount = 0;

		@Override
		public void run() {
			int progress = getProgress();
			if (progress == 100) {
				this.cancel();
			} else {
				if (mProgress == progress) {
					mCount++;
					if (mCount == 3) {
						try{
							stopLoading();
						}
						catch (Exception e){
							Log.w(TAG, "error in stopLoading");
							e.printStackTrace();
						}
						this.cancel();
					}
				}
			}
			mProgress = progress;
		}
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see android.webkit.WebView#clearView()
	 */
	@Override
	public void clearView() {
		reset();
		super.clearView();
	}

	/**
	 * Reset the view. 
	 */
	private void reset() {
		if (mViewState == ViewState.EXPANDED) {
			closeExpanded();
		} else if (mViewState == ViewState.RESIZED) {
			closeResized();
		}
		invalidate();
		mUtilityController.deleteOldAds();
		mUtilityController.stopAllListeners();
		resetLayout();
	}

	/**
	 * Loads the view from an input stream.  Does the real loading work
	 * 
	 * @param is
	 *            the input stream
	 * @param dataToInject
	 *            the data to inject
	 */
	private void loadInputStream(InputStream is, String dataToInject) {
		String url;
		reset();
		if (mTimeOut != null) {
			mTimeOut.cancel();
		}
		mTimeOut = new TimeOut();

		try {
			mLocalFilePath = mUtilityController.writeToDiskWrap(is, CURRENT_FILE, true, mDataToInject,
					mBridgeScriptPath, mScriptPath);
			url = "file://" + mLocalFilePath + java.io.File.separator + CURRENT_FILE;
			Timer timer = new Timer();
			timer.schedule(mTimeOut, 2000, 2000);
			if (mDataToInject != null) {
				injectJavaScript(mDataToInject);
			}

			super.loadUrl(url);
		} catch (IllegalStateException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/**
	 * Load url.
	 * 
	 * @param url
	 *            the url
	 * @param dontLoad
	 *            the dont load
	 * @param dataToInject
	 *            any additional javascript to inject
	 */
	public void loadUrl(String url, boolean dontLoad, String dataToInject) {
		mDataToInject = dataToInject;
		if (!dontLoad) {
			InputStream is = null;
			bPageFinished = false;
			try {
				URL u = new URL(url);
				String name = u.getFile();
				//if it is in the asset directory use the assetmanager
				
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
				loadInputStream(is, dataToInject);
				return;

			} catch (MalformedURLException e) {
			} catch (IOException e) {
				e.printStackTrace();
				return;
			}
		}
		super.loadUrl(url);
	}

	/**
	 * Instantiates a new ormma view.
	 * 
	 * @param context
	 *            the context
	 * @param set
	 *            the set
	 */
	public OrmmaView(Context context, AttributeSet set) {
		super(context, set);
		setVerticalScrollBarEnabled(false);
		setHorizontalScrollBarEnabled(false);
		setScrollContainer(false);
		mGestureDetector = new GestureDetector(new ScrollEater());

		initialize();

		TypedArray a = getContext().obtainStyledAttributes(set, attrs);

		int w = a.getDimensionPixelSize(0, -1);
		int h = a.getDimensionPixelSize(1, -1);

		if (w > 0 && h > 0)
			mUtilityController.setMaxSize(w, h);

		a.recycle();

	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see android.webkit.WebView#onTouchEvent(android.view.MotionEvent)
	 * 
	 * used for trapping scroll events
	 */
	@Override
	public boolean onTouchEvent(MotionEvent ev) {
		boolean ret = mGestureDetector.onTouchEvent(ev);
		if (ret)
			ev.setAction(MotionEvent.ACTION_CANCEL);
		return super.onTouchEvent(ev);
	}

	/**
	 * The message handler.  To keep things in the ui thread.
	 */
	private Handler mHandler = new Handler() {

		@Override
		public void handleMessage(Message msg) {
			Bundle data = msg.getData();
			switch (msg.what) {
			case MESSAGE_SEND_EXPAND_CLOSE:
				if (mListener != null) {
					mListener.onExpandClose();
				}
				break;
			case MESSAGE_RESIZE: {
				mViewState = ViewState.RESIZED;
				ViewGroup.LayoutParams lp = getLayoutParams();
				lp.height = data.getInt(RESIZE_HEIGHT, lp.height);
				lp.width = data.getInt(RESIZE_WIDTH, lp.width);
				String injection = "window.ormmaview.fireChangeEvent({ state: \'resized\'," + " size: { width: "
						+ lp.width + ", " + "height: " + lp.height + "}});";
				injectJavaScript(injection);
				requestLayout();
				if (mListener != null)
					mListener.onResize();
				break;
			}
			case MESSAGE_CLOSE: {
				switch (mViewState) {
				case RESIZED:
					closeResized();
					break;
				case EXPANDED:
					closeExpanded();
					break;
				}

				break;
			}
			case MESSAGE_HIDE: {
				setVisibility(View.INVISIBLE);
				String injection = "window.ormmaview.fireChangeEvent({ state: \'hidden\' });";

				injectJavaScript(injection);
				break;
			}
			case MESSAGE_SHOW: {
				String injection = "window.ormmaview.fireChangeEvent({ state: \'default\' });";
				injectJavaScript(injection);
				setVisibility(View.VISIBLE);
				break;
			}
			case MESSAGE_EXPAND: {
				doExpand(data);
				break;
			}
			case MESSAGE_OPEN: {
				mViewState = ViewState.LEFT_BEHIND;
				break;
			}

			}
			super.handleMessage(msg);
		}

	};

	/**
	 * Do the real work of an expand
	 */
	private void doExpand(Bundle data){
		mViewState = ViewState.EXPANDED;
		Dimensions d = (Dimensions) data.getParcelable(EXPAND_DIMENSIONS);
		String url = data.getString(EXPAND_URL);
		Properties p = data.getParcelable(EXPAND_PROPERTIES);
		if (url != null && !url.equals("undefined"))
			loadUrl(url);

		FrameLayout contentView = (FrameLayout) getRootView().findViewById(R.id.content);
		ViewGroup parent = (ViewGroup) getParent();
		FrameLayout.LayoutParams fl = new FrameLayout.LayoutParams((int) (d.width), (int) (d.height));
		fl.topMargin = (int) (d.x);
		fl.leftMargin = (int) (d.y);
		int index = 0;
		int count = parent.getChildCount();
		for (index = 0; index < count; index++) {
			if (parent.getChildAt(index) == OrmmaView.this)
				break;
		}
		mIndex = index;
		FrameLayout placeHolder = new FrameLayout(getContext());
		placeHolder.setId(PLACEHOLDER_ID);
		ViewGroup.LayoutParams lp = new ViewGroup.LayoutParams(getWidth(), getHeight());
		parent.addView(placeHolder, index, lp);
		parent.removeView(OrmmaView.this);

		FrameLayout backGround = new FrameLayout(getContext());
		if (p.useBackground) {
			int color = p.backgroundColor | ((int) (p.backgroundOpacity * 0xFF) * 0x10000000);

			backGround.setBackgroundColor(color);

		}

		backGround.setOnTouchListener(new OnTouchListener() {

			@Override
			public boolean onTouch(View arg0, MotionEvent arg1) {
				return true;
			}
		});
		FrameLayout.LayoutParams bgfl = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.FILL_PARENT,
				FrameLayout.LayoutParams.FILL_PARENT);
		backGround.setId(BACKGROUND_ID);
		backGround.setPadding((int) (d.x), (int) (d.y), 0, 0);
		backGround.addView(OrmmaView.this, fl);
		contentView.addView(backGround, bgfl);

		String injection = "window.ormmaview.fireChangeEvent({ state: \'expanded\'," + " size: " + "{ width: "
				+ (int) (d.width / mDensity) + ", " + "height: " + (int) (d.height / mDensity) + "}" + " });";

		injectJavaScript(injection);
		if (mListener != null)
			mListener.onExpand();
	}
	/**
	 * Close resized.
	 */
	private void closeResized() {
		if (mListener != null)
			mListener.onResizeClose();
		String injection = "window.ormmaview.fireChangeEvent({ state: \'default\'," + " size: " + "{ width: "
				+ mDefaultWidth + ", " + "height: " + mDefaultHeight + "}" + "});";
		injectJavaScript(injection);
		resetLayout();
	}

	/**
	 * The webview client used for trapping certain events
	 */
	WebViewClient mWebViewClient = new WebViewClient() {
		@Override
		public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
			Log.d("OrmmaView", "error:" + description);
			super.onReceivedError(view, errorCode, description, failingUrl);
		}

		@Override
		public void onPageFinished(WebView view, String url) {
			mDefaultHeight = (int) (getHeight() / mDensity);
			mDefaultWidth = (int) (getWidth() / mDensity);

			mUtilityController.init(mDensity);

		}

		@Override
		public boolean shouldOverrideUrlLoading(WebView view, String url) {
			Uri uri = Uri.parse(url);
			String type = null;
			try {

				if (url.startsWith("tel:")) {
					Intent intent = new Intent(Intent.ACTION_DIAL, Uri.parse(url));
					intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
					getContext().startActivity(intent);
					return true;
				}

				if (url.startsWith("mailto:") || url.startsWith("market:")) {
					Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
					intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
					getContext().startActivity(intent);
					return true;
				}

				HttpClient httpClient = new DefaultHttpClient();
				HttpHead head = new HttpHead(url);
				HttpResponse response;
				response = httpClient.execute(head);
				Header h = response.getFirstHeader("content-type");
				if (h != null) {
					String val = h.getValue();
					if (val.startsWith("video"))
						type = val;
				}
				Intent intent = new Intent();
				intent.setAction(android.content.Intent.ACTION_VIEW);
				if (type != null)
					intent.setDataAndType(uri, type);
				else
					intent.setData(uri);
				intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
				getContext().startActivity(intent);
				return true;

			} catch (Exception e) {
				try {
					Intent intent = new Intent();
					intent.setAction(android.content.Intent.ACTION_VIEW);
					intent.setData(uri);
					intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
					getContext().startActivity(intent);
					return true;
				} catch (Exception e2) {
					return false;
				}
			}

		}

		public void onLoadResource(WebView view, String url) {
			// Log.d(TAG,"lr:"+url);
		};

	};

	/**
	 * The m web chrome client.
	 */
	WebChromeClient mWebChromeClient = new WebChromeClient() {
		@Override
		public boolean onJsAlert(WebView view, String url, String message, JsResult result) {
			Log.d("OrmmaView", message);
			return false;
		}
	};

	/**
	 * The b got layout params.
	 */
	private boolean bGotLayoutParams;

	/**
	 * Initialize the view
	 */
	private void initialize() {
		setBackgroundColor(0);
		DisplayMetrics metrics = new DisplayMetrics();
		WindowManager wm = (WindowManager) getContext().getSystemService(Context.WINDOW_SERVICE);

		wm.getDefaultDisplay().getMetrics(metrics);
		mDensity = metrics.density;

		bPageFinished = false;

		getSettings().setJavaScriptEnabled(true);

		mUtilityController = new OrmmaUtilityController(this, this.getContext());

		addJavascriptInterface(mUtilityController, "ORMMAUtilityControllerBridge");

		setWebViewClient(mWebViewClient);

		setWebChromeClient(mWebChromeClient);
		setScriptPath();

		mContentViewHeight = getContentViewHeight();

		getViewTreeObserver().addOnGlobalLayoutListener(this);
	}

	/**
	 * Gets the content view height.
	 * 
	 * @return the content view height
	 */
	private int getContentViewHeight() {
		View contentView = getRootView().findViewById(R.id.content);
		if (contentView != null) {
			return contentView.getHeight();
		} else
			return -1;
	}

	/**
	 * Sets the script path.
	 */
	private synchronized void setScriptPath() {
		if (mScriptPath == null) {
			mScriptPath = mUtilityController.copyTextFromJarIntoAssetDir("/js/ormma.js", "js/ormma.js");
		}
		if (mBridgeScriptPath == null) {
			mBridgeScriptPath = mUtilityController.copyTextFromJarIntoAssetDir("/js/ormma_bridge.js",
					"js/ormma_bridge.js");
		}
	}

	/**
	 * Close an expanded view.
	 */
	protected synchronized void closeExpanded() {
		FrameLayout contentView = (FrameLayout) getRootView().findViewById(R.id.content);

		FrameLayout placeHolder = (FrameLayout) getRootView().findViewById(PLACEHOLDER_ID);
		FrameLayout background = (FrameLayout) getRootView().findViewById(BACKGROUND_ID);
		ViewGroup parent = (ViewGroup) placeHolder.getParent();
		background.removeView(this);
		contentView.removeView(background);
		resetLayout();
		parent.addView(this, mIndex);
		parent.removeView(placeHolder);
		parent.invalidate();

		String injection = "window.ormmaview.fireChangeEvent({ state: \'default\'," + " size: " + "{ width: "
				+ mDefaultWidth + ", " + "height: " + mDefaultHeight + "}" + "});";

		injectJavaScript(injection);

		mViewState = ViewState.DEFAULT;

		mHandler.sendEmptyMessage(MESSAGE_SEND_EXPAND_CLOSE);
		setVisibility(VISIBLE);
	}

	/**
	 * Close an opened view.
	 * 
	 * @param openedFrame
	 *            the opened frame
	 */
	protected void closeOpened(View openedFrame) {
		((ViewGroup) ((Activity) getContext()).getWindow().getDecorView()).removeView(openedFrame);
		requestLayout();
	}

	/**
	 * Gets the state.
	 * 
	 * @return the state
	 */
	public String getState() {
		return mViewState.toString().toLowerCase();
	}

	/**
	 * Resize the view
	 * 
	 * @param width
	 *            the width
	 * @param height
	 *            the height
	 */
	public void resize(int width, int height) {
		Message msg = mHandler.obtainMessage(MESSAGE_RESIZE);

		Bundle data = new Bundle();
		data.putInt(RESIZE_WIDTH, width);
		data.putInt(RESIZE_HEIGHT, height);
		msg.setData(data);

		mHandler.sendMessage(msg);
	}

	/**
	 * Close the view
	 */
	public void close() {
		mHandler.sendEmptyMessage(MESSAGE_CLOSE);
	}

	/**
	 * Hide the view
	 */
	public void hide() {
		mHandler.sendEmptyMessage(MESSAGE_HIDE);
	}

	/**
	 * Show the view
	 */
	public void show() {
		mHandler.sendEmptyMessage(MESSAGE_SHOW);
	}

	/**
	 * Gets the connectivity manager.
	 * 
	 * @return the connectivity manager
	 */
	public ConnectivityManager getConnectivityManager() {
		return (ConnectivityManager) this.getContext().getSystemService(Context.CONNECTIVITY_SERVICE);
	}

	/**
	 * Dump.
	 */
	public void dump() {
		// TODO Auto-generated method stub
	}

	/**
	 * creates an expand message and throws it to the handler for the real work
	 * 
	 * @param dimensions
	 *            the dimensions
	 * @param URL
	 *            the uRL
	 * @param properties
	 *            the properties
	 */
	public void expand(Dimensions dimensions, String URL, Properties properties) {
		Message msg = mHandler.obtainMessage(MESSAGE_EXPAND);

		Bundle data = new Bundle();
		data.putParcelable(EXPAND_DIMENSIONS, dimensions);
		data.putString(EXPAND_URL, URL);
		data.putParcelable(EXPAND_PROPERTIES, properties);
		msg.setData(data);

		mHandler.sendMessage(msg);
	}

	/**
	 * Open.
	 * 
	 * @param url
	 *            the url
	 * @param back
	 *            show the back button
	 * @param forward
	 *            show the forward button
	 * @param refresh
	 *            show the refresh button
	 */
	public void open(String url, boolean back, boolean forward, boolean refresh) {

		Intent i = new Intent(getContext(), Browser.class);
		Log.d(TAG, "open:" + url);
		i.putExtra(Browser.URL_EXTRA, url);
		i.putExtra(Browser.SHOW_BACK_EXTRA, back);
		i.putExtra(Browser.SHOW_FORWARD_EXTRA, forward);
		i.putExtra(Browser.SHOW_REFRESH_EXTRA, refresh);
		i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		getContext().startActivity(i);

	}
	
	
	public void openMap(String url, boolean fulscreen) {

		//TODO

	}
	
	public void playAudio(String url, boolean autoPlay, boolean controls, boolean loop, boolean inline, String startStyle, String stopStyle) {

		//TODO...

	}
	
	
	public void playVideo(String url, boolean audioMuted, boolean autoPlay, boolean controls, boolean loop, int[] inline, String startStyle, String stopStyle) {

		//TODO...is the int[] param valid?

	}
	
	

	/**
	 * The Class NewLocationReciever.
	 */
	public static abstract class NewLocationReciever {

		/**
		 * On new location.
		 * 
		 * @param v
		 *            the v
		 */
		public abstract void OnNewLocation(ViewState v);
	}

	/**
	 * Reset layout.
	 */
	private void resetLayout() {
		ViewGroup.LayoutParams lp = getLayoutParams();
		lp.height = mInitLayoutHeight;
		lp.width = mInitLayoutWidth;
		setVisibility(VISIBLE);
		requestLayout();
	}

	/**
	 * Checks if is page finished.
	 * 
	 * @return true, if is page finished
	 */
	public boolean isPageFinished() {
		return bPageFinished;
	}

	//trap keyboard state and view height/width
	@Override
	public void onGlobalLayout() {
		boolean state = bKeyboardOut;
		if (!bKeyboardOut && mContentViewHeight >= 0 && getContentViewHeight() >= 0
				&& (mContentViewHeight != getContentViewHeight())) {

			state = true;
			String injection = "window.ormmaview.fireChangeEvent({ keyboardState: true});";
			injectJavaScript(injection);

		}
		if (bKeyboardOut && mContentViewHeight >= 0 && getContentViewHeight() >= 0
				&& (mContentViewHeight == getContentViewHeight())) {

			state = false;
			String injection = "window.ormmaview.fireChangeEvent({ keyboardState: false});";
			injectJavaScript(injection);
		}
		if (mContentViewHeight < 0) {
			mContentViewHeight = getContentViewHeight();
		}

		bKeyboardOut = state;
	}

	/**
	 * Gets the size.
	 * 
	 * @return the size
	 */
	public String getSize() {
		return "{ width: " + (int) (getWidth() / mDensity) + ", " + "height: " + (int) (getHeight() / mDensity) + "}";
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see android.webkit.WebView#onAttachedToWindow()
	 * 
	 * Gather some initial information about the view.
	 */
	@Override
	protected void onAttachedToWindow() {
		if (!bGotLayoutParams) {
			ViewGroup.LayoutParams lp = getLayoutParams();
			mInitLayoutHeight = lp.height;
			mInitLayoutWidth = lp.width;
			bGotLayoutParams = true;
		}
		super.onAttachedToWindow();
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see android.webkit.WebView#saveState(android.os.Bundle)
	 */
	@Override
	public WebBackForwardList saveState(Bundle outState) {
		outState.putString(AD_PATH, mLocalFilePath);
		return null;
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see android.webkit.WebView#restoreState(android.os.Bundle)
	 */
	@Override
	public WebBackForwardList restoreState(Bundle savedInstanceState) {

		mLocalFilePath = savedInstanceState.getString(AD_PATH);

		String url = "file://" + mLocalFilePath + java.io.File.separator + CURRENT_FILE;
		super.loadUrl(url);

		return null;
	}

	/**
	 * The Class ScrollEater.
	 */
	class ScrollEater extends SimpleOnGestureListener {

		/*
		 * (non-Javadoc)
		 * 
		 * @see
		 * android.view.GestureDetector.SimpleOnGestureListener#onScroll(android
		 * .view.MotionEvent, android.view.MotionEvent, float, float)
		 * 
		 * Gesture detector for eating scroll events
		 */
		@Override
		public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX, float distanceY) {
			return true;
		}
	}

	/**
	 * Checks if is expanded.
	 * 
	 * @return true, if is expanded
	 */
	public boolean isExpanded() {
		return mViewState == ViewState.EXPANDED;
	}
}
