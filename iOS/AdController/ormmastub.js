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
            window.addEventListener(evt, listener, false);
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
            return ( {'height' : '250', 'width' : '320'});
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
            return (false);
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
        }

    };

    /*
    * Throw event indicating that connection with ORMMA Container has initialized successfully 
    */
	var evt = document.createEvent('MessageEvent');
	evt.initEvent('ormma', true, true, 'ready', null, 0, null, null);
    window.dispatchEvent(evt);
	
	/*
	* Set time out to throw an error as a test
	*/
	window.setTimeout(throwError, 1000);
	function throwError() {
		var evt = document.createEvent('MessageEvent');
		evt.initMessageEvent('error', true, true, 'test', null, 0, null, null);
		window.dispatchEvent(evt);
	}
}());