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

		showit('*ORMMAReady() found.');
		logit('ORMMA found');

		if (typeof ormma === 'undefined') {
			showit('ormma object not found - failed.', 'result');
			return;
		}

		var ormmaMethods = ['getSize', 'resize'];
		var hasOrmmaMethods;
		var hasError = false;

		for (var i = 0; i < ormmaMethods.length; i++) {
			ormmaMethod = ormmaMethods[i];
			hasOrmmaMethods = (typeof(ormma[ormmaMethod]) === 'function');
			if (!hasOrmmaMethods) {
				hasError = true;
				showit(ormmaMethod + '() method not found - failed.');
 				logit ('method ' + ormmaMethod + ' not found');
			} else {
				showit(ormmaMethod + '() method found - passed.');
			}
		}
		showit('Listening to sizeChange event...');
		ormma.addEventListener('sizeChange', function(width, height) {
			showit('Received sizeChange event...');
			showit('ormma.getSize().width is : ' + ormma.getSize().width);
			showit('ormma.getSize().height is : ' + ormma.getSize().height);
		});
		setTimeout(function() {
			showit('calling ormma.getSize()...');
			showit('ormma.getSize().width is : ' + ormma.getSize().width);
			showit('ormma.getSize().height is : ' + ormma.getSize().height);
		}, 100);

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

