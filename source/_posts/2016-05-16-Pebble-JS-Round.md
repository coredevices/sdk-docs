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

title: Pebble.js Support for Chalk!
author: meiguro
tags:
- Freshly Baked
---

After many morning coding sessions on the weekends,
[Pebble.js](/docs/pebblejs/) has been updated to
support the Chalk platform (Pebble Time Round). This update is available in
[CloudPebble]({{site.links.cloudpebble}}), and ready for you to work with right in
your browser with no setup!

Supporting Chalk required a ton of bug crushing to become compatible with the
new 3.0 style status bar, changes to accommodate reduced memory on the 3.x
Aplite platform, adding new features such as text flow and paging, and making it
easier to target multiple platforms by adding a feature detection API.



![Pebble.js Screenshots](/images/blog/2016-05-13-pebble-js-round/pebblejs.png)
<p class="blog__image-text">Pebble.js running on all available platforms.</p>

Whether or not you’re targeting the Chalk platform, there are many new features
for you to explore in this update - and simply recompiling your project with the
latest version of Pebble.js will update the look and feel through refined
spacing between text fields.

The background color of window's status bar can now be changed, allowing it to
blend in with the app's background in a similar way to Pebble's Music app.

```js
var defaultBackgroundColor = 'white';
var defaultColor = 'black';

var card = new UI.Card({
  backgroundColor: defaultBackgroundColor,
  status: {
    color: defaultColor,
    backgroundColor: defaultBackgroundColor
  }
});

card.show();
```

Two new elements were added,
[Line](/docs/pebblejs/#line) and
[Radial](/docs/pebblejs/#radial), and all elements
now include [borderWidth](/docs/pebblejs/#element-
borderwidth- width), [borderColor](/docs/pebblejs
/#element- bordercolor-color) and
[backgroundColor](/docs/pebblejs/#element-
backgroundcolor-color) properties (except `Line`, which uses
[strokeWidth](/docs/pebblejs/#line-strokewidth-
width) and [strokeColor](/docs/pebblejs/#line-
strokecolor-color) instead).

There are many bugfixes as well. Scrolling is no longer jittery for cards and
menus, the status bar will no longer disappear upon changing windows that both
requested to have a status bar, and large bodies of text are truncated in cards
instead of just not showing up.

There is one new known issue - which causes some applications with heavy memory
usage to crash. If you're experiencing this issue, we would appreciate you
adding more details to [#161](https://github.com/pebble/pebblejs/issues/161).

This update also comes with two new guides to help familiarize yourself with the
exciting new world of round and colorful apps. [Using
Color](/docs/pebblejs/#using-color) will help you
understand all the different ways you can specify which color you want your text
(and other elements) to be, and how you would go about styling your app with
color. [Using Feature](/docs/pebblejs/#using-
feature) will help you understand the new Feature API, how it can be used to
specify different behaviours and UIs depending on what platform you're running
on, and what features it includes.

## CloudPebble

Enabling Chalk support in CloudPebble is simple. Open your project's "Settings"
screen, check the "Build Chalk" box, then recompile your project.

![CloudPebble Settings Screen](/images/blog/2016-05-13-pebble-js-round/settings.png)
<p class="blog__image-text">Cloud Pebble Settings Screen.</p>

To run your project on CloudPebble's Chalk emulator, compile your project, then
open the "Compilation" sceen, and select "Emulator" then "Chalk."

## Pebble Tool + Local SDK

If you're using the Pebble Tool and local SDK, you'll need to merge the `master`
branch of the Pebble.js repositoroy into your project, then edit the
`appinfo.json` file to include `chalk` in the `targetPlatforms` array.

```
{
  "uuid": "8e02b5f5-c0fb-450c-a568-47fcaadf97eb",
  "shortName": "Test",
  "longName": "Test Application",
  "companyName": "#makeawesomehappen",
  "versionLabel": "0.1",
  "sdkVersion": "3",
  "enableMultiJS": true,
  "targetPlatforms": ["aplite", "basalt", "chalk"],
  "watchapp": {
    "watchface": false
  },
  "appKeys": { },
  "resources": { }
}

```

To run your project with command line emulator, compile your project, then
install it to the Chalk emulator:

```
> pebble clean
> pebble build && pebble install --emulator=chalk --logs
```

Remember, we’re also working on supporting native JavaScript applications on
Pebble smartwatches, and are calling it
[Rocky.js](https://pebble.github.io/rockyjs/). Rest assured, I will continue to
maintain Pebble.js, and you can continue to develop and ship apps with it! Keep
an eye out on future developments by following the [GitHub
repository](https://github.com/pebble/pebblejs) and checking out the latest
commits.

Let us know abour Pebble.js project or anything else you feel like mentioning,
by shouting on Twitter to [@PebbleDev](https://twitter.com/pebbledev),
[@Pebble](https://twitter.com/pebble) or even myself
[@Meiguro](https://twitter.com/meiguro).

Here’s to more exciting weekend coding sessions in the future for both of us!
