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

title: SDK 4.x Migration Guide
description: Migrating Pebble apps from SDK 3.x to SDK 4.x.
permalink: /guides/migration/migration-guide-4/
generate_toc: true
guide_group: migration
order: 4
---

This guide provides details of the changes to existing APIs in Pebble
SDK 4.x. To migrate an older app's code successfully from Pebble SDK 3.x to
Pebble SDK 4.x, consider the information outlined here and make the necessary
changes if the app uses a changed API.

The number of breaking changes in SDK 4.x for existing apps has been minimized
as much as possible. This means that:

* Apps built with SDK 3.x **will continue to run on firmware 4.x without any
  recompilation needed**.

* Apps built with SDK 4.x will generate a `.pbw` file that will run on firmware
  4.x.

## New APIs

* ``AppExitReason`` - API for the application to notify the system of the reason
it will exit.
* ``App Glance`` - API for the application to modify its glance.
* ``UnobstructedArea`` - Detect changes to the available screen real-estate
based on obstructions.

## Timeline Quick View

Although technically not a breaking change, the timeline quick view feature will
appear overlayed on a watchface which may impact the visual appearance and
functionality of a watchface. Developers should read the
{% guide_link user-interfaces/unobstructed-area "UnobstructedArea guide%} to
learn how to adapt their watchface to handle obstructions.

## appinfo.json

Since the [introduction of Pebble Packages in June 2016](/blog/2016/06/07/pebble-packages/), the `appinfo.json`
file has been deprecated and replaced with `package.json`. Your project can
automatically be converted when you run `pebble convert-project` inside your
project folder.

You can read more about the `package.json` file in the
{% guide_link tools-and-resources/app-metadata "App Metadata" %} guide.

## Launcher Icon

The new launcher in 4.0 allows developers to provide a custom icon for
their watchapps and watchfaces.

<div class="pebble-dual-image">
  <div class="panel">
  {% markdown %}
  ![Launcher Icon](/images/blog/2016-08-19-pikachu-icon.png)
  {% endmarkdown %}
  </div>
  <div class="panel">
  {% markdown %}
  ![Launcher >{pebble-screenshot,pebble-screenshot--time-red}](/images/blog/2016-08-19-pikachu-launcher.png)
  {% endmarkdown %}
  </div>
</div>

> If your `png` file is color, we will use the luminance of the image to add
> some subtle gray when rendering it in the launcher, rather than just black
> and white. Transparency will be preserved.

You should add a 25x25 `png` to the `resources.media` section of the
`package.json` file, and set `"menuIcon": true`.
Please note that icons that are larger will be ignored and 
your app will have the default icon instead.

```js
"resources": {
  "media": [
    {
      "menuIcon": true,
      "type": "png",
      "name": "IMAGE_MENU_ICON",
      "file": "images/icon.png"
    }
  ]
}
```
