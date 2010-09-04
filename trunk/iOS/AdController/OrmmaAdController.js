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
        properties : {},

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
         * @param {Object} properties Additional properties, such as transition effects
         * @param {Function} listener The listener function
         * @returns nothing
         */
        resize : function (dimensions, properties, listener) {

            this.dimensions = dimensions;
            this.properties = properties;

            _resize(dimensions, properties);

            if (typeof listener == 'function') {
                this.addEventListener('resize', listener);
            }
            fireEvent('resize', dimensions, properties);
        },


        /**
         * reset the window size to the original state
         * @param {Function} listener The listener function
         * @returns nothing
         */
        resetSize : function (listener) {

            _resetSize();

            if (typeof listener == 'function') {
                this.addEventListener('resetSize', listener);
            }
            fireEvent('resetSize');
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
        //@implementation required by SDK vendor
    }

    function _resetSize () {
        //@implementation required by SDK vendor
    }

    function ormma_callInApp (functionWithParameters) {
        document.location= "";// implementation required by SDK vendor
    }

})();





