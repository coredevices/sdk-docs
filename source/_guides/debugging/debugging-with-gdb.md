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

title: Debugging with GDB
description: |
  How to use GDB to debug a Pebble app in the emulator.
guide_group: debugging
order: 0
---

As of SDK 3.10 (and [Pebble Tool](/guides/tools-and-resources/pebble-tool) 4.2),
developers can use the powerful [GDB](https://www.gnu.org/software/gdb/)
debugging tool to find and fix errors in Pebble apps while they are running in
an emulator. GDB allows the user to observe the state of the app at any point in
time, including the value of global and local variables, as well as current
function parameters and a backtrace. Strategically placing breakpoints and
observing these values can quickly reveal the source of a bug.

{% alert notice %}
GDB cannot be used to debug an app running on a real watch.
{% endalert %}


## Starting GDB

To begin using GDB, start an emulator and install an app:

```text
$ pebble install --emulator basalt
```

Once the app is installed, begin using GDB:

```text
$ pebble gdb --emulator basalt
```

Once the `(gdb)` prompt appears, the app is paused by GDB for observation. To
resume execution, use the `continue` (or `c`) command. Similarly, the app can be
paused for debugging by pressing `control + c`.

```text
(gdb) c
Continuing.
```

A short list of useful commands (many more are available) can be also be
obtained from the `pebble` tool. Read the 
[*Emulator Interaction*](/guides/tools-and-resources/pebble-tool/#gdb) 
section of the {% guide_link tools-and-resources/pebble-tool %} guide for more
details on this list.

```text
$ pebble gdb --help
```


## Observing App State

To see the value of variables and parameters at any point, set a breakpoint
by using the `break` (or `b`) command and specifying either a function name, or
file name with a line number. For example, the snippet below shows a typical
``TickHandler`` implementation with line numbers in comments:

```c
/* 58 */  static void tick_handler(struct tm *tick_time, TimeUnits changed) {
/* 59 */    int hours = tick_time->tm_hour;
/* 60 */    int mins = tick_time->tm_min;
/* 61 */
/* 62 */    if(hours < 10) {
/* 63 */      /* other code */
/* 64 */    }
/* 65 */  }
```

To observe the values of `hours` and `mins`, a breakpoint is set in this file at
line 61:

```text
(gdb) b main.c:61
Breakpoint 2 at 0x200204d6: file ../src/main.c, line 61.
```

> Use `info break` to see a list of all breakpoints currently registered. Each
> can be deleted with `delete n`, where `n` is the breakpoint number.

With this breakpoint set, use the `c` command to let the app continue until it
encounters the breakpoint:

```text
$ c
Continuing.
```

When execution arrives at the breakpoint, the next line will be displayed along
with the state of the function's parameters:

```text
Breakpoint 2, tick_handler (tick_time=0x20018770, units_changed=(SECOND_UNIT | MINUTE_UNIT))
    at ../src/main.c:62
62    if(hours < 10) {
```

The value of `hours` and `mins` can be found using the `info locals` command:

```text
(gdb) info locals
hours = 13
mins = 23
```

GDB can be further used here to view the state of variables using the `p`
command, such as other parts of the `tm` object beyond those being used to
assign values to `hours` and `mins`. For example, the day of the month:

```text
(gdb) p tick_time->tm_mday
$2 = 14
```

A backtrace can be generated that describes the series of function calls that
got the app to the breakpoint using the `bt` command:

```text
(gdb) bt
#0  segment_logic (this=0x200218a0) at ../src/drawable/segment.c:18
#1  0x2002033c in digit_logic (this=0x20021858) at ../src/drawable/digit.c:141
#2  0x200204c4 in pge_logic () at ../src/main.c:29
#3  0x2002101a in draw_frame_update_proc (layer=<optimized out>, ctx=<optimized out>)
    at ../src/pge/pge.c:190
#4  0x0802627c in ?? ()
#5  0x0805ecaa in ?? ()
#6  0x0801e1a6 in ?? ()
#7  0x0801e24c in app_event_loop ()
#8  0x2002108a in main () at ../src/pge/pge.c:34
#9  0x080079de in ?? ()
#10 0x00000000 in ?? ()
```

> Lines that include '??' denote a function call in the firmware. Building the
> app with `pebble build --debug` will disable some optimizations and can
> produce more readable output from GDB. However, this can increase code size
> which may break apps that are pushing the heap space limit.


## Fixing a Crash

When an app is paused for debugging, the developer can manually advance each
statement and precisely follow the path taken through the code and observe how
the state of each variable changes over time. This is very useful for tracking
down bugs caused by unusual input to functions that do not adequately check
them. For example, a `NULL` pointer.

The app code below demonstrates a common cause of an app crash, caused by a
misunderstanding of how the ``Window`` stack works. The ``TextLayer`` is created
in the `.load` handler, but this is not called until the ``Window`` is pushed
onto the stack. The attempt to set the time to the ``TextLayer`` by calling
`update_time()` before it is displayed will cause the app to crash.

```c
#include <pebble.h>

static Window *s_window;
static TextLayer *s_time_layer;

static void window_load(Window *window) {
  Layer *window_layer = window_get_root_layer(window);
  GRect bounds = layer_get_bounds(window_layer);

  s_time_layer = text_layer_create(bounds);
  text_layer_set_text(s_time_layer, "00:00");
  text_layer_set_text_alignment(s_time_layer, GTextAlignmentCenter);
  layer_add_child(window_layer, text_layer_get_layer(s_time_layer));
}

static void update_time() {
  time_t now = time(NULL);
  struct tm *tick_time = localtime(&now);

  static char s_buffer[8];
  strftime(s_buffer, sizeof(s_buffer), "%H:%M", tick_time);
  text_layer_set_text(s_time_layer, s_buffer);
}

static void init() {
  s_window = window_create();
  window_set_window_handlers(s_window, (WindowHandlers) {
    .load = window_load
  });

  update_time();

  window_stack_push(s_window, true);
}

static void deinit() {
  window_destroy(s_window);
}

int main() {
  init();
  app_event_loop();
  deinit();
}
```

Supposing the cause of this crash was not obvious from the order of execution,
GDB can be used to identify the cause of the crash with ease. It is known that
the app crashes on launch, so the first breakpoint is placed at the beginning of
`init()`. After continuing execution, the app will pause at this location:

```text
(gdb) b init
Breakpoint 2 at 0x2002010c: file ../src/main.c, line 26.
(gdb) c
Continuing.

Breakpoint 2, main () at ../src/main.c:41
41    init();
```

Using the `step` command (or Enter key), the developer can step through all the
statements that occur during app initialization until the crash is found (and
the `app_crashed` breakpoint is encountered. Alternatively, `bt full` can be
used after the crash occurs to inspect the local variables at the time of the
crash:

```text
(gdb) c
Continuing.

Breakpoint 1, 0x0804af6c in app_crashed ()
(gdb) bt full
#0  0x0804af6c in app_crashed ()
No symbol table info available.
#1  0x0800bfe2 in ?? ()
No symbol table info available.
#2  0x0800c078 in ?? ()
No symbol table info available.
#3  0x0804c306 in ?? ()
No symbol table info available.
#4  0x080104f0 in ?? ()
No symbol table info available.
#5  0x0804c5c0 in ?? ()
No symbol table info available.
#6  0x0805e6ea in text_layer_set_text ()
No symbol table info available.
#7  0x20020168 in update_time () at ../src/main.c:22
        now = 2076
        tick_time = <optimized out>
        s_buffer = "10:38\000\000"
#8  init () at ../src/main.c:31
No locals.
#9  main () at ../src/main.c:41
No locals.
#10 0x080079de in ?? ()
No symbol table info available.
#11 0x00000000 in ?? ()
No symbol table info available.
```

The last statement to be executed before the crash is a call to
`text_layer_set_text()`, which implies that one of its input variables was bad.
It is easy to determine which by printing local variable values with the `p`
command:

```text
Breakpoint 4, update_time () at ../src/main.c:22
22    text_layer_set_text(s_time_layer, s_buffer);
(gdb) p s_time_layer
$1 = (TextLayer *) 0x0 <__pbl_app_info>
```

In this case, GDB displays `0x0` (`NULL`) for the value of `s_time_layer`, which
shows it has not yet been allocated, and so will cause `text_layer_set_text()`
to crash. And thus, the source of the crash has been methodically identified. A
simple fix here is to swap `update_time()` and ``window_stack_push()`` around so
that `init()` now becomes:

```c
static void init() {
  // Create a Window
  s_window = window_create();
  window_set_window_handlers(s_window, (WindowHandlers) {
    .load = window_load
  });

  // Display the Window
  window_stack_push(s_window, true);

  // Set the time
  update_time();
}
```

In this new version of the code the ``Window`` will be pushed onto the stack,
calling its `.load` handler in the process, and the ``TextLayer`` will be
allocated and available for use once execution subsequently reaches
`update_time()`.
