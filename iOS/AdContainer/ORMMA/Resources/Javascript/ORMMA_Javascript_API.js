/**
 * ORMMA is the constructor for the standard ad API.
 *
 * NOTE: An instance of this object will be created automatically and should
 *       not be instantiated directly.
 *
 * @returns a new object
 */
function ORMMA() 
{
	this.version = "0.1";
	this.eventListeners = { };
}



/**************************************************************************/
/***************** PRIVATE METHODS, FOR INTERNAL USE ONLY *****************/
/**************************************************************************/



/**
 * fireListenersForEvent executes all listeners registered for the specified
 * event. The listeners will be fired sequentially, in the order that they
 * were registered.
 *
 * NOTE: This function is called internally and is not intended for public use.
 *
 * @param {event} String, the name of the event.
 *
 * @returns nothing.
 */
ORMMA.prototype.fireListenersForEvent = function( event )
{
	var listeners = this.listenersForEvent( event.name ); 
	for ( var index = 0; index < listeners.length; index++ )
	{
		listeners[index]( event );
	}
}



/**
 * listenersForEvent retrieves all the listeners for the specified event name.
 *
 * NOTE: This function is called internally and is not intended for public use.
 *
 * @param {event} String, the name of the event.
 *
 * @returns array, the listeners for the event.
 */
ORMMA.prototype.listenersForEvent = function( event )
{
	var listenersForEvent = this.eventListeners[event];
	if ( listenersForEvent == null )
	{
		listenersForEvent = new Array();
		this.eventListeners[event] = listenersForEvent;
	}
	return listenersForEvent;
}



/**********************************************************************/
/*************************** PUBLIC METHODS ***************************/
/**********************************************************************/



/**
 * addAsset requests that the specified resource be cached locally using the
 * alias specified.
 *
 * @param {alias} String, how to reference the resource locally.
 * @param {uri} String, the source uri of the resource to cache.
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.addAsset = function( alias, uri )
{
	ormmaNativeBridge.executeNativeAddAsset( "addasset", alias, uri );
	return false;
}



/**
 * addAsset requests that the specified list of resource be cached locally
 * using the information specified.
 *
 * @param {assets} array of assets to cache. Each entry must contain
 * both an "alias" and a "uri" property.
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.addAssets = function( assets )
{
	// walk list of assets
	var i;
	for ( i = 0; i < assets.count; i++ )
	{
		this.addAsset( assets[i].alias, assets[i].uri );
	}
	return false;
}



/**
 * addEventListener adds a listener to be called when the specified event is
 * fired.
 *
 * @param {event} String, the name of the event for which to register.
 * @param {listener} Function, the function to call when the event is fired.
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.addEventListener = function( event, listener )
{
	var listeners = this.listenersForEvent( event ); 
	if ( listeners.indexOf( listener ) == -1 )
	{
		listeners.push( listener );
		if ( listeners.length == 1 )
		{
			// enable native events
			ormmaNativeBridge.enableNativeEventsForService( event, "yes" );
		}
	}
		
	return false;
}



/**
 * cacheRemaining retrieves the amount of cache remaining on the local device.
 *
 * @returns Number, the amount of cache remaining (in bytes)
 */
ORMMA.prototype.cacheRemaining = function()
{
	return ormmaNativeBridge.cacheRemaining;
}



/**
 * close requests that the current ad be restored to it's default ("closed")
 * state. Does nothing if the ad is already in the default state.
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.close = function()
{
	ormmaNativeBridge.executeNativeClose();
	return false;
}



/**
 * email requests that an email be sent using the specified properties.
 *
 * @param {to}      String, the recipient of the message
 * @param {subject} Strng, the subject of the message
 * @param {body}    String, the body of the message
 * @param {html}    Boolean, true if the body is HTML, false otherwise
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.email = function( to, subject, body, html )
{
	
	ormmaNativeBridge.executeEMail( to, subject, body, html );
	return false;
}



/**
 * expand requests that the specified URL be loaded into a new view. The view
 * will initially be located at initialDimensions and will animate to the
 * location/size specified in finalDimensions.
 *
 * @param {initialDimensions} ORMMADimensions, the initial starting place of the
 *                            new view.
 * @param {finalDimensions} ORMMADimensions, the final location of the new view.
 * @param {URL} String, the URL to load into the new view.
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.expand = function( initialDimensions, finalDimensions, URL )
{
	ormmaNativeBridge.executeNativeExpand( initialDimensions, finalDimensions, URL );
	return false;
}



/**
 * getExpandProperties retrieves the properties to be used (or last used) when
 * executing the expand function.
 *
 * @returns ORMMAExpandProperties, the properties.
 */
