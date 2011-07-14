/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

README
---
Date: 20110713
Contact: Nathan Carver
nathan.carver@crispmedia.com

---
Contents: Functional Tests
* All functional tests are 300x250 medium rectangle ads that can be displayed on handset and tablet devices.
* Some sources on Crisp servers are referenced absolutely in the HTML for script and css styles.
* All functional tests rely on the ORMMA ORMMAReady method. New tests using an alternate "ready" event are still being developed.
* Reporting is in a scrollable DIV. Use a two-finger scroll on device to see all reporting.

1. ORMMAReady.html
* independent test for ORMMAReady

2. error.html
* makes an illegal call to container to purposefully throw an error

3. expand-close.html
* calls expand and close methods for testing although the ad size stays the same

4. getState-stateChange.html
* attempts to invoke all ORMMA states, so also tests resize

5. getViewable-viewableChange.html
* should have an "offscreen" loading of the ad for best test results

6. open.html
* tests that click-throughs open in a contained web browser

7. show-hide.html
* tests the ad's ability to show and hide itself

8. supports.html
* attempts to call supports for all ORMMA support capabilities

---
Contents: Display Tests
* Additional display tests are being developed
* Screen images of expected results to be sent by separate correspondence

1. 300x50.html
* simple banner for handsets

2. 416x416.html
* full page interstitial - oversized banner with safe area for handsets

3. 300x50-expand.html
* banner expands to 300x250 for handsets

3. 728x90.html
* simple leaderboard for tablets

4. 1024x1024.html
* full page interstial - oversized banner with safe area for tablets

