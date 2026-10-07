---
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
title: Importing Apps from Rebble
description: |
  How to bring apps published in the Rebble appstore into the Developer
  Dashboard and prove ownership of them.
guide_group: appstore-publishing
order: 2
---

Apps that were published through the Rebble Dev Portal can be imported into
the Pebble appstore from the [Developer Dashboard]({{ site.links.devportal }}).
Importing copies the listing, releases and screenshots and keeps the app's
original ID, so existing links keep working. After an import the app is
managed from the Developer Dashboard like any other.


## Importing

* Open the Developer Dashboard and click *Import*.

* Choose *Import by Developer ID* and enter your Pebble developer ID. The ID
  is in the URL of your developer page on the Pebble appstore and on the
  Rebble Dev Portal profile page. Click *Load All My Apps*.

* To import single apps instead, choose *Import by App IDs* and paste one
  app ID per line. The app ID is the last part of an appstore URL such as
  `apps.repebble.com/app/583f347dca3094d3b00006d3`.

* Click *Import* next to an app, or *Import All*.

Apps are imported as Listed. Importing an app a second time refreshes its
listing from Rebble and keeps the visibility that was set in the Developer
Dashboard.


## Verifying Ownership

The import checks the developer ID that Rebble has for each app against the
ID of the signed-in account. Since the Pebble developer account is new, they
never match on a first import, and the dashboard opens the
*Verify App Ownership* page. Until verification is approved the imported apps
keep their original developer ID. They are listed on the verification page,
not in the account's app list, and cannot be edited.

* Check the list of apps submitted for verification.

* Tick *I confirm that I am the original developer of these apps* and click
  *Submit for Verification*.

* An email arrives asking for proof. Reply with a screenshot of the apps and
  their IDs in the Rebble Dev Portal. Links to the source repositories or the
  original appstore submission emails help if the screenshot is not conclusive.

Verification is done by a person and takes two to three business days. Once it
is approved, the apps move to your developer account, and the account's
developer ID becomes the original one so that the developer name shown in the
appstore stays the same.


## Keeping Apps in Sync

Apps that are still updated through the Rebble Dev Portal can be kept in sync
instead of being moved. Open *Sync* in the dashboard and turn it on per app.
Synced apps are re-imported from Rebble once a day. Rebble is the source of
truth for them, and the sync is skipped when the Pebble appstore already has a
newer release than Rebble.