ORMMA.prototype.getExpandProperties = function()
{
	return ormmaNativeBridge.expandProperties;
}



/**
 * getHeading retrieves the last known heading.
 *
 * @returns ORMMAHeading, the heading.
 */
ORMMA.prototype.getHeading = function()
{
	return ormmaNativeBridge.heading;
}



/**
 * getLocation retrieves the last known location information, if any.
 *
 * @returns ORMMALocation, the location.
 */
ORMMA.prototype.getLocation = function()
{
	return ormmaNativeBridge.location;
}



/**
 * getMaxSize retrieves the maximum size to which the default ad may be resized.
 *
 * @returns ORMMASize, the size.
 */
ORMMA.prototype.getMaxSize = function()
{
	return ormmaNativeBridge.maxSize;
}



/**
 * getNetwork retrieves the last known network state.
 *
 * @returns String, last known network state.
 *                  "unknown" - network state is unknown
 *                  "offline" - device is offline
 *                  "cell"    - device is on a cellular network
 *                  "wifi"    - device is on a wifi network
 */
ORMMA.prototype.getNetwork = function(  )
{
	return ormmaNativeBridge.network;
}



/**
 * getOrientation retrieves the last known orientation.
 *
 * @returns Number, the orientation, in degrees.
 *                    0 - Portrait
 *                   90 - Landscape, Right
 *                  180 - Portrait, Upside Down
 *                  270 - Landscape, Left
 */
ORMMA.prototype.getOrientation = function()
{
	return ormmaNativeBridge.orientation;
}



/**
 * getResizeDimensions retrieves the current dimensions of the ad.
 *
 * @returns ORMMADimensions, the current resize dimensions.
 */
ORMMA.prototype.getResizeDimensions = function()
{
	return ormmaNativeBridge.resizeDimensions;
}



/**
 * getResizeProperties retrieves the current display properties of the ad.
 *
 * @returns ORMMAResizeProperties, the current resize properties.
 */
ORMMA.prototype.getResizeProperties = function()
{
	return ormmaNativeBridge.resizeProperties;
}



/**
 * getScreenSize retrieves the current size (dimensions) of the screen in points.
 *
 * @returns ORMMASize, the current size of the screen.
 */
ORMMA.prototype.getScreenSize = function()
{
	return ormmaNativeBridge.screenSize;
}



/**
 * getShakeProperties retrieves the current shake properties.
 *
 * @returns ORMMAShakeProperties, the shake properties.
 */
ORMMA.prototype.getShakeProperties = function()
{
	return ormmaNativeBridge.shakeProperties;
}



/**
 * getState retrieves the current display state of the ad.
 *
 * @returns String, the current display state.
 *                  "hidden"   - as is not visible
 *                  "default"  - ad is in the default state
 *                  "expanded" - ad is in an expanded state
 */
ORMMA.prototype.getState = function()
{
	return ormmaNativeBridge.state;
}



