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

title: JavaScript Libraries for C Developers (pt. 1)
author: cat
tags:
- Freshly Baked
- Beautiful Code

---

One of the exciting changes introduced in [SDK 3.9] [sdk 3.9] was support for
including [Multiple JavaScript Files] [js blog] to your projects. While this
feature doesn’t allow you to run any JavaScript you previously couldn’t, it
makes organizing your PebbleKit JS code a heck of a lot easier.

In this blog post, we'll look at how to refactor some exisiting JavaScript
'library code' into an actual module for PebbleKit JS, making it simpler to use
and share!



## OWM-Weather

A few months ago we published a very simple 'library' for working with the
[Open Weather Map] [owm] API. The JavaScript side of the code takes care of
grabbing the user’s location with the built in [geolocation.getCurrentPosition]
[getcurrentposition] API, then fetches weather information for the returned
position.

The initial version of the code we’re working with can be found [here] [owm lib 0].

## Creating JavaScript Classes

> **Note:** While JavaScript (with ECMAS5) does not allow for true "Classes",
> JavaScript does a support a mechanism that allows you write Class-like code.
> For convience, we'll be refering to these objects as 'classes' throughout
> this post.

The first thing we want to do is wrap our library code in an Object constructor
function, which is what allows us to treat `OWMWeather` as a class, and rewrite
our functions so they're properties belonging to `this` (an instantiated
version of the object). If you're interested in diving a bit deeper into how
this works, take a look at Pivotal's great blog post about [JavaScript
constructors, prototypes, and the 'new' keyword] [pivotal blog].

```js
var OWMWeather = function() {
  this.owmWeatherAPIKey = '';

  this.owmWeatherXHR = function(url, type, callback) {
    //...
  };
  //...
};
```

We’ll also need to change our JS application code to construct a new
`OWMWeather` object, and change our reference of `appMessageHandler()` in the
in the `Pebble.addEventListener('appmessage', ...)` callback to
`owmWeather.appMessageHandler()`.

```js
var owmWeather = new OWMWeather();

Pebble.addEventListener('ready', function(e) {
  console.log('PebbleKit JS ready!');
});

Pebble.addEventListener('appmessage', function(e) {
  console.log('appmessage: ' + JSON.stringify(e.payload));
  owmWeather.appMessageHandler(e);
});
```

## Using the .bind() function

If we try to run our code at this point in time, we're going to run into a slew
of errors because we've changed the scope of the functions, but we haven't
updated the places where we call them. We need to change
`owmWeatherFunctionName()` to `this.owmWeatherFunctionName()` (same goes for
the API key). Here's what the new `owmWeatherLocationSuccess` method looks like
(changes are indicated with in-line comments):

```js
this.owmWeatherLocationSuccess = function(pos) {
  // Change owmWeatherAPIKey to this.owmWeatherAPIKey
  var url = 'http://api.openweathermap.org/data/2.5/weather?' +
    'lat=' + pos.coords.latitude + '&lon=' + pos.coords.longitude +
    '&appid=' + this.owmWeatherAPIKey;
  console.log('owm-weather: Location success. Contacting OpenWeatherMap.org..');

  this.owmWeatherXHR(url, 'GET', function(responseText) {
    console.log('owm-weather: Got API response!');
    if(responseText.length > 100) {
      // Change owmWeatherSendToPebble(..) to this.owmWeatherSendToPebble(..)
      this.owmWeatherSendToPebble(JSON.parse(responseText));
    } else {
      console.log('owm-weather: API response was bad. Wrong API key?');
      Pebble.sendAppMessage({ 'OWMWeatherAppMessageKeyBadKey': 1 });
    }
  // Add .bind(this) to the closing brace of the callback
  }.bind(this));
};
```

An observant developer might notice that along with changing `owmWeatherXHR` to
`this.owmWeatherXHR`, we've also added `.bind(this)` to the end of the callback
function.

We're not going to dive too deeply into how `this` and `bind` works (that's a
whole blog post on its own), but what I will say is that the `bind` method can
be thought of as modifying a function so that it will, when invoked, have its
`this` keyword set to the provided parameter.

