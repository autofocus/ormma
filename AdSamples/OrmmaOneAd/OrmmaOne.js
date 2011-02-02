/*global window, ormma */

/**
 * @fileOverview This sample file demonstrates a functional style usage of the ORMMA JavaScript SDK
 *  All Level One methods are exercised.
 *
 * @author <a href="mailto:nathan.carver@crispmedia.com">Nathan Carver</a>
 * @version 1.0.1
 */
 

/**
* helper function to output debugging data to the console
*
* @param {String} msg text to output
*/
function logit(msg) {
	if (typeof(console)!=='undefined') {
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
* @requires ormma
*/
function confirmShow() {
	try {
		ormma.removeEventListener('stateChange', confirmShow);
		logit('ad is showing');
	} catch (e) {logit('ORMMA not found');}
	var oEl = document.getElementById('banner');
	oEl.style.display = 'block';
}

/**
* ORMMAReady called by the SDK, initializes the ad
* register event listeners and initialize the ad
*
* @requires ormma
*
*/
function ORMMAReady(evt) {
	clearTimeout(ormmaWaitId);
	var myState = ormma.getState();
	
	ormma.addEventListener('error', reportEvent);
	ormma.addEventListener('response', reportEvent); /* confirm this is level1 */
	ormma.addEventListener('sizeChange', reportEvent);
	ormma.addEventListener('stateChange', reportEvent);

	if (myState !== 'hidden') {
		ormma.addEventListener('stateChange', confirmShow);
		ormma.show();
	}
}

/**
* triggered by resizeChange from confirmResizeToMaxSize call,
*  clean-up on expand, show/hide the ad creative elements,
*  discovers if there is support for the native tilt functionality
* 
* @see confirmResizeToMaxSize
* @requires ormma
*/
function confirmExpand() {
	logit('ad is expanded');
	try {
		ormma.removeEventListener('stateChange', confirmExpand);
	} catch (e) {
		logit("ORMMA not found for confirmExpand");
	}
	var oEl = document.getElementById('panel');
	oEl.style.display = 'block';
	oEl = document.getElementById('banner');
	oEl.style.display = 'none';
	
	if (typeof(ormma)!=='undefined' && ormma.supports('tilt')) {
		logit('ad supports tilt');
	} else {
		logit('ad does not support tilt or ORMMA not found');
	}
}

/**
* triggered by resizeChange event from confirmResizeToSameSize call,
*   clean-up on resize, then attempts to expand the ad
*
* @see confirmResizeToSameSize
* @requires ormma
*/
function confirmResizeToMaxSize() {
	logit('ad is max sized');
	ormma.removeEventListener('resizeChange', confirmResizeToMaxSize);
	var props = ormma.getExpandProperties();
	ormma.setExpandProperties(props);
	ormma.addEventListener('stateChange', confirmExpand);
	ormma.expand({'top' : 0, 'left' : 0, 'bottom' : 100, 'right' : 100}, {'top' : 0, 'left' : 0, 'bottom' : 300, 'right' : 300});
}

/** 
* triggered by resizeChange event from resizeAd call, 
*  clean-up on resize, then attempts to resize to max size
*
* @see resizeAd
* @requires ormma
*/
function confirmResizeToSameSize() {
	logit('ad is resized');
	
	try {
		ormma.removeEventListener('resizeChange', confirmResizeToSameSize);
		var props = ormma.getMaxSize();
		ormma.setResizeProperties(props);
		ormma.addEventListener('resizeChange', confirmResizeToMaxSize);
		ormma.resize(250, 300);
	} catch (e) {
		logit("ORMMA not found for confirmResizeToSameSize");
		confirmExpand();
	}
}

/**
* triggered by user interaction, attempts to resize ad to same size
*
* @returns {Boolean} false - so click event can stop propogating
* @requires ormma
*/
function resizeAd() {
	try {
		var props = ormma.getResizeProperties();
		ormma.setResizeProperties(props);
		ormma.addEventListener('resizeChange', confirmResizeToSameSize);
		ormma.resize(props);
	} catch (e) {
		logit("ORMMA not found for resizeAd");
		confirmResizeToSameSize();
	}
	return (false);
}

/**
* triggered by response event from sendOrmmaRequest call, tries to embed the data into the ad
* 
* @param {Event} evt The event
* @requires ormma
*/
function receiveResponse(evt) {
	logit('response received');
	ormma.removeEventListener('response', receiveResponse);
	var data = evt.data;
	var ajaxResponse = data.split(',')[1];
	document.getElementById('ajax').innerHTML = ajaxResponse;
}


/**
* triggered by user interaction, tries to view new url in internal viewer
* 
* @param {String} href The URL to request
* @returns {Boolean} false response from ormma.request so click event can be cancelled
* @requires ormma
*/
function sendOrmmaRequest(href) {
	try {
		ormma.addEventListener('response', receiveResponse);
		ormma.request('http://ajax.com/', 'proxy');
		return ormma.request(href, 'internal');
	} catch (e) {
		logit ("ORMMA not found for sendOrmmaRequest");
		return (true);
	}
}

/**
* triggered by stateChange event from hideBanner call
*   does some clean-up
* 
* @requires ormma
*/
function confirmHide() {
	logit('ad is hidden');
	try {
		ormma.removeEventListener('stateChange', confirmHide);
	} catch (e) {
		logit("ORMMA not found for confirmHide");
	}
	var oEl = document.getElementById('banner');
	oEl.style.display = 'none';
	oEl = document.getElementById('closebanner');
	oEl.style.display = 'none';
}

/**
* triggered by user interaction, attempts to hide the ad
*
* @returns {Boolean} false - so event can be cancelled
* @requires ormma
*/
function hideBanner() {
	try {
		ormma.addEventListener('stateChange', confirmHide);
		ormma.hide();
	} catch (e) {
		logit("ormma not defined for hideBanner");
		confirmHide();
	}
	return(false);
}

/**
* triggered by stateChange event from collapse call,
*   does some clean up and then shows/hides the banner/panel
*
* @requires ormma
*/
function confirmCollapse() {
	logit('ad is no longer expanded');
	try {
		ormma.removeEventListener('stateChange', confirmCollapse);
	} catch (e) {
		logit("ORMMA not found for confirmCollapse");
	}
	
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
* @requires ormma
*/
function collapse() {
	try {
		ormma.addEventListener('stateChange', confirmCollapse);
		ormma.close();
	} catch (e) {
		logit("ORMMA not found for collapse");
		confirmCollapse();
	}
}

ormmaWaitId = setTimeout(confirmShow,2000);