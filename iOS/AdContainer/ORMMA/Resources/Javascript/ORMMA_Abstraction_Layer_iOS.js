/**
 * ORMMA_iOS_Abstraction_Layer is the constructor for the Abstraction Layer
 * for iOS. Acts as the interface between the public facing javascript API and
 * the native code SDK.
 *
 * NOTE: An instance of this object will be created automatically and should
 *       not be instantiated directly.
 *
 * @returns a new object
 */
function ORMMA_iOS_Abstraction_Layer() 
{
	this.version = "0.1";
	this.location = new ORMMALocation();
	this.heading = new ORMMAHeading();
	this.network = "unknown"; // unknown, offline, cell, wifi
	this.orientation = -1;    // -1 = Unknown, 0 = Portrait, 90 = Landscape Right, 180 = Portrait Upside Down, 270 = Landscape Left
	this.resizeDimensions = new ORMMAResizeDimensions();
	this.resizeProperties = new ORMMAResizeProperties();
	this.pendingResizeDimensions = new ORMMAResizeDimensions();
	this.screenSize = new ORMMAScreenSize();
	this.baseScreenSize = new ORMMAScreenSize();
	this.visible = false;
	this.state = "default";
	this.supportedFeatures = new Array();
	this.cacheRemaining = -1;
	this.shakeProperties = new ORMMAShakeProperties();
	
	this.nativeCallQueue = new Array();
	this.nativeCallPending = false;
}



/**************************************************************************/
/***************** PRIVATE METHODS, FOR INTERNAL USE ONLY *****************/
/**************************************************************************/



/**
 * acceleration notifies the javascript API of updated accelerometer data.
 *
 * NOTE: This function is called by the native code and is not intended to be
 *       used by anything else.
 *
 * @param {x} Number, the value for the X axis.
 * @param {y} Number, the value for the Y axis.
 * @param {z} Number, the value for the Z axis.
 *
 * @returns string, "OK"
 */
ORMMA_iOS_Abstraction_Layer.prototype.acceleration = function( x, y, z )
{
	// send an event to everyone that cares
	var event = new ORMMATiltChangeEvent();
	event.x = x;
	event.y = y;
	event.z = z;
	ormma.fireListenersForEvent( event );
	
	// all done
	return "OK";
}



/**
 * addFeature adds an available feature to the list of available features
 * for this device.
 *
 * NOTE: This function is called by the native code and is not intended to be
 *       used by anything else.
 *
 * @param {feature} String, the name of the feature.
 *
 * @returns string, "OK"
 */
ORMMA_iOS_Abstraction_Layer.prototype.addFeature = function( feature )
{
	if ( this.supportedFeatures.indexOf( feature ) == -1 )
	{
		this.supportedFeatures.push( feature );
	}
	return "OK";
}



/**
 * applicationReady notifies the javascript API that the native code SDK has
 * completed startup and is ready in all respects.
 *
 * NOTE: This function is called by the native code and is not intended to be
 *       used by anything else.
 *
 * @returns string, "OK"
 */
ORMMA_iOS_Abstraction_Layer.prototype.applicationReady = function()
{
	// send an event to everyone that cares
	var event = new ORMMAReadyEvent();
	ormma.fireListenersForEvent( event );
	return "OK";
}



/**
 * executeNativeCall executes or queues a call into native code.
 *
 * NOTE: Since our communications mechanism with iOS is via a navigation event,
 *       we need to ensure that we don't overwrite events. We therefore queue
 *       up all native code requests and execute them sequentially one after
 *       the next.
 *
 * NOTE: This function is called by the native code and is not intended to be
 *       used by anything else.
 *
 * @param {command}  String, the command to execute.
 * @param {args1..n} String, Optional, additional arguments. Must be
 *                   in pairs (i.e. matching name-value pairs).
 *
 * @returns string, "OK"
 */