> If you want to learn more about JavaScript Objects, scope, and `bind`, I will
> encourage you to read [You Don't Know JS: *this* & Object Prototypes] [js book].

We'll want use `bind(this)` (where `this` will be the instance of the
OWMWeather class) whenever we're using an OWMWeather method as a callback from
within the OWMWeather code.

```js
navigator.geolocation.getCurrentPosition(
  this.owmWeatherLocationSuccess.bind(this),
  this.owmWeatherLocationError.bind(this), {
    timeout: 15000,
    maximumAge: 60000
});
```

At this point, our code should look like [this] [owm lib 1].

## Using module.exports

The last thing we want to do to make this into a handy module is extract the
code into its own file (`/src/js/lib/owm_weather.js`), and use the
[module.exports] [module exports] API to export our OWMWeather class.

```js
var OWMWeather = new function() {
  //...
};

module.exports = OWMWeather;
```

In order to use this in our PebbleKit JS application, we need to do a couple things..

If you're using CloudPebble:

- Change **JS Handling** to _CommonJS-style_ in the project settings


If you're using the SDK:

- Update our `appinfo.json` to include `'enableMultiJS': true` if it isn't
  already there

- Rename `src/js/pebble-js-app.js` to `src/js/app.js`

Once we've made these changes to our files, we're ready to include OWMWeather
in our `app.js` file with the [require API] [require api].

```js
var OWMWeather = require('./lib/owm_weather.js');
var owmWeather = new OWMWeather();

Pebble.addEventListener('ready', function(e) {
  console.log('PebbleKit JS ready!');
});

Pebble.addEventListener('appmessage', function(e) {
  console.log('appmessage: ' + JSON.stringify(e.payload));
  owmWeather.appMessageHandler(e);
});
```

At this point, our code should something look like [this][owm lib 2].

## Refactoring Variable and Function Names

Since we’ve moved all of the OWMWeather code into a class, we can safely remove
the `owmWeather` prefixes on all of our methods and properties. While we’re at
it, we're also going to rename functions and properties that are intended to be
private to begin with an `_`, which is fairly common practice:

```js
var OWMWeather = function() {
  this._apiKey = '';

  this._xhrWrapper = function(url, type, callback) {
    //...
  };
  //...
};
```

## What's next..

And that's it - we've successfuly refactored our code into a module that should
be easier for developers to use and share (which is exactly what we want). You
can view the full source code for this blog post [here][owm lib final].

In the next blog post, we'll take this library a step further and look at how
you can abstract away the need for `appKeys` in your `appinfo.json` file to
make working with the library *even easier*...

Until then, happy hacking!


[sdk 3.9]: /sdk/changelogs/3.9/
[js blog]: /blog/2016/01/29/Multiple-JavaScript-Files/


[owm]: http://openweathermap.org/


[getcurrentposition]: https://developer.mozilla.org/en-US/docs/Web/API/Geolocation/getCurrentPosition

[pivotal blog]: https://blog.pivotal.io/labs/labs/javascript-constructors-prototypes-and-the-new-keyword

[js book]: https://github.com/getify/You-Dont-Know-JS/blob/master/this%20&%20object%20prototypes/README.md#you-dont-know-js-this--object-prototypes

[module exports]: http://www.sitepoint.com/understanding-module-exports-exports-node-js/

[require api]: http://www.sitepoint.com/understanding-module-exports-exports-node-js/#importing-a-module


[owm lib 0]: https://github.com/pebble-hacks/owm-weather/tree/8c4f770e591fe5eff65209ebb6fe6ef23152d81a

[owm lib 1]: https://github.com/pebble-hacks/owm-weather/blob/8c9ab77a66d5c38719acbdfce939fbfac6d12235/owm_weather/owm_weather.js

[owm lib 2]: https://github.com/pebble-hacks/owm-weather/tree/597c717627c281b56ff303ca94f35789002a969e

[owm lib final]: https://github.com/pebble-hacks/owm-weather/tree/657da669c3d9309a956f655c65263b8dc06cec1f
