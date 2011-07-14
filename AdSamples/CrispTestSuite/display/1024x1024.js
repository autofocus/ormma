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

var ORMMAReadyStatus = {
	NOT_FOUND: -1,
	FOUND: 1
};

/**
 * called by open, calls the ormma.open method
 *
 * @see open 
 * @requires ormma
 * @returns {Boolean} false - so click event can stop propogating
 */
function ormmaOpen(url) {
	if (!window.ormmaAvail) {
		return true;
	}
	
	ormma.open(url);
	return false;
}

/**
 * ORMMAReady called by the SDK
 * Sets global 'ormmaAvail' to true
 *
 * @requires ormma
 *
 */
function ORMMAReady(evt) {
	var msg;

	window.ormmaAvail = window.ormmaAvail || ORMMAReadyStatus.FOUND;

	if (window.ormmaAvail !== ORMMAReadyStatus.NOT_FOUND) {
		//clear any timers that have been waiting for ORMMA
		window.clearTimeout(window.ormmaWaitId);

		logit('ORMMA found');

		if (typeof ormma === 'undefined') {
			showit('ormma object not found - failed.', 'result', true);
		} else if (typeof(ormma['open']) !== 'function') {
			showit('open() method not found - failed.', 'result', true);
		} else {
			showit('open method found - passed.', 'result', true);
			showit('Visual confirmation needed...', 'result');
			showit(['<ul><li>Browser opened in-app?</li>',
				'<li>ormma.org site displayed?</li>',
				'<li>Browser navigation available?</li>',
				'<li>Browser close returned to ad?</li></ul>'].join(''), 'result');
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
		logit('ORMMA not found');
	}
}

window.ormmaWaitId = window.setTimeout(ORMMANotFound, 2000);

