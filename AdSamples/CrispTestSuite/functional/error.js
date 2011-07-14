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
 * @param {boolean} first whether it is the first message
 */
function showit(msg, divId, first) {
	var oDiv = document.getElementById(divId);
	if (first) {
		oDiv.innerHTML = msg;
	} else {
		oDiv.innerHTML = oDiv.innerHTML + '<br/><br/>' + msg;
	}
}

/**
 * helper constants
 */
var ORMMAReadyStatus = {
	NOT_FOUND: -1,
	FOUND: 1
};

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
		logit('ORMMA found');
		window.gotError = false;
		if (typeof ormma === 'undefined') {
			showit('ormma object not found - failed.', 'result', true);
		} else {
			ormma.addEventListener('error', function(msg, action) {
				gotError = true;
				setTimeout(function() {
					if (msg && msg !== '') {
						showit('Called ormma.expand({x:0}) and got an error, message: ' + msg + ', action: ' + action + ' - passed.', 'result', true);
					} else {
						showit('Called ormma.expand({x:0}) and got an error, but the message was empty: - failed.', 'result', true);
					}
				}, 100);
			});
			setTimeout(function() {
				if (!gotError) {
					showit('Called ormma.expand({x:0}), but did not receive an error event - failed.', 'result', true);
				}
			}, 500);
			ormma.expand({x:0});
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
		showit('Test failure.', 'result');
		showit('*ORMMAReady() not found.', 'result');
		logit('ORMMA not found');
	}
}

window.ormmaWaitId = window.setTimeout(ORMMANotFound, 5000);

