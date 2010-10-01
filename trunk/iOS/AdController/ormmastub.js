/*global window */

/**
 * @fileOverview This is a stub for ad designers who want to work with OrmmaAdController methods
 *  In this version, only ORMMA Level 1 functions are provided
 *
 * @author <a href="mailto:nathan.carver@crispwireless.com">Nathan Carver</a>
 * @version 0.0.1
 */
 

/**
* Anonymous invocation of the ad controller class
* 
* @throws ormma ready event
*/
(function () {

/* 
* Private helper functions to provide mock data
*/
	
	/**
	* This class takes on the responsibility of providing data just as a fully implemented
	* registration object would
	* @class
	* @private
	*/
	function MockRegistration() {
		this.hasListener = [];
		this.timer = [];
		this.mockValue = [];
		this.events = ['heading', 'location', 'network', 'orientation', 'screensize', 'rotation', 'shake', 'tilt', 'shakeproperties'];
		for (var i = 0; i < this.events.length; i = i + 1) {
			this.hasListener[this.events[i]] = false;
			this.mockValue[this.events[i]] = 0;
			this.timer[this.events[i]] = null;
		}
	}
	
	/* instatiation of MockRegistration object, loaded event */
	var registration = new MockRegistration(),
		evt = document.createEvent('MessageEvent');


	/**
	* Generic private function to throw events to listeners, in this implementation, all events are MessageEvents
	* @private
	* @param {String} msg The type of event being thrown
	* @param {String} data The response data for the event
	* @see startPolling
	*/
	function throwEvent(msg, data) {
		var evt = document.createEvent('MessageEvent');
		evt.initMessageEvent(msg, true, true, data, null, 0, null, null);
		window.dispatchEvent(evt);
	}

	/**
	* Generic private helper function to register a listener and throw events for a polled feature. Interval is 500ms
	* @private
	* @param {String} evt the type of event that is being polled
	* @param {Function} listener the function to be registered as a listener
	* @see addEventListener
	*/
	function startPolling(evt, listener) {
		if (!registration.hasListener[evt]) {
			registration.hasListener[evt] = true;
			window.addEventListener(evt, listener, false);
			registration.timer[evt] = setInterval(function () {
				throwEvent(evt, registration.mockValue[evt]++);
			}, 500);
		}
	}
	
	/**
	* Generic private helper function to remove a listener for a polled feature. 
	* @private
	* @param {String} evt the type of event that is being stopped
	* @param {Function} listener the function to be removed as a listener
	* @see removeEventListener
	*/
	function stopPolling(evt, listener) {
		registration.hasListener[evt] = false; 
		clearInterval(registration.timer[evt]);
	}

/*
* Public API
*/

	/**
     * The main ad controller object
     * @namespace encapusaltes all methods of the ORMMA JavaScript API
     */
    window.Ormma = {

        /**
        * Use this method to subscribe a specific handler method to a specific event. In this way, multiple 
        * listeners can subscribe to a specific event, and a single listener can handle multiple events. The events are:
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
        * <br/>#side effects: registering listeners for device features may power up sensors in the device that will reduce battery life. 
        * <br/>#ORMMA Level: 1 
        *
        * @param {String} event name of event to listen for
        * @param {Function} listener function name (or anonymous function) to execute 
        */
        addEventListener : function (evt, listener) {
			switch (evt) {
			case "network" : 
			case "orientation" : 
			case "screensize" : 
			case "heading" : 
			case "location" : 
			case "rotation" : 
			case "shake" : 
			case "tilt" : 
				startPolling(evt, listener); 
				break;
			default : 
				window.addEventListener(evt, listener, false);
			}
        },

        /**
        * Use this method to unsubscribe a specific handler method from a specific event. Event listeners should 
        * always be removed when they are no longer useful to avoid errors. If no listener function is provided, 
        * then all functions listening to the event will be removed.
        * 
        * <br/>#side effects: none
        * <br/>#ORMMA Level: 1
        * 
        * @param {String} event name of event
        * @param {Function} listener (optional) function to be removed 
        */    
        removeEventListener : function (evt, listener) {
			window.removeEventListener(evt, listener, false);
			switch (evt) {
			case "network" : 
			case "orientation" : 
			case "screensize" : 
			case "heading" : 
			case "location" : 
			case "rotation" : 
			case "shake" : 
			case "tilt" : 
				stopPolling(evt); 
				break;
			default : //do nothing
			}
		},

        /**
        * This method returns whether the ad is in its default, fixed position or is in an expanded, larger position.
        * 
        * <br/>#side effects: none
        * <br/>#ORMMA Level: 1
        *
        * @returns {String} "default", "expanded", or "hidden" 
        */
        getState : function () {
            return ('default');
        },
        
        /**
        * This method has no return value and is executed asynchronously (so always listen for a result event 
        * before taking action instead of assuming the change has occurred).
        *
        * <br/>#side effects: changes the state value
        * <br/>#ORMMA Level: 1
        *
        * @throws stateChange 
        */
        show : function () {
            var evt = document.createEvent('MessageEvent');
            evt.initMessageEvent('stateChange', true, true, 'default', null, 0, null, null);
            window.dispatchEvent(evt);
        },

        /**
        * Use this method to get the current resize properties of the web viewer. Since the resize action 
        * is asynchronous, this value does not update until the action has completed execution (when the 
        * "resizeChange" event fires).
        *
        * <p>properties object<br/>
		* <code>
        *   properties = {
        *     "transition" : "default|dissolve|zoom|none",
        *   }
        * </code></p>
		*
        * "transition" - If "transition" is not specified in the properties object, a value of "default" is assumed.
        *
        * <br/>#side effects: none
        * <br/>#ORMMA Level: 1
        *
        * @returns {JSON} properties object
        */
        getResizeProperties : function () {
            return ({'transition' : 'default'});
        },
        
        /**
        * Use this method to set the ads resize properties.
        *
        * <br/>#side effects: none
        * <br/>#ORMMA Level: 1
        * 
        * @param {JSON} properties this object contains any number of properties, such as transition, 
                that might be used by the SDK when resizing the web viewer, for more info @see properties object 
        */
        setResizeProperties : function (properties) {
        },
        
        /**
        * Use this method to return the maximum size an ad can grow to using the resize() method. 
        * This may be set by the developer, or be the size of the parent view.
        * 
        * <br/>#side effects: none
        * ORMAA Level: 1
        * 
        * @returns {JSON} {height, width} - the maximum height and width the view can grow to 
        */
        getMaxSize : function () {
            return ({'height' : '250', 'width' : '320'});
        },
        
        /**
        * Use this method to resize the main ad view to the desired size. The views place in the view hierarchy
        * will not change, so the effect on other views is up to the app developer.
        * 
        * <br/>#side effects: changes state
        * <br/>#ORMMA Level: 1
        * 
        * @param {Integer} height the height in pixels
        * @param {Integer} width the width in pixels 
        * @throws resizeChange
        * @throws stateChange
        */
        resize : function (height, width) {
            var evt = document.createEvent('MessageEvent');
            evt.initMessageEvent('stateChange', true, true, 'default', null, 0, null, null);
            window.dispatchEvent(evt);
            
            evt = document.createEvent('Event');
            evt.initEvent('resizeChange', true, true);
            window.dispatchEvent(evt);
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
        * If "transition" is not specified in the properties object, a value of "default" is assumed.
        * 
        * "navigation"
        * If "navigation" is not specified in the properties object, a value of "none" is assumed.
        * 
        * "useBackground"
        * "useBackground" should contain a boolean value (true/false) indicating the presence of a 
        *   background. If "useBackground" is not specified in the properties object, a value of false is assumed.
        * 
        * "backgroundColor"
        * "backgroundColor" is a standard numeric RGB value (most logically expressed in hexadecimal with 
        *   two digits each for red, green, and blue).
        * 
        * "backgroundOpacity"
        * "backgroundOpacity" is a number between 0 and 1 inclusively (ranging from 0 equaling fully transparent 
        *   to 1 equaling fully opaque). If either "backgroundColor" or "backgroundOpacity" is not specified in the 
        *   properties object, values of 0xffffff and 1.0 respectively are assumed.
        * 
        * "isModal"
        * The "isModal" property is a boolean value (true/false) and if it is not specified in the properties 
        *   object a value of false is assumed.
		* </pre>
		* 
        * <br/>#side effects: none
        * <br/>#ORMMA Level: 1
        *
        * @returns {JSON} this object contains all the web viewer properties besides dimension that 
        *    are supported by the SDK vendor. @see properties object 
        */
        getExpandProperties : function () {
            return ({'transition' : 'default', 'navigation' : 'none', 'use-background' : 'true', 'background-color' : '#000000', 'background-opacity' : '0.5', 'is-modal' : 'true'});
        },
        
        /**
        * Use this method to set the ad's expand properties.
        *
        * <br/>#side effects: none -- need to call expand
        * <br/>#ORMMA Level: 1
        * 
        * @param {JSON} properties object representing all properties to set before expanding
        * @see getExpandProperties
		* @see expand
        */
        setExpandProperties : function (properties) {
        },
        
        /**
        * Use this method to open a separate overlay ad container view at the highest z-order of the window's view.
        *
        * dimensions: Object {top, left, bottom, right} - this object contains desired point value dimensions of the 
        *   resized web viewer
        *
        * <br/>#side effects: changes state
        * <br/>#ORMMA Level: 1
        * 
        * @param {JSON} initialDimensions an object describing the initial position of the overlay view 
        *   before the expand transition occurs
        * @param {JSON} finalDimensions the final position of the overlay view after the expand transition occurs
        * @param {String} url (optiional) The URL for the document to be displayed in the overlay view. 
        *   If null, the body of the current ad will be used. 
        * @throws stateChange
        * @throws resizeChange 
        */
        expand : function (initialDimensions, finalDimensions, URL) {
            var evt = document.createEvent('MessageEvent');
            evt.initMessageEvent('stateChange', true, true, 'expanded', null, 0, null, null);
            window.dispatchEvent(evt);

            evt = document.createEvent('Event');
            evt.initEvent('resizeChange', true, true);
            window.dispatchEvent(evt);
        },
        
        /**
        * For SDKs that do not expose any of the native device features, this method should always return false. 
        *
        * The features are:
		* <table>
        *   <tr><td>network    </td><td>the device can report on its network connectivity and connectivity changes</td></tr>
        *   <tr><td>orientation</td><td>the device can report on its orientation and orientation changes</td></tr>
        *   <tr><td>size       </td><td>the device can report on the screen size</td></tr>
        *   <tr><td>heading    </td><td>the device can report on the compass direction it is pointing</td></tr>
        *   <tr><td>location   </td><td>the device can report on its location</td></tr>
        *   <tr><td>rotation   </td><td>the device can report on its rotation and rotation changes</td></tr>
        *   <tr><td>shake      </td><td>the device can report on being shaken</td></tr>
        *   <tr><td>tilt       </td><td>the device can report on its tilt and tilt changes</td></tr>
        *   <tr><td>phone      </td><td>the device can make a phone call</td></tr>
        *   <tr><td>email      </td><td>the device can compose an email</td></tr>
        *   <tr><td>calendar   </td><td>the device can create a calendar entry</td></tr>
		* </table>
        *
        * <br/>#side effects: none
        * <br/>#ORMMA Level: 1
        * 
        * @param {String} feature name of feature 
        * @returns {Boolean } true, the feature is supported and getter and events are available; false, the feature is not supported 
        */
        supports : function (feature) {
			var response = false;
			switch (feature) {
			case 'network':
			case 'orientation':
			case 'screensize':
			case 'heading':
			case 'location':
			case 'shake':
			case 'tilt': 
				response = true;
			}
            return (response);
        },
        
        /**
        * The method executes asynchronously, but returns a Boolean value of false to facilitate use in anchor 
        *  tags. There is also an option explicitly for metrics tracking that will cache requests offline and 
        *  execute them whenever the device reconnects. 
        *
        * <br/>#side effects: network traffic and new views depending on display values
        * <br/>#ORMMA Level: 1
        * 
        * @param {String} uri the fully qualified URL of the page or call to action asset
        * @param {String} display the display style for the call to action 
        * @returns {Boolean} false, so click events can stop propogatiing
        * @throws response
        */
        request : function (uri, display) {
            if ('proxy' === display) {
                var evt = document.createEvent('MessageEvent');
                evt.initMessageEvent('response', true, true, uri + ',<div style="background-color:yellow;color:red;">AJAX</div>', null, 0, null, null);
                window.dispatchEvent(evt);
            } else {
				if (window.confirm("navigate to '" + uri + "'?")) {
					document.location.href = uri;
				}
			}
            return (false);
        },
        
        /**
        * Use this method to return a resized ad to the default position or an expanded ad to its pre-expanded 
        *  position within the UI. The SDK is responsible for the correct size of the ad within the app UI.
        *
        * <br/>#side effects: changes state
        * <br/>#ORMMA Level: 1
        * 
        * @throws stateChange 
		* @throws resizeChange
        */
        close : function () {
            var evt = document.createEvent('MessageEvent');
            evt.initMessageEvent('stateChange', true, true, 'default', null, 0, null, null);
            window.dispatchEvent(evt);
            evt = document.createEvent('Event');
            evt.initEvent('resizeChange', true, true);
            window.dispatchEvent(evt);
        },
        
        /**
        * Use this method to hide the web viewer. The method has no return value and is executed asynchronously 
        * (so always listen for a result event before taking action instead of assuming the change has occurred).
        *
        * <br/>#side effects: changes state
        * <br/>#ORMMA Level: 1
        * 
        * @throws stateChange 
		* @throws resizeChange
        */
        hide : function () {
            var evt = document.createEvent('MessageEvent');
            evt.initMessageEvent('stateChange', true, true, 'hidden', null, 0, null, null);
            window.dispatchEvent(evt);
            evt = document.createEvent('Event');
            evt.initEvent('resizeChange', true, true);
            window.dispatchEvent(evt);
        },
		
		/**
		* Use this method to get the most recent compass direction of the current vertical axis of the device. 
		* To receive events when the a change occurs, register an event listener for "heading" events. Values are:
		*
		* <table>
		* <tr><th>value</th><th>description</th></tr>
		* <tr><td>-1</td><td>no heading known</td></tr>
		* <tr><td>0-359</td><td>compass direction in degrees</td></tr>
		* </table>
		*
		* <br/>#side effects: will enable the compass on device, using more battery
		* <br/>#ORMMA Level: 2
		*
		* @returns {Number} degrees
		* @see headingChange event
		*/
		getHeading : function () {
			return (registration.mockValue.heading);
		},
		
		/**
		* Use this method to get the most recent location reading from the device. To receive events when a 
		* change occurs, register an event listener for "location" events. 
		*
		* <br/>#side effects: will enable the gps on device, using more battery
		* <br/>#ORMMA Level: 2
		*
		* @returns {Object} Latitude and longitude, or null
		* @see locationChange event
		*/
		getLocation : function () {
			return (registration.mockValue.location);
		},
		
		/**
		* Use this method to identify the most recent network status of the device. To receive events when a 
		* change occurs, register an event listener for "network" events. Possible results include: 
		*
		* <table>
		* <tr><th>value</th><th>description</th></tr>
		* <tr><td>offline</td><td>no network connection</td></tr>
		* <tr><td>wifi</td><td>network using a wifi antennae</td></tr>
		* <tr><td>cell</td><td>network using a cellular antennae (such as 3G)</td></tr>
		* <tr><td>unknown</td><td>network connection in unknown state</td></tr>
		* </table>
		*
		* <br/>#side effects: will enable the antennae on device, using more battery
		* <br/>#ORMMA Level: 2
		*
		* @returns {String} network status
		* @see networkChange event
		*/
		getNetwork : function () {
			return (registration.mockValue.network);
		},
		
		/**
		* Use this method to get the most recent orientation of the device. To receive events when a 
		* change occurs, register an event listener for "orientation" events. Possible results include: 
		*
		* <table>
		* <tr><th>value</th><th>description</th></tr>
		* <tr><td>-1</td><td>device orientation unknown</td></tr>
		* <tr><td>0</td><td>0 degrees (portrait)</td></tr>
		* <tr><td>90</td><td>90 degrees (tilted clockwise to landscape)</td></tr>
		* <tr><td>180</td><td>180 degrees (portrait upside down)</td></tr>
		* <tr><td>270</td><td>270 degrees (tilted counter-clockwise to landscape)</td></tr>
		* </table>
		*
		* <br/>#side effects: none
		* <br/>#ORMMA Level: 2
		*
		* @returns {Integer} orientation degrees
		* @see orientationChange event
		*/
		getOrientation : function () {
			return (registration.mockValue.orientation);
		},
		
		/**
		* Use this method to get the current point width and height of the device. Point width (pt) 
		* is preferred over pixel width (px) because of device screens with different DPI specs.  
		*
		* <br/>#side effects: none
		* <br/>#ORMMA Level: 2
		*
		* @returns {Object} width and height
		* @see screenSizeChange event
		*/
		getScreenSize : function () {
			return (registration.mockValue.screensize);
		},
		
		/**
		* Use this method to retrieve the current shake properties.  
		*
		* <br/>#side effects: none
		* <br/>#ORMMA Level: 2
		*
		* @returns {Object} interval and intensity
		* @see shake event
		*/
		getShakeProperties : function () {
			return (registration.mockValue.shakeproperties);
		},
		
		/**
		* Use this method to set the shake properties of the ORMMA object.  
		*
		* <br/>#side effects: none
		* <br/>#ORMMA Level: 2
		*
		* @param {Object} props JSON { intensity, interval } 
		* @see shake event
		*/
		setShakeProperties : function (props) {
			registration.mockValue.shakeproperties = props;
		}

    };

/*
* Initialization
*/
	//alert listeners that this file is loaded and connection with OrmmaController is successful
	evt.initEvent('ormma', true, true, 'ready', null, 0, null, null);
    window.dispatchEvent(evt);
	
	//as a test, alert listeners of a test error to exercise their handlers
	window.setTimeout(function () {
		throwEvent('error', 'test');
	}, 1000);
		
}());