ORMMA_iOS_Abstraction_Layer.prototype.executeNativeCall = function( command )
{
	var bridgeCall = "ormma://" + command;
	for ( var i = 1; i < arguments.length; i += 2 )
	{
		if ( i == 1 )
		{
			bridgeCall += "?";
		}
		else
		{
			bridgeCall += "&";
		}
		bridgeCall += arguments[i] + "=" + escape( arguments[i + 1] );
	}
	
	// add call to queue
	if ( this.nativeCallPending )
	{
		// call pending, queue up request
		this.nativeCallQueue.push( bridgeCall );
	}
	else
	{
		// no call currently in process, execute it directly
		this.nativeCallPending = true;
		window.location = bridgeCall;
	}
}



/**
 * headingChanged notifies the javascript API that the heading has changed.
 *
 * NOTE: This function is called by the native code and is not intended to be
 *       used by anything else.
 *
 * @param {magneticHeading} magneticHeading Number, the magnetic heading in
 *                          degrees.
 * @param {trueHeading} Number, the true heading, in degrees.
 * @param {accuracy}    Number, how acccurate the heading may be.
 * @param {timestamp}   Date-Time, when the heading was taken.
 *
 * @returns string, "OK"
 */
ORMMA_iOS_Abstraction_Layer.prototype.headingChanged = function( magneticHeading, trueHeading, accuracy, timestamp )
{
	this.heading.magneticHeading = magneticHeading;
	this.heading.trueHeading = trueHeading;
	this.heading.accuracy = accuracy;
	this.heading.timestamp = timestamp;
	
	// send an event to everyone that cares
	var event = new ORMMAHeadingChangeEvent();
	event.magneticHeading = magneticHeading;
	event.trueHeading = trueHeading;
	event.accuracy = accuracy;
	event.timestamp = timestamp;
	ormma.fireListenersForEvent( event );
	
	// all done
	return "OK";
}



/**
 * locationChanged notifies the javascript API that the physical geographic
 * location has changed.
 *
 * NOTE: This function is called by the native code and is not intended to be
 *       used by anything else.
 *
 * @param {lattitude}           Number, the magnetic heading in degrees
 * @param {longitude}           Number, the true heading, in degrees.
 * @param {altitude}            Number, the altitude, in meters.
 * @param {horizontalAccuracy}  Number, radius of uncertainty, in meters.
 * @param {verticalAccuracy}    Number, the accuracy of the altitude in meters.
 * @param {timestamp}           Date-Time, when the heading was taken.
 * @param {speed}               Number, how fast the device is moving in feet 
 *                              per second.
 * @param {course}              Number, the direction the device is moving,
 *                              in degrees.
 *
 * @returns string, "OK"
 */
ORMMA_iOS_Abstraction_Layer.prototype.locationChanged = function( lattitude, 
																  longitude, 
																  altitude, 
																  horizontalAccuracy, 
																  verticalAccuracy, 
																  timestamp, 
																  speed,
																  course )
{
	this.location.lattitude = lattitude;
	this.location.longitude = longitude;
	this.location.altitude = altitude;
	this.location.horizontalAccuracy = horizontalAccuracy;
	this.location.verticalAccuracy = verticalAccuracy;
	this.location.timestamp = timestamp;
	this.location.speed = speed;
	this.location.course = course;
	
	// send an event to everyone that cares
	var event = new ORMMALocationChangeEvent();
	event.lattitude = lattitude;
	event.longitude = longitude;
	event.altitude = altitude;
	event.horizontalAccuracy = horizontalAccuracy;
	event.verticalAccuracy = verticalAccuracy;
	event.timestamp = timestamp;
	event.speed = speed;
	event.course = course;
	ormma.fireListenersForEvent( event );
	
	// all done
	return "OK";
}



/**
 * nativeCallComplete notifies the abstraction layer that a native call has
 * been completed..
 *
 * NOTE: This function is called by the native code and is not intended to be
 *       used by anything else.
 *
 * @returns string, "OK"
 */
ORMMA_iOS_Abstraction_Layer.prototype.nativeCallComplete = function()
{
	// anything left to do?
	if ( this.nativeCallQueue.length == 0 )
	{
		this.nativeCallPending = false;
		return;
	}
	
	// still have something to do
	var bridgeCall = this.nativeCallQueue.pop();
	window.location = bridgeCall;
}



