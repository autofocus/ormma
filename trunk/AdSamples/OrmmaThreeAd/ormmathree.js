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
	if (typeof(console) !== 'undefined') {
		console.log((new Date()).getTime() + '-' + msg);
	}
}

/**
* helper function to generate output for all events
*
* @param {Event} evt event to get information on
*/
function reportEvent(evt) {
	var msg = 'Event fired: ' + evt.type;
	if (evt.data) {
		msg = msg + ':' + evt.data;
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
	Ormma.addEventListener('assetReady', reportEvent);
	Ormma.addEventListener('assetRemoved', reportEvent);
	Ormma.addEventListener('assetRetired', reportEvent);

	document.getElementById('cacheremaining').innerHTML = Ormma.cacheRemaining();
}

/**
* global variables for generic handling of assets
*/
var assetCount = 0,
	filenamebase = 'img',
	filepath = 'http://stage.media.crispadvertising.com/ormma/testing/';

/**
* clear out the reporting on the ad unit
*/
function clearfields() {
	document.getElementById('addassetresponse').innerHTML = '';
	document.getElementById('addassetsresponse').innerHTML = '';
	document.getElementById('removeassetresponse').innerHTML = '';
	document.getElementById('removeallresponse').innerHTML = '';
}

/**
* listener for adding one asset, updates onscreen reporting
* @param {Event} evt ORMMA event
*/
function addAssetListener(evt) {
	Ormma.removeEventListener('assetReady', addAssetListener);
	logit('asset added');
	assetCount = assetCount + 1;
	document.getElementById('addassetresponse').innerHTML = evt.data;
	document.getElementById('cacheremaining').innerHTML = Ormma.cacheRemaining();
	document.getElementById('backgroundimage').src = filepath + filenamebase + (assetCount) + '.gif';
}

/**
* response to user clicking on addAsset link, adds an Ormma listener
* and attempts to add the asset
*/
function addAssetOnclick() {
	var filename;
		
	clearfields();
	if (assetCount < 9) {
		filename = filenamebase + (assetCount + 1) + '.gif';	
		Ormma.addEventListener('assetReady', addAssetListener);
		logit('attempt to load ' + filename);
		Ormma.addAsset(filename, filepath + filename);
	} else {
		logit('no more files to load ');
	}
}

/**
* listener for adding many assets, updates onscreen reporting
* @param {Event} evt ORMMA event
*/
function addAssetsListener(evt) {
	Ormma.removeEventListener('assetReady', addAssetsListener);
	logit('multiple asset added');
	assetCount = 9;
	document.getElementById('addassetsresponse').innerHTML = evt.data;
	document.getElementById('cacheremaining').innerHTML = Ormma.cacheRemaining();
	document.getElementById('backgroundimage').src = filepath + filenamebase + (assetCount) + '.gif';
}

/**
* response to user clicking on addAssets link, adds an Ormma listener
* and attempts to add all the ad assets
*/
function addAssetsOnclick() {
	clearfields();
	Ormma.addEventListener('assetReady', addAssetsListener);
	logit('attempt to many assets');
	Ormma.addAssets({ 'img1.gif' : 'http://stage.media.crispadvertising.com/ormma/testing/img1.gif' });
}

/**
* listener for removing one asset, updates onscreen reporting
* @param {Event} evt ORMMA event
*/
function removeAssetListener(evt) {
	Ormma.removeEventListener('assetRemoved', removeAssetListener);
	logit('asset removed');
	assetCount = assetCount - 1;
	document.getElementById('removeassetresponse').innerHTML = evt.data;
	document.getElementById('cacheremaining').innerHTML = Ormma.cacheRemaining();
	document.getElementById('backgroundimage').src = filepath + filenamebase + (assetCount) + '.gif';
}

/**
* response to user clicking on removeAsset link, adds an Ormma listener
* and attempts to remove the last asset
*/
function removeAssetOnclick() {
	var filename;
	
	clearfields();
	if (assetCount > 0) {
		filename = filenamebase + assetCount + '.gif';
		Ormma.addEventListener('assetRemoved', removeAssetListener);
		logit('attempt to remove asset ' + filename);
		Ormma.removeAsset(filename);
	} else {
		logit('no more files to remove');
	}
}

/**
* listener for removing all assets, updates onscreen reporting
* @param {Event} evt ORMMA event
*/
function removeAllListener(evt) {
	Ormma.removeEventListener('assetRemoved', removeAllListener);
	logit('all assets removed');
	assetCount = 0;
	document.getElementById('removeallresponse').innerHTML = evt.data;
	document.getElementById('cacheremaining').innerHTML = Ormma.cacheRemaining();
	document.getElementById('backgroundimage').src = filepath + filenamebase + (assetCount) + '.gif';
}

/**
* response to user clicking on removeAll link, adds an Ormma listener
* and attempts to remove all assets
*/
function removeAllOnclick() {
	clearfields();
	Ormma.addEventListener('assetRemoved', removeAllListener);
	logit('attempt to remove all assets');
	Ormma.removeAllAssets();
}
