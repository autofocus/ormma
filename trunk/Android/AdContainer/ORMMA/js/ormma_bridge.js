(function() {

   var ormmaview = window.ormmaview = {};

 
 
   /****************************************************/
   /********** PROPERTIES OF THE ORMMA BRIDGE **********/
   /****************************************************/
 
   /** Expand Properties */
   var expandProperties = {
        useBackground:false,
        backgroundColor:0xffffff,
        backgroundOpacity:1.0,
        isModal:false
    };
 
 
   /** The set of listeners for ORMMA Native Bridge Events */
   var listeners = { };
 
   /** Holds the current dimension values */
   dimensions : {};
        
   /** A Queue of Calls to the Native SDK that still need execution */
   var nativeCallQueue = [ ];
 
   /** Identifies if a native call is currently in progress */
   var nativeCallInFlight = false;
 
   /** timer for identifying iframes */
   var timer;
   var totalTime;

 
 
   /**********************************************/
   /************* JAVA ENTRY POINTS **************/
   /**********************************************/
 
   /**
    * Called by the JAVA SDK when an asset has been fully cached.
    *
    * @returns string, "OK"
    */
   ormmaview.fireAssetReadyEvent = function( alias, URL ) {
      var handlers = listeners["assetReady"];
      if ( handlers != null ) {
         for ( var i = 0; i < handlers.length; i++ ) {
            handlers[i]( alias, URL );
         }
      }
 
      return "OK";
   };
 
 
   /**
    * Called by the JAVA SDK when an asset has been removed from the
	* cache at the request of the creative.
    *
    * @returns string, "OK"
    */
   ormmaview.fireAssetRemovedEvent = function( alias ) {
      var handlers = listeners["assetRemoved"];
      if ( handlers != null ) {
         for ( var i = 0; i < handlers.length; i++ ) {
            handlers[i]( alias );
         }
      }
 
      return "OK";
   };
 
 
 	ormmaview.logHTML = function(){
 		ORMMADisplayControllerBridge.logHTML(document.documentElement.innerHTML);
 	
 	};
 
   /**
    * Called by the JAVA SDK when an asset has been automatically
	* removed from the cache for reasons outside the control of the creative.
    *
    * @returns string, "OK"
    */
   ormmaview.fireAssetRetiredEvent = function( alias ) {
      var handlers = listeners["assetRetired"];
      if ( handlers != null ) {
         for ( var i = 0; i < handlers.length; i++ ) {
            handlers[i]( alias );
         }
      }
 
      return "OK";
   };
 
 
   /**
	* Called by the JAVA SDK when various state properties have changed.
    *
    * @returns string, "OK"
	*/
   ormmaview.fireChangeEvent = function( properties ) {
      var handlers = listeners["change"];
      if ( handlers != null ) {
         for ( var i = 0; i < handlers.length; i++ ) {
		    handlers[i]( properties );
         }
      }
 
      return "OK";
   };
 
 
   /**
    * Called by the JAVA SDK when an error has occured.
    *
    * @returns string, "OK"
    */
   ormmaview.fireErrorEvent = function( message, action ) {
      var handlers = listeners["error"];
      if ( handlers != null ) {
         for ( var i = 0; i < handlers.length; i++ ) {
            handlers[i]( message, action );
         }
      }
 
      return "OK";
   };
 
 
   /**
    * Called by the JAVA SDK when the user shakes the device.
    *
    * @returns string, "OK"
    */
   ormmaview.fireShakeEvent = function() {
      var handlers = listeners["shake"];
      if ( handlers != null ) {
         for ( var i = 0; i < handlers.length; i++ ) {
            handlers[i]();
         }
      }
 
      return "OK";
   };
 
 
   
 
 
   /**
    *
    */
   ormmaview.showAlert = function( message ) {
      alert( message );
   };
 
 
   /*********************************************/
   /********** INTERNALLY USED METHODS **********/
   /*********************************************/
 
 
   /**
    *
    */
   ormmaview.zeroPad = function( number ) {
      var text = "";
      if ( number < 10 ) {
         text += "0";
      }
	  text += number;
      return text;
   }
 
 
 
 
   /***************************************************************************/
   /********** LEVEL 0 (not part of spec, but required by public API **********/
   /***************************************************************************/
 
   /**
    *
    */
   ormmaview.activate = function( event ) {
   		 ORMMAUtilityControllerBridge.activate(event);
   };

 
   /**
    *
    */
   ormmaview.addEventListener = function( event, listener ) {
      var handlers = listeners[event];
	  if ( handlers == null ) {
		 // no handlers defined yet, set it up
         listeners[event] = [];
         handlers = listeners[event];
      }
 
      // see if the listener is already present
	  for ( var handler in handlers ) {
	     if ( listener == handler ) {
		    // listener already present, nothing to do
			return;
		}
	  }
 
      // not present yet, go ahead and add it
      handlers.push( listener );
   };

 
   /**
    *
    */
   ormmaview.deactivate = function( event ) {
      ORMMAUtilityControllerBridge.deactivate(event);
   };

 
   /**
    *
    */
   ormmaview.removeEventListener = function( event, listener ) {
   	  alert ('Remove!!' + event);
	  var handlers = listeners[event];
	  if ( handlers != null ) {
         handlers.remove( listener );
	  }
   };
 

 
   /*****************************/
   /********** LEVEL 1 **********/
   /*****************************/

   /**
    *
    */
   ormmaview.close = function() {
   try {
   	  ORMMADisplayControllerBridge.close();
	  } catch ( e ) {
	     alert( "close: " + e );
	  }
   };
 
 
   /**
    *
    */
   ormmaview.expand = function( dimensions, URL ) {
	  try {
		 this.dimensions = dimensions;
		 ORMMADisplayControllerBridge.expand(JSON.stringify(dimensions), URL, JSON.stringify(expandProperties));
	  } catch ( e ) {
	     alert( "executeNativeExpand: " + e + ", dimensions = " + dimensions  + ", URL = " + URL + ", expandProperties = " + expandProperties);
	  }
   };

 
   /**
    *
    */
   ormmaview.hide = function() {
   try {
	  ORMMADisplayControllerBridge.hide();
	  } catch ( e ) {
	     alert( "hide: " + e );
	  }
   };

 
   /**
    *
    */
   ormmaview.open = function( URL, controls ) {
	  // the navigation parameter is an array, break it into its parts
	  var back = false;
	  var forward = false;
	  var refresh = false;
	  if ( controls == null ) {
		 back = true;
		 forward = true;
		 refresh = true;
	  }
	  else {
		 for ( var i = 0; i < controls.length; i++ ) {
			if ( ( controls[i] == "none" ) && ( i > 0 ) ) {
			   // error
			   self.fireErrorEvent( "none must be the only navigation element present.", "open" );
			   return;
			}
			else if ( controls[i] == "all" ) {
			   if ( i > 0 ) {
				   // error
				   self.fireErrorEvent( "none must be the only navigation element present.", "open" );
				   return;
				}
				
				// ok
				back = true;
				forward = true;
				refresh = true;
			}
			else if ( controls[i] == "back" ) {
				back = true;
			}
			else if ( controls[i] == "forward" ) {
				forward = true;
			}
			else if ( controls[i] == "refresh" ) {
				refresh = true;
			}
	     }
	  }
	
	 try{
	  ORMMADisplayControllerBridge.open(URL, back, forward, refresh);
   		} catch ( e ) {
	     alert( "open: " + e );
	  }
   
   };
 
   /**
    *
    */
   ormmaview.resize = function( width, height ) {
   try {
	  ORMMADisplayControllerBridge.resize(width, height);
	  } catch ( e ) {
	     alert( "resize: " + e );
	  }
   };

 
   /**
    *
    */
   ormmaview.setExpandProperties = function( properties ) {
	  expandProperties = properties;
   };

 
   /**
    *
    */
   ormmaview.show = function() {
   try{
	  ORMMADisplayControllerBridge.show();
	  } catch ( e ) {
	     alert( "show: " + e );
	  }
   };
 
 
 
   /*****************************/
   /********** LEVEL 2 **********/
   /*****************************/

   /**
    *
    */
   ormmaview.createEvent = function( date, title, body ) {
      	var msecs=(date.getTime()-date.getMilliseconds());

		try {		
		ORMMAUtilityControllerBridge.createEvent(msecs.toString(), title, body);
		} catch ( e ) {
	     alert( "createEvent: " + e );
	  }
		
   };
 
   /**
    *
    */
   ormmaview.makeCall = function( phoneNumber ) {
   try {
	  ORMMAUtilityControllerBridge.makeCall(phoneNumber);
	  } catch ( e ) {
	     alert( "makeCall: " + e );
	  }
   };
 
 
   /**
    *
    */
   ormmaview.sendMail = function( recipient, subject, body ) {
   try {
	  ORMMAUtilityControllerBridge.sendMail(recipient, subject, body);
	  } catch ( e ) {
	     alert( "sendMail: " + e );
	  }
   };
 

   /**
    *
    */
   ormmaview.sendSMS = function( recipient, body ) {
   try {
	  ORMMAUtilityControllerBridge.sendSMS(recipient, body);
	  } catch ( e ) {
	     alert( "sendSMS: " + e );
	  }
   };
 
   /**
    *
    */
   ormmaview.setShakeProperties = function( properties ) {
   };
 
 
 
   /*****************************/
   /********** LEVEL 3 **********/
   /*****************************/

   /**
    *
    */
   ormmaview.addAsset = function( URL, alias ) {
	 
   };
   /**
    *
    */
   ormmaview.request = function( URI, display ) {
	  
   }; 
   /**
    *
    */
   ormmaview.removeAsset = function( alias ) {
   };
   })();
