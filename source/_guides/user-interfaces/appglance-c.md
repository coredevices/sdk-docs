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

title: AppGlance C API
description: |
  How to programatically update an app's app glance.
guide_group: user-interfaces
order: 2
related_docs:
  - AppGlanceSlice
related_examples:
  - title: Hello World
    url: https://github.com/pebble-examples/app-glance-hello-world
  - title: Virtual Pet
    url: https://github.com/pebble-examples/app-glance-virtual-pet

---

## Overview

An app's "glance" is the visual representation of a watchapp in the launcher and
provides glanceable information to the user. The ``App Glance`` API, added in SDK
4.0, enables developers to programmatically set the icon and subtitle that
appears alongside their app in the launcher.

> The ``App Glance`` API is only applicable to watchapps, it is not supported by
watchfaces.

## Glances and AppGlanceSlices

An app's glance can change over time, and is defined by zero or more
``AppGlanceSlice`` each consisting of a layout (including a subtitle and icon),
as well as an expiration time. AppGlanceSlices are displayed in the order they
were added, and will persist until their expiration time, or another call to
``app_glance_reload()``.

> To create an ``AppGlanceSlice`` with no expiration time, use
> ``APP_GLANCE_SLICE_NO_EXPIRATION``

Developers can change their watchapp’s glance by calling the
``app_glance_reload()`` method, which first clears any existing app glance
slices, and then loads zero or more ``AppGlanceSlice`` as specified by the
developer.

The ``app_glance_reload()`` method is invoked with two parameters: a pointer to an
``AppGlanceReloadCallback`` that will be invoked after the existing app glance
slices have been cleared, and a pointer to context data. Developers can add new
``AppGlanceSlice`` to their app's glance in the ``AppGlanceReloadCallback``.

```c
// ...
// app_glance_reload callback
static void prv_update_app_glance(AppGlanceReloadSession *session,
                                       size_t limit, void *context) {
  // Create and add app glance slices...
}

static void prv_deinit() {
  // deinit code
  // ...

  // Reload the watchapp's app glance
  app_glance_reload(prv_update_app_glance, NULL);
}
```

## The app_glance_reload Callback

The ``app_glance_reload()`` is invoked with 3 parameters, a pointer to an
``AppGlanceReloadSession`` (which is used when invoking
``app_glance_add_slice()``) , the maximum number of slices you are able to add
(as determined by the system at run time), and a pointer to the context data
that was passed into ``app_glance_reload()``. The context data should contain
all the information required to build the ``AppGlanceSlice``, and is typically
cast to a specific type before being used.

> The `limit` is currently set to 8 app glance slices per watchapp, though there
> is no guarantee that this value will remain static, and developers should
> always ensure they are not adding more slices than the limit.

![Hello World >{pebble-screenshot,pebble-screenshot--time-black}](/images/guides/appglance-c/hello-world-app-glance.png)

