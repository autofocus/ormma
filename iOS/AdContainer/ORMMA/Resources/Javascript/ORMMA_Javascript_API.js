/*
 * The ORMMA Standard Javascript API
 *
 */

// Constructor
function ORMMA() 
{
	this.version = "0.1";
	this.nextWatchId = 1;
	this.eventListeners = { };
}


// --- PRIVATE METHODS ---

ORMMA.prototype.listenersForEvent = function( event )
{
	var listenersForEvent = this.eventListeners[event];
	if ( listenersForEvent == null )
	{
		listenersForEvent = {};
		this.eventListeners[event] = listenersForEvent;
	}
	var listeners = listenersForEvent[event]; 
	if ( listeners == null )
	{
		listeners = new Array();
		listenersForEvent[event] = listeners;
	}
	return listeners;
}


ORMMA.prototype.fireListenersForEvent = function( event )
{
	var listeners = this.listenersForEvent( event.name ); 
	var index;
	for ( index = ( listeners.length - 1); index >= 0; index-- )
	{
		listeners[index]( event );
	}
}


// --- PUBLIC METHODS ---
ORMMA.prototype.addAsset = function( alias, uri )
{
	ormmaNativeBridge.executeNativeAddAsset( "addasset", alias, uri );
	return false;
}


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


ORMMA.prototype.addEventListener = function( event, listener )
{
	var listeners = this.listenersForEvent( event ); 
	if ( listeners.indexOf( listener ) == -1 )
	{
		listeners.push( listener );
		if ( listeners.length == 1 )
		{
			// enable native events
			ormmaNativeBridge.enableNativeEvents( event, "yes" );
		}
	}
		
	return false;
}


ORMMA.prototype.cacheRemaining = function()
{
	return ormmaNativeBridge.cacheRemaining;
}


ORMMA.prototype.close = function()
{
	ormmaNativeBridge.executeNativeClose();
	return false;
}


ORMMA.prototype.getHeading = function(  )
{
	return ormmaNativeBridge.heading;
}


ORMMA.prototype.getLocation = function(  )
{
	return ormmaNativeBridge.location;
}


ORMMA.prototype.getNetwork = function(  )
{
	return ormmaNativeBridge.network;
}


ORMMA.prototype.getOrientation = function()
{
	return ormmaNativeBridge.orientation;
}


ORMMA.prototype.getResizeDimensions = function()
{
	return ormmaNativeBridge.resizeDimensions;
}


ORMMA.prototype.getResizeProperties = function()
{
	return ormmaNativeBridge.resizeProperties;
}


ORMMA.prototype.getScreenSize = function()
{
	return ormmaNativeBridge.screenSize;
}


ORMMA.prototype.getShakeProperties = function()
{
	return ormmaNativeBridge.shakeProperties;
}


ORMMA.prototype.getState = function()
{
	return ormmaNativeBridge.state;
}


ORMMA.prototype.hide = function()
{
	ormmaNativeBridge.executeNativeHide();
	return false;
}


ORMMA.prototype.removeAllAssets = function(  )
{
	// TODO
	return false;
}


ORMMA.prototype.removeAsset = function( alias )
{
	ormmaNativeBridge.executeNativeRemoveAsset( alias );
	return false;
}


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
		ormmaNativeBridge.enableNativeEvents( event, "no" );
	}
	
	return false;
}


ORMMA.prototype.request = function( display )
{
	ormmaNativeBridge.executeNativeRequest( display );
	return false;
}


ORMMA.prototype.resize = function( dimensions )
{
	// see if the properties are being changed
	if ( arguments.length > 1 )
	{
		// they are, update the properties
		ormmaNativeBridge.resizeProperties = arguments[1];
	}
	
	// cal the resize function
	ormmaNativeBridge.executeNativeResize( dimensions );
	return false;
}


ORMMA.prototype.setResizeProperties = function( properties )
{
	ormmaNativeBridge.resizeProperties = properties;
	return false;
}


