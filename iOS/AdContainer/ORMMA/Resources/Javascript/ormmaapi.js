/**
 * ORMMA Javascript API Include File
 */

/******************************************************************/
/***************** STANDARD ORMMA CONSTANT VALUES *****************/
/******************************************************************/

const ORMMA_UNKNOWN_VALUE = -1;
 
const ORMMA_ORIENTATION_UNKNOWN              = UNKNOWN_VALUE;
const ORMMA_ORIENTATION_PORTRAIT             = 0;
const ORMMA_ORIENTATION_LANDSCAPE_RIGHT      = 90;
const ORMMA_ORIENTATION_PORTRAIT_UPSIDE_DOWN = 190;
const ORMMA_ORIENTATION_LANDSCAPE_LEFT       = 270;
 
const ORMMA_NETWORK_UNKNOWN = "unknown";
const ORMMA_NETWORK_OFFLINE = "offline";
const ORMMA_NETWORK_CELL    = "cell";
const ORMMA_NETWORK_WIFI    = "wifi";
 
const ORMMA_STATE_UNKNOWN  = "unknown";
const ORMMA_STATE_HIDDEN   = "hidden";
const ORMMA_STATE_DEFAULT  = "default";
const ORMMA_STATE_EXPANDED = "expanded";
 


/*************************************************************/
/***************** ORMMA JSON PROPERTY NAMES *****************/
/*************************************************************/

const ORMMA_PROPERTY_HEIGHT = "height";
const ORMMA_PROPERTY_WIDTH  = "width";
const ORMMA_PROPERTY_X = "x";
const ORMMA_PROPERTY_Y = "y";
const ORMMA_PROPERTY_Z = "z";
const ORMMA_PROPERTY_TRANSITION = "transition";
const ORMMA_PROPERTY_LATITUDE = "lat";
const ORMMA_PROPERTY_LONGITUDE = "lon";
const ORMMA_PROPERTY_ACCURACY = "acc";
const ORMMA_PROPERTY_INTENSITY = "intensity";
const ORMMA_PROPERTY_INTERVAL = "interval";

 
/**
 * The main ad controller object
 * @namespace encapusaltes all methods of the ORMMA JavaScript API
 */
