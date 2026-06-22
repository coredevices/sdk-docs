---
# Copyright 2026 Core Devices LLC
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

title: Debugging Alloy Apps with xsbug
description: |
  Use the xsbug JavaScript debugger to set breakpoints and inspect your Alloy
  app while it runs on the watch.
guide_group: debugging
order: 4
---

Alloy apps run on Moddable's XS JavaScript engine, which ships with a graphical
source-level debugger called **xsbug**. With xsbug you can set breakpoints, step
through JavaScript, inspect variables, and watch `console.log` / `trace` output
while your app runs on a watch or in the emulator.

> **Platform Support**: Alloy and xsbug debugging are available on Emery
> (Pebble Time 2) and Gabbro (Pebble Time 2 round). This requires
> `pebble-tool` 5.0.38 or later.

## Building a Debug Build

xsbug can only attach to an app that was built in debug mode. Build your
project with the `--debug` flag:

```text
$ pebble build --debug
```

A debug build:

- compiles your C code without optimizations (`-O0`) for easier stepping;
- defines `PBL_DEBUG`, which the Alloy entry point (`src/c/mdbl.c`) uses to set
  `kModdableCreationFlagDebug` and enable the xsbug connection; and
- produces a separate `<app>_debug.pbw` bundle, so your debug and release
  builds can coexist.

> **Note**: A debug build is larger and runs more slowly than a release build,
> and may not fit on memory-constrained apps. Build without `--debug` for
> normal testing and release.

## Launching the Debugger

When you install a `--debug` build, the Pebble tool automatically launches
xsbug, opens your `src/embeddedjs` folder so breakpoints map to your source,
and bridges the JavaScript debugger over the connection *before* the app boots
- so the debugger is attached as soon as your code starts running:

```text
$ pebble install --emulator emery
Launching xsbug JavaScript debugger...
```

The same happens for `pebble logs`, which also prefers the `_debug` bundle when
one is present.

xsbug ships in the active SDK's `moddable-tools` directory and is started for
you. If the tool can't find it, it prints a warning - launch xsbug manually and
re-run the install so the debugger can connect.

## Using xsbug

Once connected, xsbug shows your running app. From its interface you can:

- set and clear **breakpoints** by clicking in the gutter of a source file;
- **step** over, into, and out of functions, and continue execution;
- inspect the **call stack**, **local variables**, and **global** state; and
- view **`console.log`** and **`trace`** output in the messages pane.

For a full tour of the debugger, see the
[Moddable xsbug documentation](https://www.moddable.com/documentation/xs/xsbug).

## See Also

- {% guide_link debugging/debugging-with-app-logs %} - viewing log output
- {% guide_link alloy/getting-started %} - getting started with Alloy
