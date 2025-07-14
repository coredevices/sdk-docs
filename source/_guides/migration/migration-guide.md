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

title: SDK 2.x Migration Guide
description: Migrating Pebble apps from SDK 1.x to SDK 2.x.
permalink: /guides/migration/migration-guide/
generate_toc: true
guide_group: migration
order: 1
---

{% alert important %}
This page is outdated, intended for updating SDK 1.x apps to SDK 2.x. All app
should now be created with SDK 3.x. For migrating an app from SDK 2.x to SDK
3.x, the read {% guide_link migration/migration-guide-3 %}.
{% endalert %}


## Introduction

This guide provides you with a summary and a detailed list of the changes,
updates and new APIs available in Pebble SDK 2.0. To migrate your code successfully
from Pebble SDK 1.x to Pebble SDK 2.x, you should read this guide.

In addition to updated and new Pebble APIs, you'll find updated developer tools
and a simplified build system that makes it easier to create, build, and deploy
Pebble apps.

**Applications written for Pebble SDK 1.x do not work on Pebble 2.0.** It is
extremely important that you upgrade your apps, so that your users can continue
to enjoy your watchfaces and watchapps.

These are the essential steps to perform the upgrade:

* You'll need to upgrade Pebble SDK on your computer, the firmware on your
  Pebble, and the Pebble mobile application on your phone.
* You need to upgrade the `arm-cs-tools`. The version shipped with Pebble SDK 2
  contains several important improvements that help reduce the size of the
  binaries generated and improve the performance of your app.
* You need to upgrade the python dependencies
  `pip install --user -r {{ site.pb_sdk_path }}{{ site.pb_sdk2_package }}/requirements.txt`).

## Discovering the new Pebble tools (Native SDK only)

One of the new features introduced in Pebble native SDK 2.0 is the `pebble` command
line tool. This tool is used to create new apps, build and install those apps on
your Pebble.

The tool was designed to simplify and optimize the build process for your Pebble
watchfaces and watchapps. Give it a try right now:

```c
$ pebble new-project helloworld
$ cd helloworld
$ ls
appinfo.json      resources    src          wscript
```

Notice that the new SDK does not require symlinks as the earlier SDK did. There
is also a new `appinfo.json` file, described in greater detail later in this
guide. The file provides you with a more readable format and includes all the
metadata about your app.

```c
$ pebble build
...

Memory usage:
=============
Total app footprint in RAM:        801 bytes / ~24kb
Free RAM available (heap):       23775 bytes

[12/13] inject-metadata: build/pebble-app.raw.bin build/app_resources.pbpack.data -> build/pebble-app.bin
[13/13] helloworld.pbw: build/pebble-app.bin build/app_resources.pbpack -> build/helloworld.pbw

...

'build' finished successfully (0.562s)
```

You don't need to call the `waf` tool to configure and then build the project
anymore (`pebble` still uses `waf`, however). The new SDK also gives you some
interesting information on how much memory your app will use and how much memory
will be left for you in RAM.

```c
$  pebble install --phone 10.0.64.113 --logs
[INFO    ] Installation successful
[INFO    ] Enabling application logging...
[INFO    ] Displaying logs ... Ctrl-C to interrupt.
[INFO    ] D helloworld.c:58 Done initializing, pushed window: 0x2001a524
```

Installing an app with `pebble` is extremely simple. It uses your phone and the
official Pebble application as a gateway. You do need to configure your phone
first, however. For more information on working with this tool, read
{% guide_link tools-and-resources/pebble-tool %}.

You don't need to run a local HTTP server or connect with Bluetooth like you did
with SDK 1.x. You will also get logs sent directly to the console, which will
make development a lot easier!

## Upgrading a 1.x app to 2.0

Pebble 2.0 is a major release with many changes visible to users and developers
and some major changes in the system that are not visible at first sight but
will have a strong impact on your apps.

Here are the biggest changes in Pebble SDK 2.0 that will impact you when
migrating your app. The changes are discussed in more detail below:

* Every app now requires an `appinfo.json`, which includes your app name, UUID,
  resources and a few other new configuration parameters. For more information,
  refer to {% guide_link tools-and-resources/app-metadata %}.
* Your app entry point is called `main()` and not `pbl_main()`.
* Most of the system structures are not visible to apps anymore, and instead of
  allocating the memory yourself, you ask the system to allocate the memory and
  return a pointer to the structure.

  > This means that you'll have to change most of your system calls and
  > significantly rework your app. This change was required to allow us to
  > update the structs in the future (for example, to add new fields in them)
  > without forcing you to recompile your app code.

* Pebble has redesigned many APIs to follow standard C best practices and
  futureproof the SDK.

### Application metadata

To upgrade your app for Pebble SDK 2.0, you should first run the
`pebble convert-project` command in your existing 1.x project. This will
automatically try to generate the `appinfo.json` file based on your existing
source code and resource file. It will not touch your C code.

Please review your `appinfo.json` file and make sure everything is OK. If it is,
you can safely remove the UUID and the `PBL_APP_INFO` in your C file.

Refer to {% guide_link tools-and-resources/app-metadata %}
for more information on application metadata and the basic structure of an app
in Pebble SDK 2.0.

### Pebble Header files

In Pebble SDK 1.x, you would reference Pebble header files with three include
statements:

```c
#include "pebble_os.h"
#include "pebble_app.h"
#include "pebble_fonts.h"
```

In Pebble SDK 2.x, you can replace them with one statement:

```c
#include <pebble.h>
```

### Initializing your app

In Pebble SDK 1.x, your app was initialized in a `pbl_main()` function:

```c
void pbl_main(void *params) {
  PebbleAppHandlers handlers = {
    .init_handler = &handle_init
  };
  app_event_loop(params, &handlers);
}
```

In Pebble SDK 2.0:

* `pbl_main` is replaced by `main`.
* The `PebbleAppHandlers` structure no longer exists. You call your init and
  destroy handlers directly from the `main()` function.

```c
int main(void) {
  handle_init();
  app_event_loop();
  handle_deinit();
}
```

There were other fields in the `PebbleAppHandlers`:

* `PebbleAppInputHandlers`:
   Use a ``ClickConfigProvider`` instead.
* `PebbleAppMessagingInfo`: Refer to the section below on ``AppMessage``
 changes.
* `PebbleAppTickInfo`: Refer to the section below on Tick events.
* `PebbleAppTimerHandler`: Refer to the section below on ``Timer`` events.
* `PebbleAppRenderEventHandler`: Use a ``Layer`` and call
  ``layer_set_update_proc()`` to provide your own function to render.

### Opaque structures and Dynamic Memory allocation

In Pebble SDK 2.0, system structures are opaque and your app can't directly
allocate memory for them. Instead, you use system functions that allocate memory
and initialize the structure at the same time.

#### Allocating dynamic memory: A simple example

In Pebble SDK 1.x, you would allocate memory for system structures inside your
app with static global variables. For example, it was very common to write:

```c
Window my_window;
TextLayer text_layer;

void handle_init(AppContextRef ctx) {
  window_init(&my_window, "My App");
  text_layer_init(&text_layer, GRect(0, 0, 144, 20));
}
```

In Pebble SDK 2, you can't allocate memory statically in your program because
the compiler doesn't know at compile time how big the system structures are
(here, in the above code snippet ``Window`` and ``TextLayer``). Instead, you use
pointers and ask the system to allocate the memory for you.

This simple example becomes:

```c
Window *my_window;
TextLayer *text_layer;

void handle_init(void) {
  my_window = window_create();

  text_layer = text_layer_create(GRect(0, 0, 144, 20));
}
```

Instead of using `*_init()` functions and passing them a pointer to the structure,
in SDK 2.0, you call functions that end in `_create()`, and these functions will
allocate memory and return to your app a pointer to a structure that is
initialized.

Because the memory is dynamically allocated, it is extremely important that you
release that memory when you are finished using the structure. This can be done
with the `*_destroy()` functions. For our example, we could write:

```c
void handle_deinit(void) {
  text_layer_destroy(text_layer);
  window_destroy(my_window);
}
```

#### Dynamic memory: General rules in Pebble SDK 2.0

* Replace all statically allocated system structures with a pointer to the
  structure.
* Replace functions that ended in `_init()` with their equivalent that end in
  `_create()`.
* Keep pointers to the structures that you have initialized. Call the
  `*_destroy()` functions to release the memory.

### AppMessage changes

 * Instead of defining your buffer sizes in `PebbleAppMessagingInfo`, you pass
   them to ``app_message_open()``
 * Instead of using a `AppMessageCallbacksNode` structure and
   `app_message_register_callbacks()`, you register handler for the different
   ``AppMessage`` events with:
   * ``app_message_register_inbox_received()``
   * ``app_message_register_inbox_dropped()``
   * ``app_message_register_outbox_failed()``
   * ``app_message_register_outbox_sent()``
   * ``app_message_set_context(void *context)``: To set the context that will be
     passed to all the handlers.

* `app_message_out_get()` is replaced by ``app_message_outbox_begin()``.
* `app_message_out_send()` is replaced by ``app_message_outbox_send()``.
* `app_message_out_release()` is removed. You do not need to call this anymore.

For more information, please review the ``AppMessage`` API Documentation.

For working examples using AppMessage and AppSync in SDK 2.0, refer to:

 * `{{ site.pb_sdk2_package }}/PebbleSDK-2.x/Examples/pebblekit-js/quotes`:
   Demonstrates how to use PebbleKit JS to fetch price quotes from the web.
   It uses AppMessage on the C side.
 * `{{ site.pb_sdk2_package }}/PebbleSDK-2.x/Examples/pebblekit-js/weather`:
   A PebbleKit JS version of the traditional `weather-demo` example. It uses
   AppSync on the C side.

### Dealing with Tick events

Callbacks for tick events can't be defined through `PebbleAppHandlers` anymore.
Instead, use the Tick Timer Event service with:
``tick_timer_service_subscribe()``.

For more information, read {% guide_link events-and-services/events %}/

### Timer changes

`app_timer_send_event()` is replaced by ``app_timer_register()``.

For more information, refer to the ``Timer`` API documentation.

### WallTime API changes

* `PblTm` has been removed and replaced by the libc standard struct. Use struct
  `tm` from `#include <time.h>`.

* `tm string_format_time()` function is replaced by ``strftime()``.

* `get_time()` is replaced by `localtime(time(NULL))`. This lets you convert a
  timestamp into a struct.

* Pebble OS does not, as yet, support timezones. However, Pebble SDK 2
  introduces `gmtime()` and `localtime()` functions to prepare for timezone
  support.


### Click handler changes

In SDK 1.x, you would set up click handlers manually by modifying an array of
config structures to contain the desired configuration. In SDK 2.x, how click
handlers are registered and used has changed.

The following functions for subscribing to events have been added in SDK 2.x:

```c
void window_set_click_context();
void window_single_click_subscribe();
void window_single_repeating_click_subscribe();
void window_multi_click_subscribe();
void window_multi_click_subscribe();
void window_long_click_subscribe();
void window_raw_click_subscribe();
```

For more information, refer to the ``Window`` API documentation.

For example, in SDK 1.x you would do this:

```c
void click_config_provider(ClickConfig **config, void *context) {
  config[BUTTON_ID_UP]->click.handler = up_click_handler;
  config[BUTTON_ID_UP]->context = context;
  config[BUTTON_ID_UP]->click.repeat_interval_ms = 100;

  config[BUTTON_ID_SELECT]->click.handler = select_click_handler;

  config[BUTTON_ID_DOWN]->multi_click.handler = down_click_handler;
  config[BUTTON_ID_DOWN]->multi_click.min = 2;
  config[BUTTON_ID_DOWN]->multi_click.max = 10;
  config[BUTTON_ID_DOWN]->multi_click.timeout = 0; /* default timeout */
  config[BUTTON_ID_DOWN]->multi_click.last_click_only = true;

  config[BUTTON_ID_SELECT]->long_click.delay_ms = 1000;
  config[BUTTON_ID_SELECT]->long_click.handler = select_long_click_handler;
}
```