In this example, we’re passing the string we would like to set as the subtitle,
by using the context parameter. The full code for this example can be found in
the [AppGlance-Hello-World](https://github.com/pebble-examples/app-glance-hello-world)
repository.

```c
static void prv_update_app_glance(AppGlanceReloadSession *session,
                                       size_t limit, void *context) {
  // This should never happen, but developers should always ensure they are
  // not adding more slices than are available
  if (limit < 1) return;

  // Cast the context object to a string
  const char *message = context;

  // Create the AppGlanceSlice
  // NOTE: When .icon is not set, the app's default icon is used
  const AppGlanceSlice entry = (AppGlanceSlice) {
    .layout = {
      .icon = APP_GLANCE_SLICE_DEFAULT_ICON,
      .subtitle_template_string = message
    },
    .expiration_time = APP_GLANCE_SLICE_NO_EXPIRATION
  };

  // Add the slice, and check the result
  const AppGlanceResult result = app_glance_add_slice(session, entry);

  if (result != APP_GLANCE_RESULT_SUCCESS) {
    APP_LOG(APP_LOG_LEVEL_ERROR, "AppGlance Error: %d", result);
  }
}
```

> **NOTE:** When an ``AppGlanceSlice`` is loaded with the
> ``app_glance_add_slice()`` method, the slice's
> `layout.subtitle_template_string` is copied to the app's glance, meaning the
> string does not need to persist after the call to ``app_glance_add_slice()``
> is made.

## Using Custom Icons

In order to use custom icons within an ``AppGlanceSlice``, you need to use the
new `publishedMedia` entry in the `package.json` file.

* Create your images as 25px x 25px PNG files.
* Add your images as media resources in the `package.json`.
* Then add the `publishedMedia` declaration.

You should end up with something like this:

```js
"resources": {
  "media": [
    {
      "name": "WEATHER_HOT_ICON_TINY",
      "type": "bitmap",
      "file": "hot_tiny.png"
    }
  ],
  "publishedMedia": [
    {
      "name": "WEATHER_HOT",
      "id": 1,
      "glance": "WEATHER_HOT_ICON_TINY"
    }
  ]
}
```

Then you can reference the `icon` by `name` in your ``AppGlanceSlice``. You must
use the prefix `PUBLISHED_ID_`. E.g. `PUBLISHED_ID_WEATHER_HOT`.

## Subtitle Template Strings

The `subtitle_template_string` field provides developers with a string
formatting language for app glance subtitles. Developers can create a single
app glance slice which updates automatically based upon a timestamp.

For example, the template can be used to create a countdown until a timestamp
(`time_until`), or the duration since a timestamp (`time_since`). The result
from the timestamp evaluation can be output in various different time-format's,
such as:

* It's 50 days until New Year
* Your Uber will arrive in 5 minutes
* You are 15515 days old

### Template Structure

The template string has the following structure:

<code>{<strong><em>evaluation</em></strong>(<strong><em>timestamp</em></strong>)|format(<strong><em>parameters</em></strong>)}</code>

Let's take a look at a simple countdown example:

`Your Uber will arrive in 1 hr 10 min 4 sec`

In this example, we need to know the time until our timestamp:
`time_until(1467834606)`, then output the duration using an abbreviated
time-format: `%aT`.

`Your Uber will arrive in {time_until(1467834606)|format('%aT')}`

### Format Parameters

Each format parameter is comprised of an optional predicate, and a time-format,
separated by a colon. The time-format parameter is only output if the predicate
evaluates to true. If a predicate is not supplied, the time-format is output by
default.

<code>format(<strong><em>predicate</em></strong>:'<strong><em>time-format</em></strong>')</code>

#### Predicate

The predicates are composed of a comparator and time value. For example, the
difference between `now` and the timestamp evaluation is:

* `>1d` Greater than 1 day
* `<12m` Less than 12 months
* `>=6m` Greater than or equal to 6 months
* `<=1d12h` Less than or equal to 1 day, 12 hours.

The supported time units are:

* `d` (Day)
* `H` (Hour)
* `M` (Minute)
* `S` (Second)

#### Time Format

The time-format is a single quoted string, comprised of a percent sign and an
optional format flag, followed by a time unit. For example:

`'%aT'` Abbreviated time. e.g. 1 hr 10 min 4 sec

The optional format flags are:

* `a` Adds abbreviated units (translated and with proper pluralization) (overrides 'u' flag)
* `u` Adds units (translated and with proper pluralization) (overrides 'a' flag)
* `-` Negates the input for this format specifier
* `0` Pad value to the "expected" number of digits with zeros
* `f` Do not modulus the value

The following table demonstrates sample output for each time unit, and the
effects of the format flags.

|<small>Time Unit</small>|<small>No flag</small>|<small>'u' flag</small>|<small>'a' flag</small>|<small>'0' flag</small>|<small>'f' flag</small>|
| --- | --- | --- | --- | --- | --- |
| <small>**y**</small> | <small>&lt;year&gt;</small> | <small>&lt;year&gt; year(s)</small> | <small>&lt;year&gt; yr(s)</small> | <small>&lt;year, pad to 2&gt;</small> | <small>&lt;year, no modulus&gt;</small> |
| <small>output:</small> | <small>4</small> | <small>4 years</small> | <small>4 yr</small> | <small>04</small> | <small>4</small> |
| <small>**m**</small> | <small>&lt;month&gt;</small> | <small>&lt;month&gt; month(s)</small> | <small>&lt;month&gt; mo(s)</small> | <small>&lt;month, pad to 2&gt;</small> | <small>&lt;month, no modulus&gt;</small> |
| <small>output:</small> | <small>8</small> | <small>8 months</small> | <small>8 mo</small> | <small>08</small> | <small>16</small> |
| <small>**d**</small> | <small>&lt;day&gt;</small> | <small>&lt;day&gt; days</small> | <small>&lt;day&gt; d</small> | <small>&lt;day, pad to 2&gt;</small> | <small>&lt;day, no modulus&gt;</small> |
| <small>output:</small> | <small>7</small> | <small>7 days</small> | <small>7 d</small> | <small>07</small> | <small>38</small> |
| <small>**H**</small> | <small>&lt;hour&gt;</small> | <small>&lt;hour&gt; hour(s)</small> | <small>&lt;hour&gt; hr</small> | <small>&lt;hour, pad to 2&gt;</small> | <small>&lt;hour, no modulus&gt;</small> |
| <small>output:</small> | <small>1</small> | <small>1 hour</small> | <small>1 hr</small> | <small>01</small> | <small>25</small> |
| <small>**M**</small> | <small>&lt;minute&gt;</small> | <small>&lt;minute&gt; minute(s)</small> | <small>&lt;minute&gt; min</small> | <small>&lt;minute, pad to 2&gt;</small> | <small>&lt;minute, no modulus&gt;</small> |
| <small>output:</small> | <small>22</small> | <small>22 minutes</small> | <small>22 min</small> | <small>22</small> | <small>82</small> |
| <small>**S**</small> | <small>&lt;second&gt;</small> | <small>&lt;second&gt; second(s)</small> | <small>&lt;second&gt; sec</small> | <small>&lt;second, pad to 2&gt;</small> | <small>&lt;second, no modulus&gt;</small> |
| <small>output:</small> | <small>5</small> | <small>5 seconds</small> | <small>5 sec</small> | <small>05</small> | <small>65</small> |
| <small>**T**</small> | <small>%H:%0M:%0S (if &gt;= 1hr)<hr />%M:%0S (if &gt;= 1m)<hr />%S (otherwise)</small> | <small>%uH, %uM, and %uS<hr />%uM, and %uS<hr />%uS</small> | <small>%aH %aM %aS<hr />%aM %aS<hr />%aS</small> | <small>%0H:%0M:%0S (always)</small> | <small>%fH:%0M:%0S<hr />%M:%0S<hr />%S</small> |
| <small>output:</small> | <small>1:53:20<hr />53:20<hr />20</small> | <small>1 hour, 53 minutes, and 20 seconds<hr />53 minutes, and 20 seconds<hr />20 seconds</small> | <small>1 hr 53 min 20 sec<hr />53 min 20 sec<hr />20 sec</small> | <small>01:53:20<hr />00:53:20<hr />00:00:20</small> | <small>25:53:20<hr />53:20<hr />20</small> |
| <small>**R**</small> | <small>%H:%0M (if &gt;= 1hr)<hr />%M (otherwise)</small> | <small>%uH, and %uM<hr />%uM</small> | <small>%aH %aM<hr />%aM</small> | <small>%0H:%0M (always)</small> | <small>%fH:%0M<hr />%M</small> |
| <small>output:</small> | <small>23:04<hr />15</small> | <small>23 hours, and 4 minutes<hr />15 minutes</small> | <small>23 hr 4 min<hr />15 min</small> | <small>23:04<hr />00:15</small> | <small>47:04<hr />15</small> |

> Note: The time units listed above are not all available for use as predicates,
but can be used with format flags.

#### Advanced Usage

We've seen how to use a single parameter to generate our output, but for more
advanced cases, we can chain multiple parameters together. This allows for a
single app glance slice to produce different output as each parameter evaluates
successfully, from left to right.

<code>format(<strong><em>predicate</em></strong>:'<strong><em>time-format</em></strong>', <strong><em>predicate</em></strong>:'<strong><em>time-format</em></strong>', <strong><em>predicate</em></strong>:'<strong><em>time-format</em></strong>')</code>

For example, we can generate a countdown which displays different output before,
during and after the event:

* 100 days left
* 10 hr 5 min 20 sec left
* It's New Year!
* 10 days since New Year

To produce this output we could use the following template:

`{time_until(1483228800)|format(>=1d:'%ud left',>0S:'%aT left',>-1d:\"It's New Year!\", '%-ud since New Year')}`


## Adding Multiple Slices

An app's glance can change over time, with the slices being displayed in the
order they were added, and removed after the `expiration_time`. In order to add
multiple app glance slices, we simply need to create and add multiple
``AppGlanceSlice`` instances, with increasing expiration times.

![Virtual Pet >{pebble-screenshot,pebble-screenshot--time-black}](/images/guides/appglance-c/virtual-pet-app-glance.png)

In the following example, we create a basic virtual pet that needs to be fed (by
opening the app) every 12 hours, or else it runs away. When the app closes, we
update the app glance to display a new message and icon every 3 hours until the
virtual pet runs away. The full code for this example can be found in the
[AppGlance-Virtual-Pet](https://github.com/pebble-examples/app-glance-virtual-pet)
repository.

```c
// How often pet needs to be fed (12 hrs)
#define PET_FEEDING_FREQUENCY 3600*12
// Number of states to show in the launcher
#define NUM_STATES 4

// Icons associated with each state
const uint32_t icons[NUM_STATES] = {
  PUBLISHED_ID_ICON_FROG_HAPPY,
  PUBLISHED_ID_ICON_FROG_HUNGRY,
  PUBLISHED_ID_ICON_FROG_VERY_HUNGRY,
  PUBLISHED_ID_ICON_FROG_MISSING
};

// Message associated with each state
const char *messages[NUM_STATES] = {
  "Mmm, that was delicious!!",
  "I'm getting hungry..",
  "I'm so hungry!! Please feed me soon..",
  "Your pet ran away :("
};

static void prv_update_app_glance(AppGlanceReloadSession *session,
                                       size_t limit, void *context) {

  // Ensure we have sufficient slices
  if (limit < NUM_STATES) {
    APP_LOG(APP_LOG_LEVEL_DEBUG, "Error: app needs %d slices (%zu available)",
                                                            NUM_STATES, limit);
  }

  time_t expiration_time = time(NULL);

  // Build and add NUM_STATES slices
  for (int i = 0; i < NUM_STATES; i++) {
    // Increment the expiration_time of the slice on each pass
    expiration_time += PET_FEEDING_FREQUENCY / NUM_STATES;

    // Set it so the last slice never expires
    if (i == (NUM_STATES - 1)) expiration_time = APP_GLANCE_SLICE_NO_EXPIRATION;

    // Create the slice
    const AppGlanceSlice slice = {
      .layout = {
        .icon = icons[i],
        .subtitle_template_string = messages[i]
      },
      .expiration_time = expiration_time
    };

    // add the slice, and check the result
    AppGlanceResult result = app_glance_add_slice(session, slice);
    if (result != APP_GLANCE_RESULT_SUCCESS) {
      APP_LOG(APP_LOG_LEVEL_ERROR, "Error adding AppGlanceSlice: %d", result);
    }
  }
}

static void prv_deinit() {
  app_glance_reload(prv_update_app_glance, NULL);
}

void main() {
  app_event_loop();
  prv_deinit();
}
```
