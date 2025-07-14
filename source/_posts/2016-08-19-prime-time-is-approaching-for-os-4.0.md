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

title: Prime Time is Approaching for OS 4.0
author: jonb
tags:
- Freshly Baked
---

Pebble developers of the world unite! Pebble OS 4.0 is just around the corner
and it's now time to put those finishing touches on your projects, and prepare
them for publishing!


Pebble Time owners will be receiving OS 4.0 before Kickstarter backers receive
their Pebble 2 watches, so we're recommending that developers publish their
4.0 watchapps and watchfaces into the appstore **from August 31st onwards**.

We'll be promoting new and updated apps which utilize the new SDK 4.0 APIs and
features by creating a brand new category in the appstore called
'Optimized for 4.0'. This is your time to shine!

If you haven't even begun to prepare for 4.0, there are some really quick wins
you can use to your advantage.

## Menu Icon in the Launcher

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

## Timeline Quick View

This new feature really brings your timeline into the present, with your
next appointment appearing as a modal notification over the active watchface.

We introduced the ``UnobstructedArea`` API in 4.0 to allow developers to detect
if the screen is being obstructed by a system modal. Below you can see two
examples of the Simplicity watchface. The Pebble on the left is not using the
``UnobstructedArea`` API, and the Pebble on the right is.

<div class="pebble-dual-image">
  <div class="panel">
  {% markdown %}
  ![Simplicity >{pebble-screenshot,pebble-screenshot--time-white}](/images/blog/2016-08-19-simplicity-std.png)
  {% endmarkdown %}
  <p class="blog__image-text">Watchface not updated</p>
  </div>
  <div class="panel">
  {% markdown %}
  ![Simplicity >{pebble-screenshot,pebble-screenshot--time-white}](/images/blog/2016-08-19-simplicity-qv.png)
  {% endmarkdown %}
  <p class="blog__image-text">Respects new 4.0 unobstructed area</p>
  </div>
</div>

You can detect changes to the available screen real-estate and then move, scale,
or hide their layers to achieve an optimal layout while the screen is partially
obscured. This provides a fantastic experience to your users.

There's {% guide_link user-interfaces/unobstructed-area "a dedicated guide" %}
which goes into more detail about the ``UnobstructedArea`` API, it contains
examples and links to sample implementations.

## AppGlances

While your static app icon and app title from the `package.json` are being used as the 
default to present your app to the user,
_AppGlances_ allow developers to control this content at runtime and
to provide meaningful feedback to users directly from the new launcher. 
The API exposes the ability to dynamically change
the `icon` and `subtitle_template_string` text of your application in the
launcher.

<img src="/assets/images/blog/2016-05-24-kickstarter-3/launcher.gif"
alt="Updated Launcher" class="pebble-screenshot pebble-screenshot--time-black">
<p class="blog__image-text">Preview version of 4.0 launcher</p>

Utilizing the ``App Glance`` API doesn't need to be difficult. We've provided
guides, examples and sample applications for using the
{% guide_link user-interfaces/appglance-c "AppGlance C API" %} and the
{% guide_link user-interfaces/appglance-pebblekit-js "AppGlance PebbleKit JS API" %}.

## The Diorite Platform

The Diorite platform was created for the new Pebble 2 devices. Its display is
rectangular, 144x168 pixels, with 2 colors (black and white). It has a
microphone and heart rate monitor, but it doesn't have a compass. If your app
works with Aplite it will already work with Diorite, but there are some important considerations to note:

* If you chose to limit your app to some platforms, you need to add `"diorite"` to your `targetPlatforms` in the `package.json`.
* Check for the appropriate usage of
{% guide_link best-practices/building-for-every-pebble#available-defines-and-macros "compiler directives" %}.

In general, it's better to use capability and feature detection, rather than platform
detection. For example, when dealing with resources, use the suffix `~bw` instead of `~aplite` so they are picked on all black and white platforms.

## What's Next

We're really excited for the release of Pebble OS 4.0 and the new features it
brings. It's now time for you to take advantage of the new APIs and
enhance your existing projects, or even create entirely new ones!

Why not build something like the
{% guide_link design-and-interaction/one-click-actions "One Click Action" %}
application, which utilizes the new ``App Glance`` and ``AppExitReason`` APIs.

Please remember that we will promote watchfaces and watchapps
that make use of these new 4.0 APIs if you
submit them to the appstore **from August 31st onwards**.

Let us know on [Twitter](https://twitter.com/pebbledev) if you build something
cool using the new APIs! We'd love to hear about your experiences with the SDK.

Happy Hacking!

Team Pebble


