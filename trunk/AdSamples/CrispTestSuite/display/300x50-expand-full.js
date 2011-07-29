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

/**
 * called by expand, calls the ormma.expand method
 * 
 * @see expand
 * @requires ormma
 * @returns {Boolean} false - so click event can stop propogating
 */
function ormmaExpand() {
	if (!window.ormmaAvail) {
		return (false);
	}
	ormma.expand({'x' : 0, 'y' : 0, 'width' : 480, 'height' : 480}, null);
	return (false);
}

/**
 * called by collapse, calls the ormma.close method
 *
 * @see collapse
 * @requires ormma
 * @returns {Boolean} false - so click event can stop propogating
 */
function ormmaClose() {
	if (!window.ormmaAvail) {
		return false;
	}

	ormma.close();
	return false;
}

/**
 * triggered by user interaction, expands banner ad to panel
 * attempts to call ormma.expand
 *
 * @returns {Boolean} false - so click event can stop propogating
 */
function expand() {
	var oEl = document.getElementById('panel');
	oEl.style.display = 'block';
	oEl = document.getElementById('hotspot');
	oEl.style.display = 'block';
	oEl = document.getElementById('close');
	oEl.style.display = 'block';
	oEl = document.getElementById('banner');
	oEl.style.display = 'none';
	
	return ormmaExpand();
}

/**
 * triggered by user interaction to close panel ad back to banner
 * attempts to call ormma.close
 *
 * @returns {Boolean} false - so click event can stop propogating
 */
function collapse() {
	var oEl = document.getElementById('panel');
	oEl.style.display = 'none';
	oEl = document.getElementById('close');
	oEl.style.display = 'none';
	oEl = document.getElementById('banner');
	oEl.style.display = 'block';

	return ormmaClose();
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
		window.ormmaAvail = true;
		window.clearTimeout(window.ormmaWaitId);
		logit('ORMMA found');

		var orient = ormma.getOrientation();
		var panel = document.getElementById('panel');

		if (parseInt(orient, 10) % 180 === 0 || orient === -1) {
			panel.style.left = '-48px';
			panel.style.top = '42px';
		} else {
			panel.style.left = '32px';
			panel.style.top = '-37px';
		}
		ormma.addEventListener('orientationChange', function(orient) {
			if (!orient) {
				orient = ormma.getOrientation()
			}			
			if (parseInt(orient, 10) % 180 === 0 || orient === -1) {
				panel.style.left = '-48px';
				panel.style.top = '42px';
			} else {
				panel.style.left = '32px';
				panel.style.top = '-37px';
			}
		});
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