ORMMA.prototype.setShakeProperties = function( properties )
{
	ormmaNativeBridge.shakeProperties = properties;
	return false;
}


ORMMA.prototype.show = function()
{
	ormmaNativeBridge.executeNativeShow();
	return false;
}


ORMMA.prototype.state = function()
{
	return ormmaNativeBridge.state;
}


ORMMA.prototype.supports = function()
{
	return ormmaNativeBridge.supportedFeatures;
}


/*
 * ORMMA Events
 */

function ORMMAAlignmentChangeEvent()
{
	this.name = "alignmentChange";
	this.degrees = 0;
}

function ORMMAAssetReadyEvent()
{
	this.name = "assetReady";
	this.alias = "";
}

function ORMMAAssetRemovedEvent()
{
	this.name = "assetRemoved";
	this.alias = "";
}

function ORMMAAssetRetiredEvent()
{
	this.name = "assetRetired";
	this.alias = "";
}

function ORMMAErrorEvent()
{
	this.name = "error";
	this.message = "";
	this.action = null;
}

function ORMMAHeadingChangeEvent()
{
	this.name = "headingChange";
	this.magneticHeading = -1;
	this.trueHeading = -1;
	this.accuracy = -1;
	this.timestamp = 0;
}

function ORMMAKeyboardChangeEvent()
{
	this.name = "keyboardChange";
	this.open = false;
}

function ORMMALocationChangeEvent()
{
	this.name = "locationChange";
	this.lat = 0;
	this.lng = 0;
}

function ORMMANetowrkChangeEvent()
{
	this.name = "networkChange";
	this.online = false;
	this.connection = "none";
}

function ORMMAOrientationChangeEvent()
{
	this.name = "orientationChange";
	this.orientation = -1;
}

function ORMMAProximityChangeEvent()
{
	this.name = "proximityChange";
	this.proximity = false;
}

function ORMMAReadyEvent()
{
	this.name = "ready";
}

function ORMMAResponseEvent()
{
	this.name = "response";
	this.uri = null;
	this.response = null;
}

function ORMMARotationChangeEvent()
{
	this.name = "rotationChange";
	this.x = 0;
	this.y = 0;
	this.z = 0;
}

function ORMMAScreenSizeChangeEvent()
{
	this.name = "screenSizeChange";
	this.height = 480;
	this.width = 320;
}

function ORMMAShakeEvent()
{
	this.name = "shake";
	this.threshold = 0;
	this.time = 0;
}

function ORMMAReadyEvent()
{
	this.name = "ready";
}

function ORMMASizeChangeEvent()
{
	this.name = "sizeChange";
	this.dimensions = new ORMMAResizeDimensions();
	this.properties = new ORMMAResizeProperties();
}

function ORMMAStateChangeEvent()
{
	this.name = "stateChange";
	this.state = "unknown";
}

function ORMMATiltChangeEvent()
{
	this.name = "tiltChange";
	this.x = 0;
	this.y = 0;
	this.z = 0;
}



/*
 * The ORMMA Standard Object Types
 *
 */

// Heading
function ORMMAHeading()
{
	this.magneticHeading = -1;
	this.trueHeading = -1;
	this.accuracy = -1;
	this.timestamp = -1;
}


// Location
function ORMMALocation()
{
	this.latitude = 0;
	this.longitude = 0;
}


// Resize Dimensions
function ORMMAResizeDimensions() 
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

// Resize Dimensions
function ORMMAResizeProperties() 
{
	this.transition = "default";
	this.navigation = [ "close", "back", "forward", "refresh" ];
	this.useBackground = false;
	this.backgroundColor = "#FFFFFF";
	this.backgroundOpacity = 0.0;
	this.isModal = true;
}

// Resize Dimensions
function ORMMAScreenSize() 
{
	this.height = 0;
	this.width = 0;
}


// Shake Properties
function ORMMAShakeProperties()
{
	this.intensity = 0;
	this.interval = 0;
}


// now create the standard API object
var ormma = new ORMMA();