In SDK 2.x, you would use the following calls instead:

```c
void click_config_provider(void *context) {
  window_set_click_context(BUTTON_ID_UP, context);
  window_single_repeating_click_subscribe(BUTTON_ID_UP, 100, up_click_handler);

  window_single_click_subscribe(BUTTON_ID_SELECT, select_click_handler);

  window_multi_click_subscribe(BUTTON_ID_DOWN, 2, 10, 0, true, down_click_handler);

  window_long_click_subscribe(BUTTON_ID_SELECT, 1000, select_long_click_handler, NULL /* No handler on button release */);
}
```

Notice that the signature of ``ClickConfigProvider`` has also changed. These
``Clicks`` API functions **must** be called from within the
ClickConfigProvider function. If they are not, your app code will fail.

### Other changes

* `graphics_text_draw()` has been renamed to ``graphics_draw_text()``, matching
  the rest of Pebble's graphics_draw_ functions. There are no changes with the
  usage of the function.

## Quick reference for the upgrader

**Table 1. API changes from SDK 1.x to 2.x**

   API Call in SDK 1.x   |    API Call in SDK 2.x     |
:-----------|:------------|
 `#define APP_TIMER_INVALID_HANDLE ((AppTimerHandle)0)` | Changed. No longer needed; `app_timer_register()` always succeeds. See [``Timer``.
 `#define INT_MAX 32767`      | Changed. See `#include <limits.h>`
 `AppTimerHandle app_timer_send_event();` | See ``app_timer_register()`` for more information at ``Timer``.
 `ARRAY_MAX`      | Removed from Pebble headers. Now use limits.h
 `bool app_timer_cancel_event();`      | Changed. See ``app_timer_cancel()`` for more information at ``Timer``.
 `GContext *app_get_current_graphics_context();`      | Removed. Use the context supplied to you in the drawing callbacks.
 `GSize text_layer_get_max_used_size();`      | Use ``text_layer_get_content_size()``. See ``TextLayer``.
 `INT_MAX`      | Removed from Pebble headers. Now use limits.h
 `void get_time();`      | Use `localtime(time(NULL))` from `#include <time.h>`.
 `void resource_init_current_app();`      | No longer needed.
 `void string_format_time();`      | Use ``strftime`` from `#include <time.h>`.
 `void window_render();`      | No longer available.

### Using `*_create()/*_destroy()` instead of `*_init()/*_deinit()` functions

If you were using the following `_init()/_deinit()` functions, you should now
use `*_create()/*_destroy()` instead when making these calls:

* `bool rotbmp_init_container();` See ``BitmapLayer``.
* `bool rotbmp_pair_init_container();` ``BitmapLayer``.
* `void action_bar_layer_init();` See ``ActionBarLayer``.
* `void animation_init();` See ``Animation``.
* `void bitmap_layer_init();` ``BitmapLayer``.
* `void gbitmap_init_as_sub_bitmap();` See [Graphics Types](``Graphics Types``).
* `void gbitmap_init_with_data();` See [Graphics Types](``Graphics Types``).
* `void inverter_layer_init();` Now `InverterLayer` (deprecated in SDK 3.0).
* `void layer_init();` See ``Layer``.
* `void menu_layer_init();` See ``MenuLayer``.
* `void number_window_init();`
* `void property_animation_init_layer_frame();` See ``Animation``.
* `void property_animation_init();` See ``Animation``.
* `void rotbmp_deinit_container();` ``BitmapLayer``.
* `void rotbmp_pair_deinit_container();` ``BitmapLayer``.
* `void scroll_layer_init();` See ``ScrollLayer``.
* `void simple_menu_layer_init();` See ``SimpleMenuLayer``.
* `void text_layer_deinit();` See ``TextLayer``.
* `void text_layer_init();` See ``TextLayer``.
* `void window_deinit();` See ``Window``.
* `void window_init();` See ``Window``.
