/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

/**
 * helper function to output debugging data to the console
 *
 * @param {String} msg text to output
 */
function logit(msg) {
	if (typeof (console) !== 'undefined') {
		console.log((new Date()).getTime() + '-' + msg);
	}
}

/**
 * helper function to output test data to reporting window
 *
 * @param {String} msg text to output
 * @param {String} CSS div id of reporting window
 */
function showit(msg, divId) {
	if (!divId) {
		divId = 'result';
	}
	var oDiv = document.getElementById(divId);
	if (oDiv.innerHTML === '') {
		oDiv.innerHTML = msg;
	} else {
		oDiv.innerHTML = oDiv.innerHTML + '<br/>' + msg;
	}
}

var ORMMAReadyStatus = {
	NOT_FOUND: -1,
	FOUND: 1
};

window.ormmaStatus = undefined;

/**
 * convert orientation number to readable text
 *
 * @param {number} the integer or float orientation value
 */
function getOrientationText(orientation) {
	var str;
	switch (orientation) {
	case 0:
		str = 'portrait (' + orientation + ')';
		break;
	case -90:
	case 270:
		str = 'landscape left (' + orientation + ')';
		break;
	case 180:
	case -180:
		str = 'portrait upside down (' + orientation + ')';
		break;
	case 90:
	case -270:
		str = 'landscape right (' + orientation + ')';
		break;
	default:
		str = 'unknown (' + orientation + ')';
	};
	return str;
}

/**
 * ORMMAReady called by the SDK
 * Sets global 'ormmaAvail' to true
 *
 * @requires ormma
 *
 */
function ORMMAReady(evt) {
	window.ormmaAvail = window.ormmaAvail || ORMMAReadyStatus.FOUND;
	if (window.ormmaAvail !== ORMMAReadyStatus.NOT_FOUND) {
		//clear any timers that have been waiting for ORMMA
		window.clearTimeout(window.ormmaWaitId);

		if (typeof ormma !== 'undefined') {
			logit('ORMMA found');
			if (typeof ormma['getOrientation'] === 'function') {
				showit('getOrientation method found - passed.', 'result', true);
				showit(['Visual confirmation needed...<ul>',
					'<li>Is the current orientation ',
					getOrientationText(ormma.getOrientation()),
					'?</li>',
					'<li>Seeing orientation change message after changing the orientation of the device?</li>',
					'<li>Is the updated orientation value correct?</li>',
					'</ul>'].join(''), 'result');
				ormma.addEventListener('orientationChange', function(orientation) {
					showit('');
					showit('Received orientationChange event...');
					showit('Is the current orientation ' + getOrientationText(orientation) + '?');
				});
				ormma.addEventListener('screenChange', function(width, height) {
					showit('');
					showit('Received screenChange event...');
					showit('width: ' + width + ' height: ' + height);
				});
			} else {
				showit('Test failed.<br/><br/>getOrientation method is undefined.', 'result', true);
			}
		} else {
			showit('Test failed.<br/><br/>ormma object is undefined.', 'result', true);
		}
	}
}

/**
 * stub function to highlight when ORMMA is not found
 */
function ORMMANotFound() {
	window.ormmaAvail = window.ormmaAvail || ORMMAReadyStatus.NOT_FOUND;
	if (window.ormmaAvail !== ORMMAReadyStatus.FOUND) {
		window.ormmaAvail = false;
		showit('Test failed.<br/><br/>*ORMMAReady() not found.', 'result', true);
		logit('ORMMA not found');
	}
}

window.ormmaWaitId = window.setTimeout(ORMMANotFound, 2000);

