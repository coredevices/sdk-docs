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

title: Introducing App Debugging
author: katharine
tags:
- Freshly Baked
---

Happy leap day! Today is a once-every-four-years day of bizarre date-related
bugs, and thus an opportune moment for us to introduce our latest developer
feature: app debugging in the emulator! This gives you a powerful new way to
hunt down errors in your apps.




A new command is available in our preview release of pebble tool 4.2 and
SDK 3.10: `pebble gdb`.
Running this command from a project directory on an emulator with your app
installed will pause the emulator and attach a gdb debugger instance
to it:

```nc|text
katharine@scootaloo ~/p/pebble-caltrain (master)> pebble gdb --emulator basalt
Reading symbols from /Users/katharine/Library/Application Support/Pebble SDK/SDKs/3.10-beta4/sdk-core/pebble/basalt/qemu/basalt_sdk_debug.elf...(no debugging symbols found)...done.
Remote debugging using :49229
0x0801cd8c in ?? ()
add symbol table from file "/Users/katharine/projects/pebble-caltrain/build/basalt/pebble-app.elf" at
	.text_addr = 0x200200a8
	.data_addr = 0x20023968
	.bss_addr = 0x200239b8
Reading symbols from /Users/katharine/projects/pebble-caltrain/build/basalt/pebble-app.elf...done.
Breakpoint 1 at 0x804aebc

Press ctrl-D or type 'quit' to exit.
Try `pebble gdb --help` for a short cheat sheet.
Note that the emulator does not yet crash on memory access violations.
(gdb) 
```

Do note that once we pause execution by launching gdb, emulator buttons and
any pebble tool command that interacts with the emulator won't work until we
continue execution (using `continue` or `c`) or quit gdb.

