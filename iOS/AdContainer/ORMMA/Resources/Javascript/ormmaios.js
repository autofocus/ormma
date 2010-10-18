window.OrmmaBridge = {
 
 
 
 /******************************************************************/
 /***************** PROPERTIES OF THE ORMMA BRIDGE *****************/
 /******************************************************************/
 
 
 
   version = "0.1",

   cacheRemaining = ORMMA_UNKNOWN_VALUE,

   pendingResizeDimensions = { ORMMA_PROPERTY_X : ORMMA_UNKNOWN_VALUE, 
	                           ORMMA_PROPERTY_Y : ORMMA_UNKNOWN_VALUE, 
	                           ORMMA_PROPERTY_HEIGHT : ORMMA_UNKNOWN_VALUE, 
	                           ORMMA_PROPERTY_WIDTH : ORMMA_UNKNOWN_VALUE },
   resizeDimensions = { ORMMA_PROPERTY_X : ORMMA_UNKNOWN_VALUE, 
	                    ORMMA_PROPERTY_Y : ORMMA_UNKNOWN_VALUE, 
	                    ORMMA_PROPERTY_HEIGHT : ORMMA_UNKNOWN_VALUE, 
	                    ORMMA_PROPERTY_WIDTH : ORMMA_UNKNOWN_VALUE },
   baseScreenSize = { ORMMA_PROPERTY_HEIGHT : ORMMA_UNKNOWN_VALUE, 
	                  ORMMA_PROPERTY_WIDTH : ORMMA_UNKNOWN_VALUE },
   shakeProperties = { ORMMA_PROPERTY_INTENSITY : 0, 
	                   ORMMA_PROPERTY_INTERVAL : 0 },
  
   nativeCallQueue = [ ],
   nativeCallPending = false,
 
 
 
   /******************************************************************/
   /***************** INTERNALLY USED FUNCTIONS ONLY *****************/
   /******************************************************************/

 
 
   /**
    * Executes or queues a call into native code.
    *
    * NOTE: Since our communications mechanism with iOS is via a navigation
    *       event, we need to ensure that we don't overwrite events. We
    *       therefore queue up all native code requests and execute them
    *       sequentially one after the next.
    *
    * NOTE: This function is called by the bridge code and is not intended to
    *       be used by anything else.
    *
    * @param {command}  String, the command to execute.
    * @param {args1..n} String, Optional, additional arguments. Must be in pairs.
    *                   (i.e. matching name-value pairs).
    *
    * @returns string, "OK"
    */
   executeNativeCall : function( command ) {
      // build iOS command
      var bridgeCall = "ormma://" + command;
      for ( var i = 1; i < arguments.length; i += 2 ) {
         if ( i == 1 ) {
            bridgeCall += "?";
         }
         else {
            bridgeCall += "&";
         }
         bridgeCall += arguments[i] + "=" + escape( arguments[i + 1] );
      }
 
      // add call to queue
      if ( this.nativeCallPending ) {
         // call pending, queue up request
         this.nativeCallQueue.push( bridgeCall );
      }
      else {
         // no call currently in process, execute it directly
         this.nativeCallPending = true;
         window.location = bridgeCall;
      }
   }
 
 
   /**
    * Creates and dispatches a javascript event based on the passed name and
	* data.
    *
    * @param {name} String, the name of the event.
    * @param {data} Object, Optional, the payload of the event. Generally will
	*               be either NULL, JSON, or a string.
    */
   sendOrmmaEvent : function( name, data ) {
      var event;
 
      if ( data == null ) {
         event = document.createEvent( "Event" );
         evt.initMessageEvent( name, true, true );
      }
      else {
         event = document.createEvent( "MessageEvent" );
         evt.initMessageEvent( name, true, true, data, null, 0, null, null );
      }
      window.dispatchEvent( event ); 
   },
 
 
 
   /*******************************************************************/
   /***************** FUNCTIONS CALLED BY OBJECTIVE-C *****************/
   /*******************************************************************/
 
 
 
   /**
    * Notifies the javascript API of updated accelerometer data.
    *
    * NOTE: This function is called by the native code and is not intended to
    *       be used by anything else.
    *
    * @param {x} Number, the value for the X axis.
    * @param {y} Number, the value for the Y axis.
    * @param {z} Number, the value for the Z axis.
    *
    * @returns string, "OK" (needed for Objective-C / JS Interface)
    */
   acceleration : function( x, y, z ) {
      // send an event to everyone that cares
      this.sendOrmmaEvent( "tiltChange", { ORMMA_PROPERTY_X : x, 
						                   ORMMA_PROPERTY_Y : y, 
						                   ORMMA_PROPERTY_Z : z } );
 
      // all done
      return "OK";
   },
 
  
   /**
    * Adds an available feature to the list of available features for this
    * device.
    *
    * NOTE: This function is called by the native code and is not intended to
    *       be used by anything else.
    *
    * @param {feature} String, the name of the feature.
    *
    * @returns string, "OK" (needed for Objective-C / JS Interface)
    */
   addFeature : function( feature ) {
      if ( window.ormma.supportedFeatures.indexOf( feature ) == -1 ) {
         window.ormma.supportedFeatures.push( feature );
      }
      return "OK";
   },
 
 
 
   /**
    * Notifies the javascript API that the native code SDK has completed startup
	* and is ready in all respects.
    *
    * NOTE: This function is called by the native code and is not intended to be
    *       used by anything else.
    *
    * @returns string, "OK" (needed for Objective-C / JS Interface)
    */
   applicationReady : function() {
      // send an event to everyone that cares
      this.sendOrmmaEvent( "ready", null );
      return "OK";
   },
 
 
   /**
     * Notifies the javascript API that the heading has changed.
     *
     * NOTE: This function is called by the native code and is not intended to be
     *       used by anything else.
     *
     * @param {magneticHeading} Number, the magnetic heading in degrees.
     * @param {trueHeading}     Number, the true heading, in degrees.
     * @param {accuracy}        Number, how acccurate the heading may be.
     * @param {timestamp}       Date-Time, when the heading was taken.
     *
     * @returns string, "OK"
     */
    headingChanged : function( magneticHeading, trueHeading, accuracy, timestamp ) {
       this.heading = trueHeading;
 
       // send an event to everyone that cares
       this.sendOrmmaEvent( "headingChange", trueHeading );
 
       // all done
       return "OK";
    },
 
 
 
 
    /***************************************************************/
    /******************** API INTERFACE METHODS ********************/
    /***************************************************************/
 
 
 
    /**
     * Requests that the native SDK enable or disable a specified service.
     *
     * @param {name}    String, The name of the service.
     * @param {enabled} Boolean, flag indicating if the service should be 
     *                  enabled or disabled.
     *
     * @returns nothing.
     */
    enableNativeEventsForService : function( name, enabled ) {
       this.executeNativeCall( "service", 
							   "name", name, 
							   "enabled", ( enabled ? "yes" : "no" ) );
    },
 
 
 
    /**
     * Requests that the native SDK add a new asset to the cache from the 
	 * specified location.
     *
     * @param {alias} String, alias to use for the resource.
     * @param {uri}   String, the source location of the resource.
     *
     * @returns nothing.
     */
    executeNativeAddAsset : function( alias, uri ) {
       this.executeNativeCall( "addasset", 
							   "alias", alias, 
							   "uri", uri );
	},
 
 
 
    /**
     * Requests that the native SDK close an expanded or full screen ad.
     *
     * @returns nothing.
     */
    executeNativeClose : function() {
       this.executeNativeCall( "close" );
    },
 
 
 
    /**
     * Requests that the native SDK send an email with the specified properties.
     *
     * @param {to}      String, the recipient of the message
     * @param {subject} Strng, the subject of the message
     * @param {body}    String, the body of the message
     * @param {html}    Boolean, true if the body is HTML, false otherwise
     *
     * @returns nothing.
     */
    executeNativeEMail : function( to, subject, body, html ) {
       this.executeNativeCall( "email",
		        			   "to", to,
						       "subject", subject,
						       "body", body,
						       "html", ( html ? "Y" : "N" ) );
    },
 
 
 
    /**
     * Requests that the native SDK resize the current ad to the specified
	 * dimensions using a separate view.
     *
     * @param {dimensions} ORMMADimensions, the dimensions to use for the
     *                     expand action.
     *
     * @returns nothing.
     */
    executeNativeExpand : function( initialDimensions, finalDimensions, URL ) {
       this.pendingResizeDimensions = finalDimensions;
       this.executeNativeCall( "expand", 
						       "url", URL,
						       "x1", initialDimensions.x, 
						       "y1", initialDimensions.y,
						       "w1", initialDimensions.width,
						       "h1", initialDimensions.height,
						       "x1", finalDimensions.x, 
						       "y1", finalDimensions.y,
						       "w1", finalDimensions.width,
						       "h1", finalDimensions.height,
						       "transition", this.expandProperties.transition,
						       "navigation", this.expandProperties.navigation,
						       "useBG",      this.expandProperties.useBackground,
						       "bgColor",    this.expandProperties.backgroundColor,
						       "bgOpacity",  this.expandProperties.backgroundOpacity,
						       "modal",      this.expandProperties.isModal );
    },
 
 
 
    /**
     * Requests that the native SDK hide the ad.
     *
     * @returns nothing.
     */
    executeNativeHide : function() {
       this.executeNativeCall( "hide" );
    },
 
 
 
    /**
     * Requests that the native SDK call the specified phone number.
     *
     * @param {phoneNumber} String, the phone number to dial
     *
     * @returns nothing.
     */
    executeNativePhone : function( phoneNumber ) {
       this.executeNativeCall( "phone",
						       "number", phoneNumber );
    },
 
 
 
    /**
     * Requests that the native SDK remove the resource specified by the alias
	 * from the cache.
     *
     * @param {alias} String, alias of the resource.
     *
     * @returns nothing.
     */
    executeNativeRemoveAsset : function( alias ) {
       this.executeNativeCall( "removeasset", "alias", alias );
    },
 
 
 
    /**
     * Requests that the native SDK execute the specified HTTP request.
     *
     * @param {uri}     String, the source URI for the request.
     * @param {display} String, the display style to use.
     *
     * @returns nothing.
     */
    executeNativeRequest : function( uri, display ) {
       this.executeNativeCall( "request", "uri", uri, "display", display );
    },
 
 
 
    /**
     * Requests that the native SDK resize the current ad to the specified 
	 * dimensions using the same ad view.
     *
     * NOTE: this will modify the size of the ad in place. It is therefore
	 *       possible that the new ad may be clipped depending on the
	 *       application's view hierarchy.
     *
     * @param {height} Number, the new height of the ad.
     * @param {width}  Number, the new width of the ad.
     *
     * @returns nothing.
     */
    executeNativeResize : function( height, width ) {
       // save pending resize
       var d = new ORMMADimensions();
       d.x = this.resizeDimensions.x;
       d.y = this.resizeDimensions.y;
       d.height = height;
       d.width = width;
       this.pendingResizeDimensions = d;
 
       this.executeNativeCall( "resize",   
		 				       "w", width,
						       "h", height,
						       "transition", this.resizeProperties.transition );
    },
	
	
	
	/**
	 * Notifies the native SDK that the ad is ready for display.
	 *
	 * @returns nothing.
	 */
	executeNativeShow : function() {
		this.executeNativeCall( "show" );
	},
	
	
	
	/**
	 * Requests that the native SDK send an SMS with the specified properties.
	 *
	 * @param {to}      String, the recipient of the message
	 * @param {body}    String, the body of the message
	 *
	 * @returns nothing.
	 */
	executeNativeSMS : function( to, body ) {
		this.executeNativeCall( "sms",
							    "to", to,
							    "body", body );
	},
	
	
	
    /**
     * Retrieves the current orientation of the device.
     *
     * @returns the orientation.
     */
    orientation : function() {
		var o = window.orientation;
		if ( o == 0 ) {
			return ORMMA_ORIENTATION_PORTRAIT;
		}
		else if ( o == 90 ) {
			return ORMMA_ORIENTATION_LANDSCAPE_LEFT;
		}
		else if ( o == 180 ) {
			return ORMMA_ORIENTATION_PORTRAIT_UPSIDE_DOWN;
		}
		
		// must be Landscape right
		return ORMMA_ORIENTATION_LANDSCAPE_RIGHT;
    },
	
 
 
// end of OrmaBridge Definition 
};