/**
 * networkChanged notifies the javascript API that the network state has changed.
 *
 * NOTE: This function is called by the native code and is not intended to be
 *       used by anything else.
 *
 * @param {newState} String, the new network state. Must be one of-
 *                   "unknown" - network state is unknown
 *                   "offline" - device is offline
 *                   "cell"    - device is on the WWAN/Cellular network
 *                   "wifi"    - device is on WiFi
 *
 * @returns string, "OK"
 */
ORMMA_iOS_Abstraction_Layer.prototype.networkChanged = function( newState )
{
	// save the new state
	this.network = newState;
	
	// send an event to everyone that cares
	var event = new ORMMANetworkChangeEvent();
	event.network = newState;
	ormma.fireListenersForEvent( event );
	
	// all done
	return "OK";
}



/**
 * orientationChanged notifies the javascript API that the device orientation
 * has changed.
 *
 * NOTE: This function is called by the native code and is not intended to be
 *       used by anything else.
 *
 * @param {orientation} Number, the orientation of the device, 
 *                      specified in degrees.
 *                        0 = Portrait
 *                       90 = Landscape, Right
 *                      180 = Portrait, Upside Down
 *                      270 = Landscape, Left
 *
 * @returns string, "OK"
 */
ORMMA_iOS_Abstraction_Layer.prototype.orientationChanged = function( orientation )
{
	// save the new state
	this.orientation = orientation;
	
	// send an event to everyone that cares
	var event = new ORMMAOrientationChangeEvent();
	event.orientation = orientation;
	ormma.fireListenersForEvent( event );
	
	// update our screen size
	if ( ( orientation == 90 ) ||
		 ( orientation == 270 ) )
	{
		// landscape
		this.screenSize.height = this.baseScreenSize.width;
		this.screenSize.width = this.baseScreenSize.height;
	}
	else
	{
		// assume portrait
		this.screenSize.width = this.baseScreenSize.width;
		this.screenSize.height = this.baseScreenSize.height;
	}
	
	// send an screen size change event to everyone that cares
	var event = new ORMMAScreenSizeChangeEvent();
	event.height = this.screenSize.height;
	event.width = this.screenSize.width;
	ormma.fireListenersForEvent( event );
	
	// all done
	return "OK";
}



/**
 * rotation notifies the javascript API of updated gyroscope data.
 *
 * NOTE: This function is called by the native code and is not intended to be
 *       used by anything else.
 *
 * @param {x} Number, the value for the X axis.
 * @param {y} Number, the value for the Y axis.
 * @param {z} Number, the value for the Z axis.
 *
 * @returns string, "OK"
 */
ORMMA_iOS_Abstraction_Layer.prototype.rotation = function( x, y, z )
{
	// send an event to everyone that cares
	var event = new ORMMARotationChangeEvent();
	event.x = x;
	event.y = y;
	event.z = z;
	ormma.fireListenersForEvent( event );
	
	// all done
	return "OK";
}



/**
 * setBaseScreenSize allows the native code to specify the base screen size.
 *
 * NOTE: This function is called by the native code and is not intended to be
 *       used by anything else.
 *
 * @param {width}  Number, the width in points of the display. 
 * @param {height} Number, the height in points of the display. 
 *
 * @returns string, "OK"
 */
ORMMA_iOS_Abstraction_Layer.prototype.setBaseScreenSize = function( width, height )
{
	// update our base dimensions
	this.baseScreenSize.width = width;
	this.baseScreenSize.height = height;

	// make sure we have some dimensions for general use until we get the orientation
	this.screenSize.width = width;
	this.screenSize.height = height;

	// all done
	return "OK";
}



/**
 * stateChanged notifies the javascript API that the display state of the ad has 
 * changed.
 *
 * NOTE: This function is called by the native code and is not intended to be
 *       used by anything else.
 *
 * @param {newState} String, the display state of the ad. 
 *                   "hidden"   - the ad has been hidden
 *                   "default"  - the ad is in the default state
 *                   "expanded" - the ad is in the expanded state.
 *
 * @returns string, "OK"
 */
