/**
 * Anonymous function to encapsulate the OrmmaAdController methods
 */
(function() {

    /**
     * The main ad controller object
     */
    window.OrmmaAdController = {

        /**
         * The object that holds all types of OrmmaAdController events and associated listeners
         */
        events : [],

        /**
         * Holds the current dimension values
         */
        dimensions : {},

        /**
         * Holds the current property values
         */
        properties :  {"transition": "none",
			"navigation":"none",
			"use-background":false,
			"background-color" : "#000000",
			"background-opacity" : 1.0,
			"is-modal" : true},
			
		state : "default",	

        /**
         * addEventListener adds an event listener to the listener array
         * @param {String} event The event name
         * @param {Function} listener The listener function
         * @returns nothing
         */
        addEventListener : function (event, listener) {
            if (typeof listener == 'function') {
                if (!this.events[event]) {
                    this.events[event] = [];
                }
                if (!this.events[event].listeners) {
                    this.events[event].listeners = [];
                }
                if (getListenerIndex(event, listener) === -1) {
                    this.events[event].listeners.splice(0, 0, listener);
                }
                if (event == 'locationChange'){
                	_startLocationListener();
                }
            }
        },

        /**
         * removeEventListener removes an event listener from the listener array
         * @param {String} event The event name
         * @param {Function} listener The listener function
         * @returns nothing
         */
        removeEventListener : function (event, listener) {
            if (typeof listener == 'function' && this.events[event] && this.events[event].listeners) {
                var listenerIndex = getListenerIndex(event, listener);
                if (listenerIndex !== -1) {
                    this.events[event].listeners.splice(listenerIndex, 1);
                }
            }
        },

        /**
         * resize resizes the display window
         * @param {Object} dimensions The new dimension values of the window
         * @returns nothing
         */
        resize : function (dimensions) {

            this.dimensions = dimensions;

            _resize(this.dimensions, this.properties);

            fireEvent('sizeChange', dimensions, properties);
            this.state = 'expanded';
            fireEvent('stateChange', 'expanded');
        },


        setResizeProperties : function (properties) {

            this.properties = properties;
        },



        /**
         * reset the window size to the original state
         * @param {Function} listener The listener function
         * @returns nothing
         */
        close : function () {

            _close();
            this.state = 'default';
            fireEvent('stateChange', 'default');
        },
        
        /**
         * Use this method to get the available size of the local cache.
         * @param none
         * @returns available size of local cache
         */
		cacheRemaining : function() {
				return _cacheRemaining();
		},

        /**
         * Use this method to hide the web viewer.
         * @param none
         * @returns nothing
         */
		hide : function() {
			_hide();
			this.state = 'hidden';
			fireEvent('stateChange', 'hidden');
		},

		show : function() {
			_show();
			this.state = 'default';
			fireEvent('stateChange', 'default');
		},
        /**
         * Use this method to get the current state of the web viewer. 
         * @param none
         * @returns boolean reflecting visible state
         */		
		getState : function() {
			return this.state;
		},
		
        /**
         * Adds an asset 
         * @param {String} alias name that ad developer will use to refer to asset URI
         * @param {String} uri actual URI of the asset
         * @returns nothing
         */
		addAsset : function(alias, uri) {
			_addAsset(alias, uri);
    	},
        /**
         * Adds a list of assets
         * @param {abstract array}  an abstract array (aka standard JavaScript Object) of alias/uri key-value pairs.
         * @returns nothing
         */

		addAssets : function(assets) {
			var key;
    		for (key in assets) {
				_addAsset(key, assets[key]);
			}
    	},
    	
    	addedAsset: function (alias) {
    		fireEvent('assetReady',alias);
    	},

        /**
         * Adds an asset 
         * @param {String} alias name that ad developer will use to refer to asset URI
         * @param {String} uri actual URI of the asset
         * @returns nothing
         */
		removeAsset : function(alias) {
			_removeAsset(alias);
    	},
    	removededAsset: function (alias) {
    		fireEvent('assetReady',alias);
    	},

		getHeading: function() {
			return _getHeading();
		},

		getLocation: function() {
			return _getLocation();
		},

		getNetwork: function() {
			return _getNetwork();
		},

		getOrientation: function() {
			return _getOrientation();
		},

		getResizeDimensions: function() {
			return dimensions;
		},

		getResizeProperties: function() {
			return properties;
		},

		getScreenSize: function() {
			return _getScreenSize();
		},

		getShakeProperties: function() {
			return _getShakeProperties();
		},

		getState: function() {
			return _getState();
		},
		
		locationChanged: function(loc){
		//	location = eval('(' + loc +')');
		//	alert(loc);
			fireEvent('locationChange',loc);
		}
		
		
		
		
		
		


	};
    /**
     * The private methods
     */


    /**
     * getListenerIndex retrieves the index of listener from the event listener array
     * @private
     * @param {String} event The event name
     * @param {Function} listener The listener function
     * @returns the index value of the listener array, -1 if the listener doesn't exist
     */
    function getListenerIndex (event, listener) {
        var len, i;
        if (OrmmaAdController.events[event] && OrmmaAdController.events[event].listeners) {
            len = OrmmaAdController.events[event].listeners.length;
            for (i = len-1;i >= 0;i--) {
                if (OrmmaAdController.events[event].listeners[i] === listener) {
                    return i;
                }
            }
        }
        return -1;
    }

    /**
     * fireEvent fires an event
     * @private
     * @param {String} event The event name
     * @param {Object} additional information about the event
     * @returns nothing
     */
    function fireEvent (event, args) {
        var len, i;
        if (OrmmaAdController.events[event] && OrmmaAdController.events[event].listeners) {
            len = OrmmaAdController.events[event].listeners.length;
            for (i = len-1; i >= 0; i--) {
                (OrmmaAdController.events[event].listeners[i])(event, args);
            }
        }
    }

    /* implementations of public methods for specific vendors */

    function _resize (dimensions, properties) {
        ORMMADisplayControllerBridge.resize(JSON.stringify(dimensions), JSON.stringify(properties));
    }

    function _close () {
        ORMMADisplayControllerBridge.close();
    }

	function _cacheRemaining() {
		return ORMMAAssetsControllerBridge.cacheRemaining();
	}

	function _hide() {
		ORMMADisplayControllerBridge.hide();
	}

	function _show() {
		ORMMADisplayControllerBridge.show();
	}


	function _addAsset(alias, uri) {
		ORMMAAssetsControllerBridge.addAsset(alias, uri);
	}

	function _removeAsset(alias) {
		ORMMAAssetsControllerBridge.removeAsset(alias);
	}

	function _getHeading() {
		return ORMMALocationControllerBridge.getHeading();
	}

	function _getLocation() {
		return eval('('+ORMMALocationControllerBridge.getLocation()+')');
	}

	function _getNetwork() {
		return ORMMANetworkControllerBridge.getNetwork();
	}
	function _getOrientation() {
		return ORMMADisplayControllerBridge.getOrientation();
	}

	function _getScreenSize() {
		return eval('('+ORMMADisplayControllerBridge.getScreenSize()+')');
	}
	
	function _startLocationListener(){
		ORMMALocationControllerBridge.startLocationListener();
	}

})();