Once we're here, we can add some breakpoints to the app in interesting places.
Here we are debugging my
[Caltrain app](https://github.com/Katharine/pebble-caltrain). Let's say I think
there's a bug in the search for the next train: I probably want to poke around
in [`find_next_train`](https://github.com/Katharine/pebble-caltrain/blob/f4983c748429127a8af85911cb123bd8c3bacb73/src/planning.c#L4).
We can run `b find_next_train` to add a breakpoint there:

```nc|text
(gdb) b find_next_train
Breakpoint 2 at 0x20020f1e: file ../src/planning.c, line 5.
(gdb) 
```

Now we can use the `c` or `continue` command to set my app running again, until
it stops at `find_next_train`:

```nc|text
(gdb) c
Continuing.
```

The app runs as usual until we open a station, which causes it to look up a
train, where it hits the breakpoint and pauses the app so we can inspect it:

```nc|text
Breakpoint 2, find_next_train (count=184, times=0x2002f414, nb=0x2001873c, 
    sb=0x20018738) at ../src/planning.c:5
5	  TrainTime *best[2] = {NULL, NULL};
(gdb) 
```

Now we can see how we got here using the `backtrace` or `bt` command:

```nc|text
(gdb) bt
#0  find_next_train (count=184, times=0x2002f414, nb=0x2001873c, sb=0x20018738)
    at ../src/planning.c:7
#1  0x200211b2 in next_train_at_station (station=13 '\r', 
    northbound=0x20025a0c <s_northbound>, southbound=0x20025a14 <s_southbound>)
    at ../src/planning.c:76
#2  0x200215c8 in prv_update_times () at ../src/stop_info.c:106
#3  0x200216f8 in show_stop_info (stop_id=13 '\r') at ../src/stop_info.c:174
#4  0x200219f0 in prv_handle_menu_click (menu_layer=0x2002fe3c, 
    cell_index=0x2002ff0c, context=0x2002fe3c) at ../src/stop_list.c:57
#5  0x0805cb1c in ?? ()
#6  0x0805a962 in ?? ()
#7  0x0801ebca in ?? ()
#8  0x0801e1fa in ?? ()
#9  0x200202d6 in main () at ../src/main.c:23
#10 0x080079de in ?? ()
#11 0x00000000 in ?? ()
```

The `??` entries are inside the pebble firmware; the rest are in the Caltrain
app.
We can step forward a few times to get to an interesting point using the `step`
or `s` command:

```nc|text
(gdb) s
7	  const time_t timestamp = time(NULL);
(gdb) s
8	  const uint16_t minute = current_minute();
(gdb) s
current_minute () at ../src/model.c:183
183	  const time_t timestamp = time(NULL);
(gdb) 
```

Now we've stepped into another function, `current_minute`. Let's say we're
confident in the implementation of this (maybe we wrote unit tests), so we can
jump back up to `find_next_train` using the `finish` command:

```nc|text
(gdb) finish
Run till exit from #0  current_minute () at ../src/model.c:183
0x20020f38 in find_next_train (count=184, times=0x2002f414, nb=0x2001873c, 
    sb=0x20018738) at ../src/planning.c:8
8	  const uint16_t minute = current_minute();
Value returned is $2 = 738
(gdb) 
```

When we step to the next line, we see it has a similar `current_day` that we
don't need to inspect closely, so we jump over it using the `next` or `n`
command:

```nc|text
(gdb) s
9	  const uint8_t day = current_day();
(gdb) n
11	  for(int i = 0; i < count; ++i) {
(gdb) 
```

Now we can double check our current state by using `info locals` to look at all
our local variables, and `info args` to look at what was originally passed in:

```nc|text
(gdb) info locals
i = 184
best = {0x0 <__pbl_app_info>, 0x0 <__pbl_app_info>}
timestamp = 1456776942
minute = 738
day = 1 '\001'
(gdb) info args
count = 184
times = 0x2002f414
nb = 0x2001873c
sb = 0x20018738
(gdb)
```

`timestamp`, `minute` and `day` all have the values they gained from our last
few function calls. `best` is still a pair of NULL pointers, and `i` hasn't been
assigned yet, so its value is garbage. Once we step another line it'll be filled
in, which we can check using the `print` or `p` command:

```nc|text
(gdb) s
12	    TrainTime *train_time = &amp;times[i];
(gdb) p i
$3 = 0
```

Now let's step forward and have it fill in `train_time`, and see what we get:

```nc|text
(gdb) s
14	    trip_get(train_time->trip, &amp;trip);
(gdb) p train_time
$4 = (TrainTime *) 0x2002f414
(gdb) 
```

This is unenlightening — it's just the same pointer as `times`, which is what we
expect when referencing `&times[0]`. Fortunately, `print`/`p` will evaluate
arbitrary expressions, so we can dereference the pointer to see what it actually
points at:

```nc|text
(gdb) p *train_time
$5 = {trip = 189, time = 309, stop = 13 '\r', sequence = 10 '\n'}
(gdb) 
```

Better! It might be more interesting to just print that out for each loop
iteration, so let's set a breakpoint here and have it print `*train_time`
and continue:

```nc|text
(gdb) b
Breakpoint 3 at 0x20020f62: file ../src/planning.c, line 14.
(gdb) commands
Type commands for breakpoint(s) 3, one per line.
End with a line saying just "end".
>p *train_time
>c
>end
(gdb) c
Continuing.

Breakpoint 3, find_next_train (count=184, times=0x2002f414, nb=0x2001873c, 
    sb=0x20018738) at ../src/planning.c:14
14	    trip_get(train_time->trip, &amp;trip);
$6 = {trip = 209, time = 344, stop = 13 '\r', sequence = 11 '\v'}

Breakpoint 3, find_next_train (count=184, times=0x2002f414, nb=0x2001873c, 
    sb=0x20018738) at ../src/planning.c:14
14	    trip_get(train_time->trip, &amp;trip);
$7 = {trip = 199, time = 345, stop = 13 '\r', sequence = 13 '\r'}
```
…and so on. A bit noisy, so let's remove that breakpoint now:

```nc|text
(gdb) delete 3
(gdb)
```

Finally, let's have our program continue on its way by running `c` again:

```nc|text
(gdb) c
Continuing
```

When we want to get out of gdb we'll need our `(gdb)` prompt back, so press
ctrl-C to pause the app again:

```nc|text
^C
Program received signal SIGINT, Interrupt.
0x08007072 in ?? ()
(gdb) 
```

This will most likely pause execution inside some firmware code, as we did when
we initially launched gdb. We can now do anything we've done before, but we're
just going to quit:

```nc|text
(gdb) quit
A debugging session is active.

	Inferior 1 [Remote target] will be killed.

Quit anyway? (y or n) y
katharine@scootaloo ~/p/pebble-caltrain (master)>
```

Hopefully this has given you some ideas as to how you might be able to use gdb
to debug your own apps. If you'd like to know more about gdb,
[here is a Q&A-style tutorial](http://www.unknownroad.com/rtfm/gdbtut/) that
will answer many questions you might have. Good luck and happy debugging!