ORMMA_iOS_Abstraction_Layer.prototype.stateChanged = function( newState )
{
	// save the new state
	this.state = newState;
	
	// send an event to everyone that cares
	var event = new ORMMAStateChangeEvent();
	event.state = newState;
	ormma.fireListenersForEvent( event );
	
	// update our dimensions
	this.resizeDimensions = this.pendingResizeDimensions;
	
	// our size has also changed, send an event for that too
	event = new ORMMASizeChangeEvent();
	event.resizeDimensions = this.resizeDimensions;
	event.resizeProperties = this.resizeProperties;
	ormma.fireListenersForEvent( event );
	
	// all done
	return "OK";
}



/***************************************************************/
/******************** API INTERFACE METHODS ********************/
/***************************************************************/



/**
 * enableNativeEventsForService requests that the native SDK enable or disable
 * a specified service.
 *
 * @param {name}    String, The name of the service.
 * @param {enabled} Boolean, flag indicating if the service should be 
 *                  enabled or disabled.
 *
 * @returns nothing.
 */
ORMMA_iOS_Abstraction_Layer.prototype.enableNativeEventsForService = function( name, enabled )
{
	this.executeNativeCall( "service", "name", name, "enabled", ( enabled ? "yes" : "no" ) );
}



/**
 * executeNativeAddAsset requests that the native SDK add a new asset to the
 * cache from the specified location.
 *
 * @param {alias} String, alias to use for the resource.
 * @param {uri}   String, the source location of the resource.
 *
 * @returns nothing.
 */
ORMMA_iOS_Abstraction_Layer.prototype.executeNativeAddAsset = function( alias, uri )
{
	this.executeNativeCall( "addasset", "alias", alias, "uri", uri );
}



/**
 * executeNativeClose requests that the native SDK close an expanded or full 
 * screen ad.
 *
 * @returns nothing.
 */
ORMMA_iOS_Abstraction_Layer.prototype.executeNativeClose = function()
{
	this.executeNativeCall( "close" );
}



/**
 * executeNativeHide notifies the native SDK that the ad may be hidden.
 *
 * @returns nothing.
 */
ORMMA_iOS_Abstraction_Layer.prototype.executeNativeHide = function()
{
	this.executeNativeCall( "hide" );
}



/**
 * executeNativeRemoveAsset requests that the native SDK remove the resource
 * specified by the alias from the cache.
 *
 * @param {alias} String, alias of the resource.
 *
 * @returns nothing.
 */
ORMMA_iOS_Abstraction_Layer.prototype.executeNativeRemoveAsset = function( alias )
{
	this.executeNativeCall( "removeasset", "alias", alias );
}



/**
 * executeNativeRequest requests that the native SDK execute the specified
 * HTTP request.
 *
 * @param {uri}     String, the source URI for the request.
 * @param {display} String, the display style to use.
 *
 * @returns nothing.
 */
ORMMA_iOS_Abstraction_Layer.prototype.executeNativeRequest = function( uri, display )
{
	this.executeNativeCall( "request", "uri", uri, "display", display );
}



/**
 * executeNativeResize requests that the native SDK resize the current ad to
 * the specified dimensions.
 *
 * @param {dimensions} ORMMADimensions, the dimensions to use for the
 *                     resize action.
 *
 * @returns nothing.
 */
ORMMA_iOS_Abstraction_Layer.prototype.executeNativeResize = function( dimensions )
{
	this.pendingResizeDimensions = dimensions;
	this.executeNativeCall( "resize", 
						    "x", dimensions.x, 
						    "y", dimensions.y,
						    "w", dimensions.width,
						    "h", dimensions.height,
						    "transition", this.resizeProperties.transition,
						    "navigation", this.resizeProperties.navigation,
						    "useBG",      this.resizeProperties.useBackground,
						    "bgColor",    this.resizeProperties.backgroundColor,
						    "bgOpacity",  this.resizeProperties.backgroundOpacity,
						    "modal",      this.resizeProperties.isModal );
}



/**
 * executeNativeShow notifies the native SDK that the ad is ready for display.
 *
 * @returns nothing.
 */
ORMMA_iOS_Abstraction_Layer.prototype.executeNativeShow = function()
{
	this.executeNativeCall( "show" );
}



/*******************************************************************/
/************************** ORMMA GLOBALS **************************/
/*******************************************************************/



/**
 * Creates a new global ORMMA Native Bridge Abstraction Layer Object
 */
var ormmaNativeBridge = new ORMMA_iOS_Abstraction_Layer();
