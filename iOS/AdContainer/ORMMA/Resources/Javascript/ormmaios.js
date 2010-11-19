window.OrmmaBridge = {
	
	
	
	/******************************************************************/
	/***************** PROPERTIES OF THE ORMMA BRIDGE *****************/
	/******************************************************************/
	
	
	
	version : "0.1",
	
	cacheRemaining : ORMMA_UNKNOWN_VALUE,
	
	landscapeScreenSize : { height : ORMMA_UNKNOWN_VALUE, 
							width  : ORMMA_UNKNOWN_VALUE },
	portraitScreenSize : { height : ORMMA_UNKNOWN_VALUE, 
						   width  : ORMMA_UNKNOWN_VALUE },
	
	nativeCallQueue : [ ],
	nativeCallPending : false,
	
	
	
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
		var value;
		var firstArg = true;
		for ( var i = 1; i < arguments.length; i += 2 ) {
			value = arguments[i + 1];
			if ( value == null ) {
				// no value, ignore the property
				continue;
			}
			
			// add the correct separator to the name/value pairs
			if ( firstArg ) {
				bridgeCall += "?";
				firstArg = false;
			}
			else {
				bridgeCall += "&";
			}
			bridgeCall += arguments[i] + "=" + escape( value );
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
	},
	
	
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
		
		try {
		if ( data == null ) {
			event = document.createEvent( "Event" );
			event.initEvent( name, true, true );
		}
		else {
			event = document.createEvent( "MessageEvent" );
			event.initMessageEvent( name, true, true, data, null, 0, null, null );
		}
		} catch ( e ) {
			alert( "sendOrmmaEvent: " + e );
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
		this.sendOrmmaEvent( "tiltChange", { x : x, 
											 y : y, 
											 z : z } );
		
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
	 * Used to fire an Error Event.
	 *
	 * NOTE: This function is called by the native code and is not intended to be
	 *       used by anything else.
	 *
	 * @returns string, "OK" (needed for Objective-C / JS Interface)
	 */
	fireError : function( message, action ) {
		// build our data object
		var data = { message : message,
					 action : action };
		
		// send an event to everyone that cares
		this.sendOrmmaEvent( "error", data );
	},
	
	
	/**
     * Notifies the javascript API that the heading has changed.
     *
     * NOTE: This function is called by the native code and is not intended to be
     *       used by anything else.
     *
     * @param {heading} Number, the heading in degrees.
     *
     * @returns string, "OK"
     */
    headingChanged : function( heading ) {
		window.Ormma.heading = heading;
		
		// send an event to everyone that cares
		this.sendOrmmaEvent( "headingChange", heading );
		
		// all done
		return "OK";
    },
	
	
	/**
     * Notifies the javascript API that the heading has changed.
     *
     * NOTE: This function is called by the native code and is not intended to be
     *       used by anything else.
     *
     * @param {latitude}  Number, the location's latitude.
     * @param {longitude} Number, the location's longitude.
     * @param {accuracy}  Number, how acccurate the fix may be.
     *
     * @returns string, "OK"
     */
    locationChanged : function( latitude, longitude, accuracy ) {
		window.Ormma.location = { lat : latitude,
								  lon : longitude,
								  acc : accuracy };
		
		// send an event to everyone that cares
		this.sendOrmmaEvent( "locationChange", window.Ormma.location );
		
		// all done
		return "OK";
    },
	
	
	/**
	 * nativeCallComplete notifies the abstraction layer that a native call has
	 * been completed..
	 *
	 * NOTE: This function is called by the native code and is not intended to be
	 *       used by anything else.
	 *
	 * @returns string, "OK"
	 */
	nativeCallComplete : function() {
		// anything left to do?
		if ( this.nativeCallQueue.length == 0 )
		{
			this.nativeCallPending = false;
			return;
		}
		
		// still have something to do
		var bridgeCall = this.nativeCallQueue.pop();
		window.location = bridgeCall;
		
		return "OK";
	},
	
	
	
	/**
	 * Notifies the Javascript API of that the orientation of the device has
	 * changed.
	 *
	 * NOTE: This function is called by the native code and is not intended to
	 *       be used by anything else.
	 *
	 * @param {o} Number, the new orientation, in degrees.
	 *
	 * @returns string, "OK" (needed for Objective-C / JS Interface)
	 */
	orientationChanged : function( o ) {
		// update the base size
		window.Ormma.orientation = o;
		
		// update the screen size based on the new orientation
		if ( window.Ormma.isLandscape() ) {
			window.Ormma.screenSize = this.landscapeScreenSize;
		}
		else {
			window.Ormma.screenSize = this.portraitScreenSize;
		}
		
		// now fire an event to let anyone know that cares that
		// the screen size has changed.
		this.sendOrmmaEvent( "orientationChange", window.Ormma.getOrientation() );
		this.sendOrmmaEvent( "screenSizeChange", window.Ormma.screenSize );
	},
	
	
	
	/**
	 * Notifies the javascript API of updated gyroscope data.
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
	rotation : function( x, y, z ) {
		// send an event to everyone that cares
		this.sendOrmmaEvent( "rotationChange", { x : x, 
												 y : y, 
												 z : z } );
		
		// all done
		return "OK";
	},
	
	
	
	/**
	 * Notifies the Javascript API of the size of the display. The dimensions 
	 * of the display are assumed to be in portrait orientation and landscape 
	 * orientation will be calculated as needed.
	 *
	 * NOTE: This function is called by the native code and is not intended to
	 *       be used by anything else.
	 *
	 * @param {w} Number, the width of the display (assuming portrait).
	 * @param {h} Number, the height of the display (assuming portrait).
	 *
	 * @returns string, "OK" (needed for Objective-C / JS Interface)
	 */
	setBaseScreenSize : function( w, h ) {
		// update the base size
		this.portraitScreenSize = { height : h, 
									width : w };
		this.landscapeScreenSize = { height : w, 
									 width : h };
		
		// now set the current screen size (assuming portrait)
		window.Ormma.screenSize = this.portraitScreenSize;
		
		// now fire an event to let anyone know that cares that
		// the screen size has changed.
		this.sendOrmmaEvent( "screenSizeChange", window.Ormma.screenSize );
	},
	
	
	/**
	 * Notifies the Javascript API of the maximum allows size of the ad to use
	 * when resizing.
	 *
	 * NOTE: This function is called by the native code and is not intended to
	 *       be used by anything else.
	 *
	 * @param {w} Number, the maximum width of the ad.
	 * @param {h} Number, the maximum height of the ad.
	 *
	 * @returns string, "OK" (needed for Objective-C / JS Interface)
	 */
	setMaxSize : function( w, h ) {
		window.Ormma.maxSize.height = h;
		window.Ormma.maxSize.width = w;
	},
	
	
	/**
	 * Notifies the Javascript API of the current size of the ad.
	 *
	 * NOTE: This function is called by the native code and is not intended to
	 *       be used by anything else.
	 *
	 * @param {w} Number, the width of the ad.
	 * @param {h} Number, the height of the ad.
	 *
	 * @returns string, "OK" (needed for Objective-C / JS Interface)
	 */
	sizeChanged : function( w, h ) {
		// update the base size
		window.Ormma.size = { height : h, 
							  width  : w };
		
		// now fire an event to let anyone know that cares that
		// the screen size has changed.
		this.sendOrmmaEvent( "sizeChange", window.Ormma.size );
	},
	
	
	/**
	 * Notifies the Javascript API of a change in the current ad state.
	 *
	 * NOTE: This function is called by the native code and is not intended to
	 *       be used by anything else.
	 *
	 * @param {s} String, the new state.
	 *
	 * @returns string, "OK" (needed for Objective-C / JS Interface)
	 */
	stateChanged : function( s ) {
		// update the base size
		window.Ormma.state = s;
		
		// now fire an event to let anyone know that cares that
		// the screen size has changed.
		this.sendOrmmaEvent( "stateChange", window.Ormma.state );
	},
	
	
	
	
    /***************************************************************/
    /******************** API INTERFACE METHODS ********************/
    /***************************************************************/
	
	
    /**
     * Requests that the native SDK enable or disable a specified service.
     *
     * @param {name}    String, The name of the event.
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
     * @param {url}   String, the source location of the resource.
     *
     * @returns nothing.
     */
    executeNativeAddAsset : function( url ) {
		this.executeNativeCall( "addasset", 
							    "uri", url );
	},
	
	
    /**
     * Requests that the native SDK close an expanded or full screen ad.
     *
     * @returns nothing.
     */
	executeNativeCalendar : function( date, title, body) {
		this.executeNativeCall( "calendar",
							    "date", date,
							    "title", title,
							    "body", body );
	},
	
	
    /**
     * Requests that the native SDK close an expanded or full screen ad.
     *
     * @returns nothing.
     */
	executeNativeCamera : function( date, title, body) {
		this.executeNativeCall( "camera" );
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
     * @param {finalDimensions} JSON: { x, y, w, h }, the final dimensions to
     *                          use for the expand action.
     * @param {url} String, the URL to display.
     *
     * @returns nothing.
     */
    executeNativeExpand : function( finalDimensions, url ) {
		try {
			var cmd = "this.executeNativeCall( 'expand'";
			if ( url != null ) {
				cmd += ", 'url', '" + url + "'";
			}
			if ( ( typeof finalDimensions.x != "undefined" ) && ( finalDimensions.x != null ) ) {
				cmd += ", 'x', '" + finalDimensions.x + "'";
			}
			if ( ( typeof finalDimensions.y != "undefined" ) && ( finalDimensions.y != null ) ) {
				cmd += ", 'y', '" + finalDimensions.y + "'";
			}
			if ( ( typeof finalDimensions.width != "undefined" ) && ( finalDimensions.width != null ) ) {
				cmd += ", 'w', '" + finalDimensions.width + "'";
			}
			if ( ( typeof finalDimensions.height != "undefined" ) && ( finalDimensions.height != null ) ) {
				cmd += ", 'h', '" + finalDimensions.height + "'";
			}
			var props = window.Ormma.expandProperties;
			if ( ( typeof props.useBackground != "undefined" ) && ( props.useBackground != null ) ) {
				cmd += ", 'useBG', '" + props.useBackground + "'";
			}
			if ( ( typeof props.backgroundColor != "undefined" ) && ( props.backgroundColor != null ) ) {
				cmd += ", 'bgColor', '" + props.backgroundColor + "'";
			}
			if ( ( typeof props.backgroundOpacity != "undefined" ) && ( props.backgroundOpacity != null ) ) {
				cmd += ", 'bgOpacity', '" + props.backgroundOpacity + "'";
			}
			cmd += " );";
			eval( cmd );
	    } catch ( e ) {
			alert( "executeNativeExpand: " + e + ", cmd = " + cmd );
	    }
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
     * Requests that the native SDK remove all cached resources for the
	 * current creative.
     *
     * @returns nothing.
     */
	executeNativeOpen : function( url, navigation ) {
		// the navigation parameter is an array, break it into its parts
		var back = false;
		var forward = false;
		var refresh = false;
		if ( navigation == null ) {
			back = true;
			forward = true;
			refresh = true;
		}
		else {
			for ( var i = 0; i < navigation.length; i++ ) {
				if ( ( navigation[i] == "none" ) && ( i > 0 ) ) {
					// error
					self.sendOrmmaEvent( "none must be the only navigation element present.", "open" );
					return;
				}
				else if ( navigation[i] == "all" ) {
					if ( i > 0 ) {
						// error
						self.sendOrmmaEvent( "none must be the only navigation element present.", "open" );
						return;
					}
					
					// ok
					back = true;
					forward = true;
					refresh = true;
				}
				else if ( navigation[i] == "back" ) {
					back = true;
				}
				else if ( navigation[i] == "forward" ) {
					forward = true;
				}
				else if ( navigation[i] == "" ) {
					refresh = true;
				}
			}
		}
		
		
		this.executeNativeCall( "open",
							    "url", url,
							    "back", ( back ? "Y" : "N" ),
							    "forward", ( forward ? "Y" : "N" ),
							    "refresh", ( refresh ? "Y" : "N" ) );
	},
	
	
	
    /**
     * Requests that the native SDK display the specified URL in a browser
	 * window.
     *
     * @param {url} String, the url to display.
     *
     * @returns nothing.
     */
    executeNativePhone : function( phoneNumber ) {
		this.executeNativeCall( "phone",
						        "number", phoneNumber );
    },
	
	
	
    /**
     * Requests that the native SDK remove all cached resources for the
	 * current creative.
     *
     * @returns nothing.
     */
	executeNativeRemoveAllAssets : function() {
		this.executeNativeCall( "removeallassets" );
	},
	
	
	
    /**
     * Requests that the native SDK remove the resource specified by the alias
	 * from the cache.
     *
     * @param {alias} String, alias of the resource.
     *
     * @returns nothing.
     */
    executeNativeRemoveAsset : function( url ) {
		this.executeNativeCall( "removeasset", 
							    "url", url );
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
		this.executeNativeCall( "request", 
							    "uri", uri, 
							    "display", display );
    },
	
	
	
    /**
     * Requests that the native SDK resize the current ad to the specified 
	 * dimensions using the same ad view.
     *
     * NOTE: this will modify the size of the ad in place. It is therefore
	 *       possible that the new ad may be clipped depending on the
	 *       application's view hierarchy.
     *
     * @param {width}  Number, the new width of the ad.
     * @param {height} Number, the new height of the ad.
     *
     * @returns nothing.
     */
    executeNativeResize : function( width, height ) {
		if ( width > window.Ormma.maxSize.width ) {
			var data = { message : "Unable to resize creative width to " + width + "] which is larger than maximum allowed width of " + window.Ormma.maxSize.width + ".",
				         action : "resize" };
			this.sendOrmmaEvent( "error", data );
			return;
		}
		if ( height > window.Ormma.maxSize.height ) {
			var data = { message : "Unable to resize creative height to " + height + " which is larger than maximum allowed height of [" +  window.Ormma.maxSize.height + ".",
				action : "resize" };
			this.sendOrmmaEvent( "error", data );
			return;
		}
		
		// ok to perform the resize
		this.executeNativeCall( "resize", "w", width, "h", height );
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
	
	
	
	// end of OrmaBridge Definition 
};