/**
 * hide requests that the entire ad be hidden.
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.hide = function()
{
	ormmaNativeBridge.executeNativeHide();
	return false;
}



/**
 * removeAllAssets requests that all cached assets be removed.
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.removeAllAssets = function()
{
	// TODO
	return false;
}



/**
 * removeAsset requests that the cached resource referenced by the specified 
 * alias be removed.
 *
 * @param {alias} String, the name of the resource to remove.
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.removeAsset = function( alias )
{
	ormmaNativeBridge.executeNativeRemoveAsset( alias );
	return false;
}



/**
 * removeEventListener removes the specified listener from the event.
 *
 * @param {event} String, the name of the event.
 * @param {listener} Function, the listener to remove.
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.removeEventListener = function( event, listener )
{
	var listeners = this.listenersForEvent( event ); 
	var index = listeners.indexOf( listener );
	if ( index != -1 )
	{
		listeners.splice( index, 1 );
	}
	if ( listeners.length == 0 )
	{
		// disable the native events
		ormmaNativeBridge.enableNativeEventsForService( event, "no" );
	}
	
	return false;
}



/**
 * request requests that the specified URI be displayed.
 *
 * @param {uri} String, the uri to display.
 * @param {display} String, the display state.
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.request = function( uri, display )
{
	ormmaNativeBridge.executeNativeRequest( uri, display );
	return false;
}



/**
 * request requests that the ad be resized.
 *
 * @param {height} ORMMADimensions, the new dimensions of the ad.
 * @param {height} ORMMADimensions, the new dimensions of the ad.
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.resize = function( height, width )
{
	// call the resize function
	ormmaNativeBridge.executeNativeResize( height, width );
	return false;
}



/**
 * setExpandProperties updates the properties to be used when expanding ads.
 *
 * @param {dimensions} ORMMAExpandProperties, the new properties to use.
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.setExpandProperties = function( properties )
{
	ormmaNativeBridge.expandProperties = properties;
	return false;
}



/**
 * setResizeProperties updates the properties to be used when resizing ads.
 *
 * @param {dimensions} ORMMAResizeProperties, the new properties to use.
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.setResizeProperties = function( properties )
{
	ormmaNativeBridge.resizeProperties = properties;
	return false;
}



/**
 * setShakeProperties updates the properties to be used to identify a shake.
 *
 * @param {properties} ORMMAShakeProperties, the new properties to use.
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.setShakeProperties = function( properties )
{
	ormmaNativeBridge.shakeProperties = properties;
	return false;
}



/**
 * show requests that the ad be displayed to the user.
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.show = function()
{
	ormmaNativeBridge.executeNativeShow();
	return false;
}



/**
 * sms requests that an SMS be sent using the specified properties.
 *
 * @param {to}      String, the recipient of the message
 * @param {body}    String, the body of the message
 *
 * @returns false (for use in links)
 */
ORMMA.prototype.sms = function( to, subject )
{
	
	ormmaNativeBridge.executeEMail( to, subject, body );
	return false;
}



/**
 * supports retrieves a list of features that the device supports.
 *
 * @returns array, a list of Strings denoting each feature.
 */
ORMMA.prototype.supports = function( feature )
{
	return ( ormmaNativeBridge.supportedFeatures.contains( feature ) );
}



/******************************************************************/
/************************** ORMMA EVENTS **************************/
/******************************************************************/



/**
 * ORMMAAssetReadyEvent: fired whenever an asset has been cached.
 */
function ORMMAAssetReadyEvent()
{
	this.name = "assetReady";
	this.alias = "";
}



/**
 * ORMMAAssetRemovedEvent: fired whenever an asset is removed from the cache.
 */
function ORMMAAssetRemovedEvent()
{
	this.name = "assetRemoved";
	this.alias = "";
}



/**
 * ORMMAAssetRetiredEvent: fired whenever an asset is retired from the cache.
 */
function ORMMAAssetRetiredEvent()
{
	this.name = "assetRetired";
	this.alias = "";
}



/**
 * ORMMAErrorEvent: fired whenever an error occurs.
 */
function ORMMAErrorEvent()
{
	this.name = "error";
	this.message = "";
	this.action = null;
}



/**
 * ORMMAHeadingChangeEvent: fired whenever heading (compass) data is available.
 */
function ORMMAHeadingChangeEvent()
{
	this.name = "headingChange";
	this.magneticHeading = -1;
	this.trueHeading = -1;
	this.accuracy = -1;
	this.timestamp = 0;
}



/**
 * ORMMAKeyboardChangeEvent: fired whenever the soft keyboard has been either
 * displayed or put away.
 */
function ORMMAKeyboardChangeEvent()
{
	this.name = "keyboardChange";
	this.open = false;
}



/**
 * ORMMALocationChangeEvent: fired whenever location based service data (GPS)
 * has been updated.
 */
function ORMMALocationChangeEvent()
{
	this.name = "locationChange";
	this.lattidue = -1;
	this.longitude = -1;
	this.altitude = -1;
	this.horizontalAccuracy = -1;
	this.verticalAccuracy = -1;
	this.timestamp = "";
	this.speed = -1;
	this.course = -1;
}



/**
 * ORMMANetworkChangeEvent: fired whenever the network status has changed.
 */
function ORMMANetworkChangeEvent()
{
	this.name = "networkChange";
	this.online = false;
	this.connection = "none";
}



