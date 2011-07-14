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

window.ormmaStatus = undefined;

/**
 * ORMMAReady called by the SDK
 * Sets global 'ormmaAvail' to true
 *
 * @requires ormma
 *
 */
function ORMMAReady(evt) {
	var initialText;

	window.ormmaAvail = window.ormmaAvail || ORMMAReadyStatus.FOUND;
	if (window.ormmaAvail !== ORMMAReadyStatus.NOT_FOUND) {
		//clear any timers that have been waiting for ORMMA
		window.clearTimeout(window.ormmaWaitId);

		logit('ORMMA found');
		if (typeof ormma !== 'undefined') {
			initialText = ['Visual confirmation needed...<ul>',
					'<li>Did "passed" message show after shaking device?</li></ul>'].join('');
			document.getElementById('result').innerHTML = initialText;
			ormma.addEventListener('shake', function() {
				showit('shake event received - passed.', 'result', true);
				document.getElementById('button').style.display = 'block';
			});
			document.getElementById('select').onchange = function(evt) {
				document.getElementById('text').value = '';
			}
			document.getElementById('text').onchange = function(evt) {
				var props = {};
				var selValue = document.getElementById('select').value;
				if (selValue !== 'none') {
					props[selValue] = document.getElementById('text').value;
				}
				ormma.setShakeProperties(props);
			}
			document.getElementById('button').onclick = function(evt) {
				document.getElementById('button').style.display = 'none';
				showit(initialText, 'result', true);
			};
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

