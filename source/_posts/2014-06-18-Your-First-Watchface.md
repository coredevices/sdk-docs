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

title: Pebble SDK Tutorial (Part 2)
author: Chris Lewis
excerpt: |
  This is the second in a series of articles aimed at helping developers new and
  experienced begin creating their own watchapps. In this section we will be
  using the TickTimerService to display the current time, which is the basis of
  all great watchfaces. After this, we will use GBitmaps and BitmapLayers to
  improve the aesthetics of our watchface.
---

##Your First Watchface

###Previous Tutorial Parts
[Pebble SDK Tutorial (Part 1): Your First Watchapp](/blog/2014/06/10/Pebble-SDK-Tutorial-1/)

###Introduction

This is the second in a series of articles aimed at helping developers new and
experienced begin creating their own watchapps. In this section we will be using
the ``TickTimerService`` to display the current time, which is the basis of all
great watchfaces. After this, we will use ``GBitmap``s and ``BitmapLayer``s to
improve the aesthetics of our watchface. By the end of this section, our app
will look like this:

![final](/images/blog/tut_2_frame_added.png "final")



###Getting Started

To begin creating this watchface, we will be using the 
[source code](https://gist.github.com/C-D-Lewis/a911f0b053260f209390) from the 
last post as a starting point, which you can import into 
[CloudPebble]({{site.links.cloudpebble}}) as a new project 
[here](https://cloudpebble.net/ide/gist/a911f0b053260f209390). 

As you may have noticed, the current watchapp is started from the Pebble main
menu, and not on the watchface carousel like other watchfaces. To change this,
go to 'Settings' in your CloudPebble project and change the 'App Kind' to
'Watchface'. This will cause the app to behave in the same way as any other
watchface. If you were using the native SDK, this change would be done in the
`appinfo.json` file.

Once this is done, we will modify the main C file to prepare it for showing the
time. Remove the call to ``text_layer_set_text()`` to prevent the watchface
showing anything irrelevant before the time is shown. For reference,
`window_load()` should now look like this:

```c
void window_load(Window *window)
{
  //We will add the creation of the Window's elements here soon!
  g_text_layer = text_layer_create(GRect(0, 0, 144, 168));
  text_layer_set_background_color(g_text_layer, GColorClear);
  text_layer_set_text_color(g_text_layer, GColorBlack);
 
  layer_add_child(window_get_root_layer(window), text_layer_get_layer(g_text_layer));
}
```

###Telling the Time

Now we can use the ``TextLayer`` we created earlier to display the current time,
which is provided to us once we register a ``TickHandler`` with the system. The
first step to do this is to create an empty function in the format dictated by
the ``TickHandler`` documentation page. This is best placed before it will be
used, which is above `init()`:

```c
void tick_handler(struct tm *tick_time, TimeUnits units_changed)
{

}
```

This function is called by the system at a fixed tick rate depending on the
``TimeUnits`` value supplied when we register the handler. Let's do this now in
`init()` before ``window_stack_push()``, using the ``MINUTE_UNIT`` value to get
an update every minute change:

```c
tick_timer_service_subscribe(MINUTE_UNIT, (TickHandler)tick_handler);
```

Now that we have subscribed to the ``TickTimerService``, we can add code to the 
`tick_handler()` function to use the time information provided in the 
`tick_time` parameter to update the ``TextLayer``. The data stored within this 
structure follows the 
[ctime struct tm format](http://www.cplusplus.com/reference/ctime/tm/). This 
means that we can access the current hour by using `tick_time->tm_hour` and the
current minute by using `tick_time->tm_min`, for example. Instead, we will use a
function called `strftime()` that uses the `tick_time` parameter to write a
time-formatted string into a buffer we provide, called `buffer`. Therefore the
new tick handler will look like this:

```c
void tick_handler(struct tm *tick_time, TimeUnits units_changed)
{
  //Allocate long-lived storage (required by TextLayer)
  static char buffer[] = "00:00";
  
  //Write the time to the buffer in a safe manner
  strftime(buffer, sizeof("00:00"), "%H:%M", tick_time);
  
  //Set the TextLayer to display the buffer
  text_layer_set_text(g_text_layer, buffer);
}
```

Now every time a minute passes `tick_handler()` will create a new string in the
buffer and display it in the ``TextLayer``. This is the basis of every
watchface. However, the text contained in the ``TextLayer`` is difficult to read
because the default system font is very samll, so we will change some of the
layout properties to better suit its purpose. Modify `window_load()` to add the
relevant ``TextLayer`` functions like so:

```c
void window_load(Window *window)
{
  //Create the TextLayer
  g_text_layer = text_layer_create(GRect(0, 59, 144, 50));
  text_layer_set_background_color(g_text_layer, GColorClear);
  text_layer_set_text_color(g_text_layer, GColorBlack);
  
  //Improve the layout to be more like a watchface
  text_layer_set_font(g_text_layer, fonts_get_system_font(FONT_KEY_BITHAM_42_BOLD));
  text_layer_set_text_alignment(g_text_layer, GTextAlignmentCenter);
 
  layer_add_child(window_get_root_layer(window), text_layer_get_layer(g_text_layer));
}
``` 

Now the watchface should look more like a classic watchface with a larger font
and centered text:

![largetext](/images/blog/tut_2_largetext.png "large text")

###Adding Bitmaps
The next logical way to improve the watchface is to add some complementary
images. These take the form of ``GBitmap``s, and are referenced by a
`RESOURCE_ID` specified in CloudPebble Settings or `appinfo.json` when working
with the native SDK. The first bitmap we wil add will be a smart border for the
``TextLayer``, shown for you to use below:

![frame](/images/blog/tut_2_frame.png "frame")

To add this image to our project in CloudPebble, click "Add New" next to
Resources, navigate to your stored copy of the image above and give it an ID
such as "FRAME", then click Save.

Once this is done, we can add it to the watchface. The first step is to declare
two new global items: A ``GBitmap`` to hold the loaded image and a
``BitmapLayer`` to show it. Add these to the top of the file, alongside the
existing global variables:

```c
GBitmap *g_frame_bitmap;
BitmapLayer *g_frame_layer;
```

The next step is to allocate the ``GBitmap``, show it using the ``BitmapLayer``
and add it as a child of the main ``Window``. ``Layer``s are drawn in the order
they are added to their parent, so be sure to add the ``BitmapLayer`` **before**
the ``TextLayer``. This will ensure that the time is drawn on top of the image,
and not the other way around:

```c
//Create and add the image
g_frame_bitmap = gbitmap_create_with_resource(RESOURCE_ID_FRAME);
g_frame_layer = bitmap_layer_create(GRect(7, 56, 129, 60));
bitmap_layer_set_bitmap(g_frame_layer, g_frame_bitmap);
layer_add_child(window_get_root_layer(window), bitmap_layer_get_layer(g_frame_layer));
```

Once again, remember to add calls to `_destroy()` for each element to free
memory in `window_unload()`:

```c
void window_unload(Window *window)
{
  //We will safely destroy the Window's elements here!
  text_layer_destroy(g_text_layer);

  gbitmap_destroy(g_frame_bitmap);
  bitmap_layer_destroy(g_frame_layer);
}
```

With these steps completed, a re-compile of your project should yield something
similar to that shown below:

![frameadded](/images/blog/tut_2_frame_added.png "frame added")

The ``TextLayer`` is now surrounded by a crisp frame border. It's not amazing,
but it's the start on a journey to a great watchface!

###Conclusion
There you have it: turning your simple watchapp into a basic watchface. In
summary:

1. Modify the App Kind to be a watchface instead of a watchapp.
2. Add a subscription to the ``TickTimerService`` to get the current time.
3. Modify the ``TextLayer`` layout to better suit the task of telling the time.
4. Add an image resource to the project
5. Display that image using a combination of ``GBitmap`` and ``BitmapLayer``.

From there you can add more images, change the text font and size and more to
further improve the look of the watchface. In future posts you will learn how to
use ``Timer``s and ``Animation``s to make it even better!

###Source Code
Just like last time, the full source code file can be found 
[here](https://gist.github.com/C-D-Lewis/17eb11ab355950595ca2) and directly 
imported into CloudPebble 
[as a new project](https://cloudpebble.net/ide/gist/17eb11ab355950595ca2). If 
your code doesn't compile, have a look at this and see where you may have gone 
wrong. 

Send any feedback or questions to [@PebbleDev](http://twitter.com/PebbleDev) or 
[@Chris_DL](http://twitter.com/Chris_DL).


