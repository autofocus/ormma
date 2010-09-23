/*global window, Ormma */

/**
 * @fileOverview This sample file demonstrates a functional style usage of the ORMMA JavaScript SDK
 *  All Level One methods are exercised.
 *
 * @author <a href="mailto:nathan.carver@crispwireless.com">Nathan Carver</a>
 * @version 0.0.1
 */
 

/**
* helper function to output debugging data to the console
*
* @param {String} msg text to output
*/
function logit(msg) {
	if (console) {
		console.log((new Date()).getTime() + '-' + msg);
	}
}

/**
* helper function to generate output for all events
*
* @param {Event} evt event to get information on
*/
function reportEvent(evt) {
	var msg = 'Event fired: ' + evt.type 
	if (evt.data) {
		msg = msg + ':' + evt.data
	}
	logit(msg);
}

/**
* triggered by initAd, clean-up after ad is shown
*
* @see initAd
* @requires Ormma
*/
function confirmShow() {
	Ormma.removeEventListener('stateChange', confirmShow);
	logit('ad is showing');
	var oEl = document.getElementById('banner');
	oEl.style.display = 'block';
}

/**
* init started at the end of loading this file, shows the ad
*
* @param {Event} evt the ready event
* @requires Ormma
*/
function initAd(evt) {
	var myState = Ormma.getState();
	if (myState !== 'hidden') {
		Ormma.addEventListener('stateChange', confirmShow);
		Ormma.show();
	}
}

/**
* triggered by resizeChange from confirmResizeToMaxSize call,
*  clean-up on expand, show/hide the ad creative elements,
*  discovers if there is support for the native tilt functionality
* 
* @see confirmResizeToMaxSize
* @requires Ormma
*/
function confirmExpand() {
	logit('ad is expanded');
	Ormma.removeEventListener('stateChange', confirmExpand);
	var oEl = document.getElementById('panel');
	oEl.style.display = 'block';
	oEl = document.getElementById('banner');
	oEl.style.display = 'none';
	
	if (Ormma.supports('tilt')) {
		logit('ad supports tilt');
	} else {
		logit('ad does not support tilt');
	}
}

/**
* triggered by resizeChange event from confirmResizeToSameSize call,
*   clean-up on resize, then attempts to expand the ad
*
* @see confirmResizeToSameSize
* @requires Ormma
*/
function confirmResizeToMaxSize() {
	logit('ad is max sized');
	Ormma.removeEventListener('resizeChange', confirmResizeToMaxSize);
	var props = Ormma.getExpandProperties();
	Ormma.setExpandProperties(props);
	Ormma.addEventListener('stateChange', confirmExpand);
	Ormma.expand({'top' : 0, 'left' : 0, 'bottom' : 100, 'right' : 100}, {'top' : 0, 'left' : 0, 'bottom' : 300, 'right' : 300});
}

/** 
* triggered by resizeChange event from resizeAd call, 
*  clean-up on resize, then attempts to resize to max size
*
* @see resizeAd
* @requires Ormma
*/
function confirmResizeToSameSize() {
	logit('ad is resized');
	Ormma.removeEventListener('resizeChange', confirmResizeToSameSize);
	var props = Ormma.getMaxSize();
	Ormma.setResizeProperties(props);
	Ormma.addEventListener('resizeChange', confirmResizeToMaxSize);
	Ormma.resize(250, 300);
}

/**
* triggered by user interaction, attempts to resize ad to same size
*
* @returns {Boolean} false - so click event can stop propogating
* @requires Ormma
*/
function resizeAd() {
	var props = Ormma.getResizeProperties();
	Ormma.setResizeProperties(props);
	Ormma.addEventListener('resizeChange', confirmResizeToSameSize);
	Ormma.resize(props);
	return (false);
}

/**
* triggered by response event from sendOrmmaRequest call, tries to embed the data into the ad
* 
* @param {Event} evt The event
* @requires Ormma
*/
function receiveResponse(evt) {
	logit('response received');
	Ormma.removeEventListener('response', receiveResponse);
	var data = evt.data;
	var ajaxResponse = data.split(',')[1];
	document.getElementById('ajax').innerHTML = ajaxResponse;
}


/**
* triggered by user interaction, tries to view new url in internal viewer
* 
* @param {String} href The URL to request
* @returns {Boolean} false response from Ormma.request so click event can be cancelled
* @requires Ormma
*/
function sendOrmmaRequest(href) {
	Ormma.addEventListener('response', receiveResponse);
	Ormma.request('http://ajax.com/', 'proxy');
	return Ormma.request(href, 'internal');
}

/**
* triggered by stateChange event from hideBanner call
*   does some clean-up
* 
* @requires Ormma
*/
function confirmHide() {
	logit('ad is hidden');
	Ormma.removeEventListener('stateChange', confirmHide);
	var oEl = document.getElementById('banner');
	oEl.style.display = 'none';
	oEl = document.getElementById('closebanner');
	oEl.style.display = 'none';
}

/**
* triggered by user interaction, attempts to hide the ad
*
* @returns {Boolean} false - so event can be cancelled
* @requires Ormma
*/
function hideBanner() {
	Ormma.addEventListener('stateChange', confirmHide);
	Ormma.hide();
	return(false);
}

/**
* triggered by stateChange event from collapse call,
*   does some clean up and then shows/hides the banner/panel
*
* @requires Ormma
*/
function confirmCollapse() {
	logit('ad is no longer expanded');
	Ormma.removeEventListener('stateChange', confirmCollapse);
	
	var oEl = document.getElementById('panel');
	oEl.style.display = 'none';
	oEl = document.getElementById('banner');
	oEl.style.display = 'block';
	oEl = document.getElementById('closebanner');
	oEl.style.display = 'block';
}

/**
* triggered by user interaction to close expanded add, attempts
*   to close the ad in-app
*
* @requires Ormma
*/
function collapse() {
	Ormma.addEventListener('stateChange', confirmCollapse);
	Ormma.close();
}

/**
* register event listeners and initialize the ad
*
* @requires Ormma
*/
Ormma.addEventListener('error', reportEvent);
Ormma.addEventListener('ready', reportEvent);
Ormma.addEventListener('resizeChange', reportEvent);
Ormma.addEventListener('response', reportEvent);
Ormma.addEventListener('screenSizeChange', reportEvent);
Ormma.addEventListener('stateChange', reportEvent);
