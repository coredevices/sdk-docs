---
# Copyright 2025 Core Devices LLC
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

layout: tutorials/tutorial
tutorial: alloy-watchface
tutorial_part: 1

title: Your First Watchface
description: |
  Learn the basics of creating a Pebble watchface with Alloy, including
  displaying the time and date.
permalink: /tutorials/alloy-watchface-tutorial/part1/
generate_toc: true
platform_choice: true
---

> The complete source code for this tutorial is
> [available on GitHub](https://github.com/coredevices/alloy-watchface-tutorial).

In this tutorial series we will build a fully-featured digital watchface from
scratch using Alloy, Pebble's modern JavaScript framework. By the end you will
have a watchface with weather support, user settings, and more. But first, we
need to start with the basics.

> **Platform Support**: Alloy currently supports Emery (Pebble Time 2) and
> Gabbro (Pebble Round 2).

When we are done with this first part, you should have a working watchface that
displays the time and date on a black background:

{% screenshot_viewer %}
{
  "image": "/images/tutorials/alloy-watchface-tutorial/part1.png",
  "default": "emery",
  "platforms": [
    {"hw": "emery", "wrapper": "core-time2-red"},
    {"hw": "gabbro", "wrapper": "core-time-round2-black-20"}
  ]
}
{% endscreenshot_viewer %}


## Creating a New Project

^CP^ Go to [CloudPebble]({{ site.links.cloudpebble }}) and click **Create** to
start a new project. Choose **JavaScript SDK (beta)** as the project type
(this is Alloy) and name it "watchface". Then go to **Settings** on the left and
set **App Kind** to **Watchface**.

^LC^ Before we begin, make sure you have the Pebble SDK installed. If you haven't
done this yet, head over to the [download page](/sdk) to get set up.

^LC^ Once you are ready, navigate to a directory of your choosing and create a new
Alloy project:

{% platform local %}
```text
$ pebble new-project --alloy watchface
```
{% endplatform %}

^CP^ The most important file is `main.js` - this is where your watchface code
runs on the watch.

^LC^ This creates a new folder with the basic structure for an Alloy app. The most
important file is `src/embeddedjs/main.js` - this is where your watchface code
runs on the watch. (See the
[Getting Started guide](/guides/alloy/getting-started/) for more details on
project structure.)

^LC^ Open `package.json` and make sure the `watchapp` object indicates this is a
watchface:

{% platform local %}
```json
"watchapp": {
  "watchface": true
}
```
{% endplatform %}

The key difference between a watchface and a watchapp is that watchfaces serve
as the default display on the watch. The Up and Down buttons are reserved for
the Pebble timeline, so they are not available for custom behavior.


## Understanding Alloy Watchfaces

Every Alloy watchface follows the same basic pattern:

1. **Import Poco** for graphics rendering
2. **Create a renderer** from the `screen` global
3. **Set up fonts and colors** once at startup
4. **Register a time event** that redraws the display

^CP^ Open `main.js` in the CloudPebble editor and replace its contents with:

^LC^ Open `src/embeddedjs/main.js` and replace its contents with:

```js
import Poco from "commodetto/Poco";

const render = new Poco(screen);
```

`Poco` is a low-level graphics library for drawing on the screen. The `screen`
global provides access to the Pebble display.


## Setting Up Fonts and Colors

Before we can draw anything, we need a font and some colors. Add these below
the renderer:

```js
// Fonts
const timeFont = new render.Font("Bitham-Bold", 42);
const dateFont = new render.Font("Gothic-Bold", 24);

// Colors
const black = render.makeColor(0, 0, 0);
const white = render.makeColor(255, 255, 255);
```

Alloy comes with several built-in Pebble fonts. `Bitham-Bold` at 42px is a
good size for a time display - bold and easy to read at a glance.

`makeColor()` takes RGB values (0–255) and returns a color value optimized for
the display.


## Displaying the Time

Now let's write a draw function. All Poco drawing happens between `begin()` and
`end()` calls:

```js
function draw(event) {
    const now = event.date;

    render.begin();
    render.fillRectangle(black, 0, 0, render.width, render.height);

    // Format time as HH:MM
    const hours = String(now.getHours()).padStart(2, "0");
    const minutes = String(now.getMinutes()).padStart(2, "0");
    const timeStr = `${hours}:${minutes}`;

    // Center the time on screen
    let width = render.getTextWidth(timeStr, timeFont);
    render.drawText(timeStr, timeFont, white,
        (render.width - width) / 2,
        (render.height / 2) - timeFont.height + 5);

    render.end();
}
```

The `event` parameter contains a `date` property with the current `Date`
object - no need to call `new Date()` yourself. We use `padStart()` to ensure
single-digit hours and minutes are zero-padded (e.g., "09:05" instead of
"9:5").

`getTextWidth()` measures how many pixels wide the rendered text will be, which
lets us center it horizontally.

Now register the draw function for time updates:

```js
watch.addEventListener("minutechange", draw);
```

`minutechange` fires once every minute. The callback is also invoked
immediately when the event listener is registered, so the watchface draws right
away without needing a separate startup call. You could use `secondchange` for
a seconds display, but that costs extra battery.

^CP^ Click the **play** button to compile and install - you should now see the
current time!

^LC^ Build and install - you should now see the current time!

{% platform local %}
```nc|text
$ pebble build
$ pebble install --emulator emery
```
{% endplatform %}


## Adding the Date

Let's add a date display below the time. We need day and month name arrays
since JavaScript's `Date` only provides numeric values:

```js
const DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
```

Now update the `draw()` function to include the date. Add this after the time
drawing, before `render.end()`:

```js
    // Format date as "Mon Jan 01"
    const dayName = DAYS[now.getDay()];
    const monthName = MONTHS[now.getMonth()];
    const dateStr = `${dayName} ${monthName} ${String(now.getDate()).padStart(2, "0")}`;

    // Draw date below the time
    width = render.getTextWidth(dateStr, dateFont);
    render.drawText(dateStr, dateFont, white,
        (render.width - width) / 2,
        (render.height / 2) + 10);
```

Build and install. You should now see both the time and date.


## Conclusion

That is the basic process for creating a Pebble watchface with Alloy! To recap,
we:

1. Created a new Alloy project configured as a watchface.
2. Imported Poco and created a renderer.
3. Set up fonts and colors.
4. Drew the time centered on screen.
5. Registered a `minutechange` event listener to keep the display updated.
6. Added a date display.

If you have problems with your code, check it against
[the source code for this part](https://github.com/coredevices/alloy-watchface-tutorial/tree/main/part1).


## What's Next?

The design is functional but plain. In the next part we will switch to a more
distinctive font and properly center the layout.

[Go to Part 2 &rarr; >{wide,bg-dark-red,fg-white}](/tutorials/alloy-watchface-tutorial/part2/)
