/*
 * Abstraction Layer between the ORMMA Javascript Library and the Native Code
 * Used to allow easy shifting between mobile platforms while still presenting
 * a common interface to creative developers.
 */

function ORMMA_iOS_Abstraction_Layer() 
{
	this.version = "0.1";
	this.nextWatchId = 1;
	this.location = new ORMMALocation();
	this.heading = new ORMMAHeading();
	this.network = "unknown"; // unknown, offline, cell, wifi
	this.orientation = -1;    // -1 = Unknown, 0 = Portrait, 90 = Landscape Right, 180 = Portrait Upside Down, 270 = Landscape Left
	this.resizeDimensions = new ORMMAResizeDimensions();
	this.resizeProperties = new ORMMAResizeProperties();
	this.pendingResizeDimensions = new ORMMAResizeDimensions();
	this.screenSize = new ORMMAScreenSize();
	this.baseScreenSize = new ORMMAScreenSize();
	this.proximity = false;
	this.visible = false;
	this.state = "default";
	this.supportedFeatures = new Array();
	this.cacheRemaining = -1;
	this.shakeProperties = new ORMMAShakeProperties();
	
	this.nativeCallQueue = new Array();
	this.nativeCallPending = false;
}


// Turn on/off various services
ORMMA_iOS_Abstraction_Layer.prototype.enableNativeEvents = function( name, enabled )
{
	this.executeNativeCode( "service", "name", name, "enabled", ( enabled ? "yes" : "no" ) );
}


// add device features
ORMMA_iOS_Abstraction_Layer.prototype.addFeature = function( feature )
{
	if ( this.supportedFeatures.indexOf( feature ) == -1 )
	{
		this.supportedFeatures.push( feature );
	}
	return "OK";
}


ORMMA_iOS_Abstraction_Layer.prototype.applicationReady = function()
{
	// send an event to everyone that cares
	var event = new ORMMAReadyEvent();
	ormma.fireListenersForEvent( event );
	return "OK";
}


ORMMA_iOS_Abstraction_Layer.prototype.networkChanged = function( state )
{
	// save the new state
	this.network = state;
	
	// send an event to everyone that cares
	var event = new ORMMANetworkChangeEvent();
	event.network = state;
	ormma.fireListenersForEvent( event );
	
	// all done
	return "OK";
}


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


ORMMA_iOS_Abstraction_Layer.prototype.proximityChanged = function( state )
{
	// save the new state
	this.proximity = state;
	
	// send an event to everyone that cares
	var event = new ORMMAProxmityChangeEvent();
	event.proximity = state;
	ormma.fireListenersForEvent( event );
	
	// all done
	return "OK";
}


ORMMA_iOS_Abstraction_Layer.prototype.stateChanged = function( state )
{
	// save the new state
	this.state = state;
	
	// send an event to everyone that cares
	var event = new ORMMAStateChangeEvent();
	event.state = state;
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


// Executes a call into native code
// Parameters
//    command  - the command to execute
//    [arg...] - zero or more arguments to the command
ORMMA_iOS_Abstraction_Layer.prototype.executeNativeCode = function( command )
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


ORMMA_iOS_Abstraction_Layer.prototype.executeNativeAddAsset = function( alias, uri )
{
	this.executeNativeCode( "addasset", alias, uri );
}


ORMMA_iOS_Abstraction_Layer.prototype.executeNativeClose = function()
{
	this.executeNativeCode( "close" );
}


ORMMA_iOS_Abstraction_Layer.prototype.executeNativeHide = function()
{
	this.executeNativeCode( "hide" );
}


ORMMA_iOS_Abstraction_Layer.prototype.executeNativeRemoveAsset = function( alias )
{
	this.executeNativeCode( "removeasset", alias );
}


ORMMA_iOS_Abstraction_Layer.prototype.executeNativeRequest = function( display )
{
	this.executeNativeCode( "request", display );
}


// execute a resize event
ORMMA_iOS_Abstraction_Layer.prototype.executeNativeResize = function( dimensions )
{
	this.pendingResizeDimensions = dimensions;
	this.executeNativeCode( "resize", 
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


ORMMA_iOS_Abstraction_Layer.prototype.executeNativeShow = function()
{
	this.executeNativeCode( "show" );
}

// now create the standard abstraction layer object
var ormmaNativeBridge = new ORMMA_iOS_Abstraction_Layer();