/**
 * ORMMAOrientationChangeEvent: fired whenever the device orientation has
 * been changed.
 */
function ORMMAOrientationChangeEvent()
{
	this.name = "orientationChange";
	this.orientation = -1;
}



/**
 * ORMMAResponseEvent: fired whenever a request is completed.
 */
function ORMMAResponseEvent()
{
	this.name = "response";
	this.uri = null;
	this.response = null;
}



/**
 * ORMMARotationChangeEvent: fired whenever gyroscope data is available.
 */
function ORMMARotationChangeEvent()
{
	this.name = "rotationChange";
	this.x = -1;
	this.y = -1;
	this.z = -1;
}



/**
 * ORMMAScreenSizeChangeEvent: fired whenever the screen dimensions are changed.
 */
function ORMMAScreenSizeChangeEvent()
{
	this.name = "screenSizeChange";
	this.height = 480;
	this.width = 320;
}



/**
 * ORMMAShakeEvent: fired whenever a shake event is detected.
 */
function ORMMAShakeEvent()
{
	this.name = "shake";
	this.threshold = 0;
	this.time = 0;
}



/**
 * ORMMAReadyEvent: fired whenever the native SDK is ready in all respects.
 */
function ORMMAReadyEvent()
{
	this.name = "ready";
}



/**
 * ORMMASizeChangeEvent: fired whenever the ad size or position is changed.
 */
function ORMMASizeChangeEvent()
{
	this.name = "sizeChange";
	this.dimensions = new ORMMADimensions();
	this.properties = new ORMMAResizeProperties();
}



/**
 * ORMMAStateChangeEvent: fired whenever the display state changes.
 */
function ORMMAStateChangeEvent()
{
	this.name = "stateChange";
	this.state = "unknown";
}



/**
 * ORMMATiltChangeEvent: fired whenever accelerometer data is available.
 */
function ORMMATiltChangeEvent()
{
	this.name = "tiltChange";
	this.x = 0;
	this.y = 0;
	this.z = 0;
}



/****************************************************************************/
/************************** ORMMA STANDARD OBJECTS **************************/
/****************************************************************************/



/**
 * ORMMAExpandProperties: contains properties used during ad resize. 
 */
function ORMMAExpandProperties() 
{
	this.transition = "default";
	this.navigation = [ "close", "back", "forward", "refresh" ];
	this.useBackground = false;
	this.backgroundColor = "#FFFFFF";
	this.backgroundOpacity = 0.0;
	this.isModal = true;
}



/**
 * ORMMAHeading: contains heading (compass) information. 
 */
function ORMMAHeading()
{
	this.magneticHeading = -1;
	this.trueHeading = -1;
	this.accuracy = -1;
	this.timestamp = -1;
}



/**
 * ORMMALocation: contains a physical/geographic location. 
 */
function ORMMALocation()
{
	this.latitude = -1;
	this.longitude = -1;
	this.altitude = -1;
	this.horizontalAccuracy = -1;
	this.verticalAccuracy = -1;
	this.timestamp = "";
	this.speed = -1;
	this.course = -1;
}



/**
 * ORMMADimensions: contains the new origin and ad size for resize.
 */
function ORMMADimensions() 
{
	this.x = -1;
	this.y = -1;
	this.width = -1;
	this.height = -1;
	
	if ( arguments.length > 0 ) 
	{
		this.x = arguments[0];
	}
	if ( arguments.length > 1 ) 
	{
		this.y = arguments[1];
	}
	if ( arguments.length > 2 ) 
	{
		this.width = arguments[2];
	}
	if ( arguments.length > 3 ) 
	{
		this.height = arguments[3];
	}
}



/**
 * ORMMAResizeProperties: contains properties used during ad resize. 
 */
function ORMMAResizeProperties() 
{
	this.transition = "default";
}



/**
 * ORMMASize: contains the size in pixels of a view or screen.
 */
function ORMMASize() 
{
	this.height = 0;
	this.width = 0;
}



/**
 * ORMMAShakeProperties: contains properties identifying a shake.
 */
function ORMMAShakeProperties()
{
	this.intensity = 0;
	this.interval = 0;
}



/*******************************************************************/
/************************** ORMMA GLOBALS **************************/
/*******************************************************************/



/**
 * Creates a new global ORMMA  Object
 */
var ormma = new ORMMA();



