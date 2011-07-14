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
			var showResult = function() {
				showit('Listening to networkChange event...');
				showit(['Visual confirmation needed...<ul>',
					'<li>Is the current network status ',
					ormma.getNetwork(),
					'?</li>',
					'</ul>'].join(''), 'result', true);
			};

			if (typeof ormma['getNetwork'] === 'function') {
				showResult();
				ormma.addEventListener('networkChange', function(online, connection) {
					showit('');
					showit('Received networkChange event...');
					showit('online is : ' + online);
					showit('connection is : ' + connection);
				});
				document.getElementById('button').onclick = function() {
					document.getElementById('result').innerHTML = '';
					setTimeout(function() {
						showResult();
					}, 300);
				};
			} else {
				showit('Test failed.<br/><br/>getNetwork method is undefined.', result, true);
			}
		} else {
			showit('Test failed.<br/><br/>ormma object is undefined - failed.', result, true);
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
		showit('Test failed.<br/><br/>*ORMMAReady() not found.', result, true);
		logit('ORMMA not found');
	}
}

window.ormmaWaitId = window.setTimeout(ORMMANotFound, 2000);

