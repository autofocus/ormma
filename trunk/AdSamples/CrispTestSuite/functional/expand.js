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

	var props = {},
		pos = ormma.getDefaultPosition();

	document.getElementById('propName').disabled = 'disabled';
	document.getElementById('propValue').disabled = 'disabled';

	var propName = document.getElementById('propName').value;
	var propValue = document.getElementById('propValue').value;

	if (propName && propValue) {
		props[propName] = propValue;
	}
/*
	if (!props['useBackground']) {
		props['useBackground'] = true;
	}
	if (!props['backgroundColor']) {
		props['backgroundColor'] = '#000000';
	}
	if (!props['backgroundOpacity']) {
		props['backgroundOpacity'] = 1;
	}
	if (!props['lockOrientation']) {
		props['lockOrientation'] = true;
	}
*/
	ormma.setExpandProperties(props);
	ormma.addEventListener('stateChange', function () {
		logit('ad is expanded');
		ormma.removeEventListener('stateChange');
	});
	ormma.expand({'x' : pos.x, 'y' : pos.y, 'width' : 300, 'height' : 300}, null);
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

	ormma.addEventListener('stateChange', function () {
		logit('ad is no longer expanded');
		ormma.removeEventListener('stateChange');
	});
	document.getElementById('propName').disabled = '';
	document.getElementById('propValue').disabled = '';
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
		//clear any timers that have been waiting for ORMMA
		window.clearTimeout(window.ormmaWaitId);

		logit('ORMMA found');

		if (typeof ormma === 'undefined') {
			showit('ormma object not found - failed.', 'result', true);
			return;
		}

		//check that all expected Level1 methods are available		
		var ormmaMethods = ['expand', 'close', 'getExpandProperties', 'setExpandProperties'];
		var hasOrmmaMethods;
		var hasError = false;

		for (var i = 0; i < ormmaMethods.length; i++) {
			ormmaMethod = ormmaMethods[i];
			hasOrmmaMethods = (typeof(ormma[ormmaMethod]) === 'function');
			if (!hasOrmmaMethods) {
				showit(ormmaMethod + ' method not found - failed.', 'result', true);
 				logit ('method ' + ormmaMethod + ' not found');
			}
		}
        document.getElementById('propName').onchange = function(evt) {
			document.getElementById('propValue').value = '';
		};

		if (!hasError) {
			var msg = ['expand/close methods found - passed.<br/>',
				       'Visual confirmation needed...<ul>',
					   '<li>Panel expanded in-app?</li>',
					   '<li>Panel close returned to banner?</li></ul>'].join('');
			showit(msg, 'result', true)
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


