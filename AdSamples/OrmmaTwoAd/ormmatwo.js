/*global window, Ormma */

/**
 * @fileOverview This sample file demonstrates a functional style usage of the ORMMA JavaScript SDK
 *  All Level One methods are exercised.
 *
 * @author <a href="mailto:nathan.carver@crispwireless.com">Nathan Carver</a>
 * @version 0.0.1
 * @requires Ormma
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
* @requires Ormma
*/
function confirmShow() {
	logit('ad is showing');
	Ormma.removeEventListener('stateChange', confirmShow);
	document.getElementById('interstitial').style.display = 'block';
}

/**
* init started at the end of loading this file, shows the ad
*
* @param {Event} evt the ready event
* @requires Ormma
*/
function initAd(evt) {
	logit('initAd');
	var myState = Ormma.getState();
	if (myState !== 'hidden') {
		Ormma.addEventListener('stateChange', confirmShow);
		Ormma.show();
	}
	Ormma.addEventListener('error', reportEvent);
	Ormma.addEventListener('ready', reportEvent);
	Ormma.addEventListener('screenSizeChange', reportEvent);
	
	if (Ormma.supports('network')) document.getElementById('networksupport').innerHTML = 'Y';
	if (Ormma.supports('orientation')) document.getElementById('orientationsupport').innerHTML = 'Y';
	if (Ormma.supports('screensize')) document.getElementById('screensizesupport').innerHTML = 'Y';
	if (Ormma.supports('heading')) document.getElementById('headingsupport').innerHTML = 'Y';
	if (Ormma.supports('location')) document.getElementById('locationsupport').innerHTML = 'Y';
	if (Ormma.supports('shake')) document.getElementById('shakesupport').innerHTML = 'Y';
	if (Ormma.supports('tilt')) document.getElementById('tiltsupport').innerHTML = 'Y';
	
	Ormma.setShakeProperties('shake softly');
	document.getElementById('network').innerHTML = Ormma.getNetwork();
	document.getElementById('orientation').innerHTML = Ormma.getOrientation();
	document.getElementById('screensize').innerHTML = Ormma.getScreenSize();
	document.getElementById('heading').innerHTML = Ormma.getHeading();
	document.getElementById('location').innerHTML = Ormma.getLocation();
	document.getElementById('shakeprops').innerHTML = Ormma.getShakeProperties();	
}

function onOrmmaScreenSizeChange() {
	document.getElementById('screensize').innerHTML = Ormma.getScreenSize();
}

function onOrmmaHeadingChange() {
	document.getElementById('heading').innerHTML = Ormma.getHeading();
}

function onOrmmaLocationChange() {
	document.getElementById('location').innerHTML = Ormma.getLocation();
}

function onOrmmaNetworkChange() {
	document.getElementById('network').innerHTML = Ormma.getNetwork();
}

function onOrmmaOrientationChange() {
	document.getElementById('orientation').innerHTML = Ormma.getOrientation();
}

function onOrmmaShakeChange() {
	document.getElementById('shake').innerHTML = 'shaken';	
}

function onOrmmaTiltChange() {
	document.getElementById('tilt').innerHTML = 'tilted';	
}