window.Ormma = {
	
	
	/**********************************************************************/
	/***************** INTERNAL STATE, NOT FOR PUBLIC USE *****************/
	/**********************************************************************/
	
	/** stores the list of URLs and their aliases that have been cached */
	aliases = { },
	
	/** stores the lask known amount of cache remaining */
	cacheRemaining = ORMMA_UNKNOWN_VALUE,

	/** stores the current expand properties */
	expandProperties = { },

	/** stores the last known heading */
	heading = ORMMA_UNKNOWN_VALUE,
	
	/** stores the last known location */
	location = { ORMMA_PROPERTY_LATITUDE  : ORMMA_UNKNOWN_VALUE, 
		         ORMMA_PROPERTY_LONGITUDE : ORMMA_UNKNOWN_VALUE },
	
	/** stores the maximum size of the ad */
	maxSize = { ORMMA_PROPERTY_HEIGHT : ORMMA_UNKNOWN_VALUE, 
		        ORMMA_PROPERTY_WIDTH  : ORMMA_UNKNOWN_VALUE };

	/** stores the last known network state */
	network = ORMMA_NETWORK_UNKNOWN,
	
	/** stores the last known orientation */
	orientation = ORMMA_UNKNOWN_VALUE,
	
	/** stores the current resize properties */
	resizeProperties = { ORMMA_PROPERTY_TRANSITION : ORMMA_STATE_UNKNOWN },
	
	/** stores the current screen size */
	screenSize = { ORMMA_PROPERTY_HEIGHT : ORMMA_UNKNOWN_VALUE, 
		           ORMMA_PROPERTY_WIDTH  : ORMMA_UNKNOWN_VALUE },
	
	/** stores the current properties defining a shake */
	shakeProperties = { },
	
	/** stores the last known size of the ad */
	size = { ORMMA_PROPERTY_HEIGHT : ORMMA_UNKNOWN_VALUE, 
			 ORMMA_PROPERTY_WIDTH  : ORMMA_UNKNOWN_VALUE },
	
	/** stores the last known display state */
	state = ORMMA_STATE_UNKNOWN,
	
	/** stores the list of features supported by the device */
	supportedFeatures = [ ],


	
	/**********************************************/
	/***************** PUBLIC API *****************/
	/**********************************************/
	
	
	/**
	 * Use this method to request that a specific resource, as specified by
	 * the passed URL be cached.
	 *
	 * <br/>#side effects: if the requested resource is not already cached, use
	 *                     of this method will attempt to bring up the network.
	 *                     Additionally, the actual resource will be retrieved
	 *                     asynchronously, so it is incumbent upon the caller
	 *                     to listen for the response event.
	 * <br/>#ORMMA Level: 3 
	 *
	 * @param {url} the URL to cache
	 */
	addAsset : function( url ) {
		window.ormmaBridge.executeNativeAddAsset( url );
	},
	
	
	/**
	 * Use this method to request that the specified set of resources be locally
	 * cached.
	 *
	 * <br/>#side effects: if any requested resource is not already cached, use
	 *                     of this method will attempt to bring up the network.
	 *                     Additionally, the actual resources will be retrieved
	 *                     asynchronously, so it is incumbent upon the caller
	 *                     to listen for the response event.
	 * <br/>#ORMMA Level: 3 
	 *
	 * @param {Array} the list of URLs to cache
	 */
	addAssets : function( assets ) {
		// TODO
	},
	
	
	/**
	 * Use this method to subscribe a specific handler method to a specific
	 * event. In this way, multiple listeners can subscribe to a specific event, 
	 * and a single listener can handle multiple events. The events are:
	 *   
	 * <table>
	 *   <tr><td>ready</td><td>report initialize complete</td></tr>
	 *   <tr><td>network</td><td>report network connectivity changes</td></tr>
	 *   <tr><td>keyboard</td><td>report soft keyboard changes</td></tr>
	 *   <tr><td>orientation</td><td>report orientation changes</td></tr>
	 *   <tr><td>heading</td><td>report heading changes</td></tr>
	 *   <tr><td>location</td><td>report location changes</td></tr>
	 *   <tr><td>rotation</td><td>report rotation changes</td></tr>
	 *   <tr><td>shake</td><td>report device being shaken</td></tr>
	 *   <tr><td>state</td><td>report state changes</td></tr>
	 *   <tr><td>tilt</td><td>report tilt changes</td></tr>
	 * </table>
	 *
	 * <br/>#side effects: registering listeners for device features may power 
	 *                     up sensors in the device that will reduce the device
	 *                     battery life. 
	 * <br/>#ORMMA Level: 1 
	 *
	 * @param {String} event name of event to listen for
	 * @param {Function} listener function name / anonymous function to execute 
	 */
	addEventListener : function( evt, listener ) {
		window.addEventListener( evt, listener, false );
	},
	
	
	/**
	 * Use this method to return a resized ad to the default position or an
	 * expanded ad to its pre-expanded position within the UI. The SDK is 
	 * responsible for the correct size of the ad within the app UI.
	 *
	 * <br/>#side effects: changes state
	 * <br/>#ORMMA Level: 1
	 * 
	 * @throws stateChange 
	 * @throws resizeChange
	 */
	close : function() {
		window.ormmaBridge.executeNativeClose();
	},
	
	
	/**
	 * Use this method to create a new event in the device's calander.
	 *
	 * NOTE: before using this API method, callers should verify that the
	 *       implementation supports this feature by calling the "supports"
	 *       method.
	 *
	 * <br/>#side effects: none
	 * <br/>#ORMMA Level: 1
	 */
	createEvent : function( date, title, body ) {
		// TODO
	},
	
	
	/**
	 * Use this method to open a separate overlay ad container view at the
	 * highest z-order of the window's view.
	 *
	 * dimensions: Object { x, y, w, h } - contains the origin and size of the
	 *                                     view.
	 *
	 * <br/>#side effects: changes state
	 * <br/>#ORMMA Level: 1
	 * 
	 * @param {JSON} initialDimensions an object describing the initial position
	 *                                 of the overlay view before the expand
	 *                                 transition occurs.
	 * @param {JSON} finalDimensions the final position of the overlay view
	 *                               after the expand transition occurs.
	 * @param {String} url (optional) The URL for the document to be displayed
	 *                                in the overlay view. If null, the body of
	 *                                the current ad will be used. 
	 *
	 * @throws stateChange
	 * @throws resizeChange 
	 */
	expand : function( initialDimensions, finalDimensions, URL ) {
		// TODO
		window.ormmaBridge.executeNativeExpand(  );
	},
	
	
	/**
	 * Use this method to determine the cached alias for the specified URL.
	 *
	 * NOTE: The specified resource must have been cached AND the cache 
	 *       operation must be complete in order to receive a meaningful
	 *       return value.
	 *
	 * <br/>#side effects: none
	 * <br/>#ORMMA Level: 1
	 *
	 * @returns the alias name
	 */
	getAssetURL : function ( url ) {
		// TODO
	},
	
	
	/**
	 * Use this method to determine the amount of cache remaining.
	 *
	 * <br/>#side effects: none
	 * <br/>#ORMMA Level: 3
	 *
	 * @returns the amount of cache remainig, or -1 if unknown.
	 */
	getCacheRemaining : function() {
		return this.cacheRemaining;
	},
	
	
	/**
	 * Use this method to get the properties for expanding an ad.
	 *
	 * <p>properties object<br/>
	 * <code>
	 * properties = {
	 *  "transition" : "default|dissolve|fade|roll|slide|zoom|none",
	 *  "navigation" : "none|close|back|forward|refresh",
	 *  "use-background" : "true|false",
	 *  "background-color" : "#rrggbb",
	 *  "background-opacity" : "n.n",
	 *  "is-modal" : "true|false"
	 * }
	 * </code></p>
	 * 
	 * <pre>
	 * "transition"
	 * If "transition" is not specified in the properties object, a value of
	 * "default" is assumed.
	 * 
	 * "navigation"
	 * If "navigation" is not specified in the properties object, a value of
	 * "none" is assumed.
	 * 
	 * "useBackground"
	 * "useBackground" should contain a boolean value (true/false) indicating
	 * the presence of a background. If "useBackground" is not specified in the 
	 * properties object, a value of false is assumed.
	 * 
	 * "backgroundColor"
	 * "backgroundColor" is a standard numeric RGB value (most logically
	 * expressed in hexadecimal with two digits each for red, green, and blue).
	 * 
	 * "backgroundOpacity"
	 * "backgroundOpacity" is a number between 0 and 1 inclusively (ranging
	 * from 0 equaling fully transparent to 1 equaling fully opaque). If either
	 * "backgroundColor" or "backgroundOpacity" is not specified in the 
	 * properties object, values of 0xffffff and 1.0 respectively are assumed.
	 * 
	 * "isModal"
	 * The "isModal" property is a boolean value (true/false) and if it is not
	 * specified in the properties object a value of false is assumed.
	 * </pre>
	 * 
	 * <br/>#side effects: none
	 * <br/>#ORMMA Level: 1
	 *
	 * @returns {JSON} this object contains all the web viewer properties
	 *                 besides dimension that are supported by the SDK vendor.
	 * @see properties object 
	 */
	getExpandProperties : function() {
		return this.expandProperties;
	},
	
	
	/**
	 * Retrieves the last known heading, if any.
	 *
	 * NOTE: this method will only return meaningful results if the location
	 *       has been previously determined.
	 *
	 * <br/>#side effects: none
	 * <br/>#ORMMA Level: 2
	 *
	 * @returns {Number} degrees from true north, or -1 if unknown.
	 */
	getHeading : function() {
		return this.heading;
	},
	
	
	/**
	 * Use this method to return the last known location.
	 *
	 * NOTE: this method will only return meaningful results if the location
	 *       has been previously determined.
	 *
	 * <br/>#side effects: none
	 * <br/>#ORMMA Level: 2
	 *
	 * @returns {JSON} {lat, long, acc} location information.
	 */
	getLocation : function() {
		return this.location;
	},
	
	
	/*
	 * Use this method to return the maximum size an ad can grow to using the 
	 * resize() method. 
	 * This may be set by the developer, or be the size of the parent view.
	 * 
	 * <br/>#side effects: none
	 * ORMAA Level: 1
	 * 
	 * @returns {JSON} {height, width} - the maximum height and width the view
	 * can grow to 
	 */
	getMaxSize : function() {
		return this.maxSize;
	},
	
	
	/**
	 * Use this method to retrieve the last known network state.
	 *
	 * <br/>#side effects: none
	 * ORMMA Level: 1
	 *
	 * @returns {String} the last known network state. Should be one of:
	 *                   unknown, offline, cell, or wifi.
	 */
	getNetwork : function() {
		return this.network;
	},
	
	
	/**
	 * Use this method to retrieve the last known orientation.
	 *
	 * <br/>#side effects: none
	 * ORMMA Level: 1
	 *
	 * @returns {Number} the last known orientation.
	 */
	getOrientation : function() {
		return this.orientation;
	}
	
	
	/**
	 * Use this method to get the current resize properties of the web viewer.
	 * Since the resize action is asynchronous, this value does not update until
	 * the action has completed execution (when the resizeChange" event fires).
	 *
	 * <p>properties object<br/>
	 * <code>
	 *   properties = {
	 *     "transition" : "default|dissolve|zoom|none",
	 *   }
	 * </code></p>
	 *
	 * "transition" - If "transition" is not specified in the properties object,
	 * a value of "default" is assumed.
	 *
	 * <br/>#side effects: none
	 * <br/>#ORMMA Level: 1
	 *
	 * @returns {JSON} { transition } properties object
	 */
	getResizeProperties : function() {
		return this.resizeProperties;
	},
	
	
	/**
	 * Use this method to retrieve size of the screen.
	 *
	 * <br/>#side effects: none
	 * ORMMA Level: 1
	 *
	 * @returns {JSON} {width, height} the size of the screen.
	 */
	getScreenSize : function() {
		return this.screenSize;
	},
	
	
	/**
	 * Use this method to retrieve current shake properties.
	 *
	 * <br/>#side effects: none
	 * ORMMA Level: 2
	 *
	 * @returns {JSON} {interval, intensity} the properties defining shake.
	 */
	getShakeProperties : function() {
		return this.shakeProperties;
	},
	
	
	/**
	 * Use this method to retrieve size of the ad view.
	 *
	 * <br/>#side effects: none
	 * ORMMA Level: 1
	 *
	 * @returns {JSON} {width, height} the size of the ad view.
	 */
	getSize : function() {
		return this.size;
	},
	
	
	/**
	 * This method returns whether the ad is in its default, fixed position or
	 * is in an expanded, larger position.
	 * 
	 * <br/>#side effects: none
	 * <br/>#ORMMA Level: 1
	 *
	 * @returns {String} "default", "expanded", or "hidden" 
	 */
	getState : function() {
		return this.state;
	},
	
	
	/**
	 * Use this method to hide the web viewer. The method has no return value
	 * and is executed asynchronously (so always listen for a result event
	 * before taking action instead of assuming the change has occurred).
	 *
	 * <br/>#side effects: changes state
	 * <br/>#ORMMA Level: 1
	 * 
	 * @throws stateChange 
	 * @throws resizeChange
	 */
	hide : function() {
		window.ormmaBridge.executeNativeHide();
	},
	
	
	/**
	 * Use this method to make a telephone call.
	 *
	 * NOTE: before using this API method, callers should verify that the
	 *       implementation supports this feature by calling the "supports"
	 *       method.
	 *
	 * <br/>#side effects: none
	 * <br/>#ORMMA Level: 2
	 * 
	 * @param {String} phone number to dial.
	 */
	makeCall : function( number ) {
		window.ormmaBridge.executeNativeHide( number );
	},
	
	
	open : function() {
	},
	
	
	/**
	 * Use this method to remove all cached resources for the current creative.
	 *
	 * <br/>#side effects: use of this function will affect ALL resources for
	 *                     the current creative.
	 * <br/>#ORMMA Level: 3
	 *
	 * @throws assetRemoved
	 */
	removeAllAssets : function() {
		window.ormmaBridge.executeNativeRemoveAllAssets();
	},
	
	
	/**
	 * Use this method to remove a set of cached resources for the current
	 * creative.
	 *
	 * <br/>#side effects: none.
	 * <br/>#ORMMA Level: 3
	 *
	 * @param {Array} list of assets to remove.
	 *
	 * @throws assetRemoved
	 */
	removeAsset : function( url ) {
		window.ormmaBridge.executeNativeRemoveAsset( url );
	},
	
	
	/**
	 * Use this method to remove a set of cached resources for the current
	 * creative.
	 *
	 * <br/>#side effects: none.
	 * <br/>#ORMMA Level: 3
	 *
	 * @param {Array} list of assets to remove.
	 *
	 * @throws assetRemoved
	 */
	removeAssets : function( assets ) {
		// TODO
	},
	
	
	/**
	 * Use this method to unsubscribe a specific handler method from a specific
	 * event. Event listeners should always be removed when they are no longer 
	 * useful to avoid errors. If no listener function is provided, then all
	 * functions listening to the event will be removed.
	 * 
	 * <br/>#side effects: none
	 * <br/>#ORMMA Level: 1
	 * 
	 * @param {String} event name of event
	 * @param {Function} listener (optional) function to be removed 
	 */    
	removeEventListener : function( evt, listener ) {
		window.removeEventListener( evt, listener, false );
	},
	
	
	/**
	 * The method executes asynchronously, but returns a Boolean value of false
	 * to facilitate use in anchor tags. There is also an option explicitly for
	 * metrics tracking that will cache requests offline and execute them
	 * whenever the device reconnects. 
	 *
	 * <br/>#side effects: network traffic and new views depending on display
	 *                     values.
	 * <br/>#ORMMA Level: 1
	 * 
	 * @param {String} uri the fully qualified URL of the page or call to action
	 *                     asset.
	 * @param {String} display the display style for the call to action.
	 * @returns {Boolean} false, so click events can stop propogatiing.
	 * @throws response
	 */
	request : function( uri, display ) {
		window.ormmaBridge.executeNativeRequest( uri, display );
		return false;
	},
	
	
	/**
	 * Use this method to resize the main ad view to the desired size. The views
	 * place in the view hierarchy will not change, so the effect on other views
	 * is up to the app developer.
	 * 
	 * <br/>#side effects: changes state
	 * <br/>#ORMMA Level: 1
	 * 
	 * @param {Integer} height the height in pixels
	 * @param {Integer} width the width in pixels 
	 * @throws resizeChange
	 * @throws stateChange
	 */
	resize : function( height, width ) {
		// TODO
	},
	
	
	/**
	 * Use this method to send an email.
	 *
	 * NOTE: before using this API method, callers should verify that the
	 *       implementation supports this feature by calling the "supports"
	 *       method.
	 *
	 * <br/>#side effects: none
	 * <br/>#ORMMA Level: 1
	 */
	sendMail : function() {
		// TODO
	},
	
	
	/**
	 * Use this method to send an SMS text message.
	 *
	 * NOTE: before using this API method, callers should verify that the
	 *       implementation supports this feature by calling the "supports"
	 *       method.
	 *
	 * <br/>#side effects: none
	 * <br/>#ORMMA Level: 1
	 */
	sendSMS : function() {
		// TODO
	},
	
	/**
	 * Use this method to set the ad's expand properties.
	 *
	 * <br/>#side effects: none -- need to call expand
	 * <br/>#ORMMA Level: 1
	 * 
	 * @param {JSON} properties object representing all properties to set before
	 *               expanding
	 * @see getExpandProperties
	 * @see expand
	 */
	setExpandProperties : function( properties ) {
		window.ormmaBridge.expandProperties = properties;
	},
	
	
	/**
	 * Use this method to set the ads resize properties.
	 *
	 * <br/>#side effects: none
	 * <br/>#ORMMA Level: 1
	 * 
	 * @param {JSON} properties this object contains any number of properties,
	 * such as transition, that might be used by the SDK when resizing the web 
	 * viewer, for more info @see properties object.
	 */
	setResizeProperties : function( properties ) {
		window.ormmaBridge.resizeProperties = properties;
	},
	
	
	setShakeProperties : function() {
		// TODO
	},
	
	
	/**
	 * This method has no return value and is executed asynchronously (so always
	 * listen for a result event before taking action instead of assuming the
	 * change has occurred).
	 *
	 * <br/>#side effects: changes the state value.
	 * <br/>#ORMMA Level: 1
	 *
	 * @throws stateChange 
	 */
	show : function () {
		// TODO
	},
	
	
	/**
	 * Determines if a given feature is available for the current device.
	 *
	 * The features are:
	 * <table>
	 *   <tr><td>calendar   </td><td>the device can create a calendar entry</td></tr>
	 *   <tr><td>email      </td><td>the device can compose an email</td></tr>
	 *   <tr><td>heading    </td><td>the device can report on the compass direction it is pointing</td></tr>
	 *   <tr><td>location   </td><td>the device can report on its location</td></tr>
	 *   <tr><td>network    </td><td>the device can report on its network connectivity and connectivity changes</td></tr>
	 *   <tr><td>orientation</td><td>the device can report on its orientation and orientation changes</td></tr>
	 *   <tr><td>phone      </td><td>the device can make a phone call</td></tr>
	 *   <tr><td>rotation   </td><td>the device can report on its rotation and rotation changes</td></tr>
	 *   <tr><td>shake      </td><td>the device can report on being shaken</td></tr>
	 *   <tr><td>size       </td><td>the device can report on the screen size</td></tr>
	 *   <tr><td>sms        </td><td>the device can send text/sms messages</td></tr>
	 *   <tr><td>tilt       </td><td>the device can report on its tilt and tilt changes</td></tr>
	 * </table>
	 *
	 * <br/>#side effects: none
	 * <br/>#ORMMA Level: 1
	 * 
	 * @param {String} feature name of feature 
	 * @returns {Boolean } true, the feature is supported and getter and events
	 *                           are available; 
	 *                     false, the feature is not supported 
	 */
	supports : function( feature ) {
		return ( this.supportedFeatures.indexOf( feature ) != -1 );
	},
	
	
	/**
	 * Use this method to determine the current version of this implementation
	 * of the ORMMA Javascript API
	 *
	 * <br/>#side effects: none
	 * <br/>#ORMMA Level: 1
	 *
	 * @returns {String} the version number
	 */
	version : function() {
		return "0.1";
	},

	
};
