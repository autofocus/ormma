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

window.listenerEnabled = true;
window.gotEvent = false;
window.stopLoading = false;

/**
 * called by open, calls the ormma.open method
 *
 * @see open 
 * @requires ormma
 * @returns {Boolean} false - so click event can stop propogating
 */
function ormmaOpen(url) {
	if (!window.ormmaAvail) {
		return (true);
	}
	
	ormma.open(url);
	return (false);
}

function getExpectedState(action) {
	if (action) {
		var actionStatePairs = {
			expand: 'expanded',
			resize: 'resized',
			close: 'default',
			hide: 'hidden'
		};
		if (actionStatePairs[action]) {
			return actionStatePairs[action];
		} else {
			return '';
		}
	} else {
		logit('Required parameter action is missing.');
		return '';
	}
}

function simulateActions(actions, callback) {
	if (window.stopLoading || (typeof ormma.getViewable === 'function' && (!(ormma.getViewable() === true || ormma.getViewable() === 'true')))) {
		return;
	}
	if (actions.length > 0) {
		switch (actions[0]) {
		case 'addEventListener':
			ormma.addEventListener('stateChange', stateChangeHandler);
			window.listenerEnabled = true;
			showit('Added event listener', 'result');
			break;
		case 'removeEventListener':
			ormma.removeEventListener('stateChange', stateChangeHandler);
			window.listenerEnabled = false;
			showit('Removed event listener', 'result');
			break;
		case 'expand':
			showit('calling expand()...', 'result');
			ormma.expand({x:0, y:20, width:300, height:250});
			break;
		case 'resize':
			showit('calling resize()...', 'result');
			ormma.resize(ormma.getSize().width - 1, ormma.getSize().height + 1);
			break;
		case 'close':
			showit('calling close()...', 'result');
			ormma.close();
			break;
		case 'hidden':
			break;
		}
		setTimeout(function() {
			verifyState(getExpectedState(actions[0]), function() {
				actions.splice(0, 1);
				simulateActions(actions, callback);
			});
		}, 2000);
		return;
	}
	if (typeof callback === 'function') {
		callback.call();
	}
}

function stateChangeHandler(state) {
	gotEvent = true;
	showit('Received stateChange event. State is now ' + state, 'result');
}

function verifyState(expected, callback, sync) {
	var verify = function () {
		if (expected !== '') {
			if (expected === ormma.getState()) {
				showit('Expected state: ' + expected + '; Reported state: ' + ormma.getState() + ' - passed.', 'result');
			} else {
				showit('Expected state: ' + expected + '; Reported state: ' + ormma.getState() + ' - failed.', 'result');
			}
		} else {
			if (!window.listenerEnabled) {
				if (!gotEvent) {
					showit('No event received after listener removed - passed.', 'result');
				} else {
					showit('Still received event after listener was removed - failed.', 'result');
				}
			}
		}
		if (typeof callback === 'function') {
			callback.call();
		}
	};
	if (sync) {
		verify();
	} else {
		setTimeout(function() {
			verify();
		}, 500);
	}
}

function loadTest() {
	if (typeof ormma.getViewable === 'function' || ormma.getViewable() === true || ormma.getViewable() === 'true') { /*start the tests only when the ad is in view*/
		if (ormma.getState() === 'default') {
			showit('Expected initial state: default; Reported initial state: default - passed.', 'result');
		} else {
			showit('Expected initial state: default; Reported initial state: ' + ormma.getState() + ' - failed.', 'result');
		}

		var expectedActionsAndStates = ['addEventListener', 'expand', 'close', 'resize', 'expand', 'close', 'removeEventListener', 'expand', 'close'];
		simulateActions(expectedActionsAndStates, function() {
			var hideBtn = document.getElementById('close');
			hideBtn.style.display = 'block';
			showit('ACTION NEEDED: click close button to hide the ad', 'result');
			hideBtn.onclick = function(evt) {
				ormma.hide();
				verifyState('hidden', function() {
					ormma.show();
				});
			};
		});
		var id = setInterval(function() {
			if (!(ormma.getViewable() === true || ormma.getViewable() === 'true')) {
				window.stopLoading = true;
				setTimeout(function() {
					ormma.close();
				}, 100);
			} else {
				if (window.stopLoading) {
					window.stopLoading = false;
					loadTest();
				}
			}
		}, 1000);
	} else {
		setTimeout(function() {
			loadTest();
		}, 1000);
	}
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
			showit('ormma object not found - failed.', 'result');
			return;
		}

		//check that all expected Level1 methods are available		
		var ormmaMethods = ['getState', 'addEventListener', 'removeEventListener', 'resize', 'expand', 'close', 'hide', 'show', 'getViewable'];
		var hasOrmmaMethods;
		var hasError = false;

		for (var i = 0; i < ormmaMethods.length; i++) {
			ormmaMethod = ormmaMethods[i];
			hasOrmmaMethods = (typeof(ormma[ormmaMethod]) === 'function');
			if (!hasOrmmaMethods) {
				hasError = true;
				showit(ormmaMethod + ' method not found - failed.', 'result');
 				logit ('method ' + ormmaMethod + ' not found');
			} else {
				showit(ormmaMethod + '() method found - passed.');
			}
		}

		loadTest();
	}
}

/**
 * stub function to highlight when ORMMA is not found
 */
function ORMMANotFound() {
	window.ormmaAvail = window.ormmaAvail || ORMMAReadyStatus.NOT_FOUND;
	if (window.ormmaAvail !== ORMMAReadyStatus.FOUND) {
		window.ormmaAvail = false;
		showit('Test failed.<br/><br/>*ORMMAReady() not found.', 'result');
		logit('ORMMA not found');
	}
}

window.ormmaWaitId = window.setTimeout(ORMMANotFound, 2000);

