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

layout: pebbleos/default
title: Exposing APIs to the SDK
description: |
  How a firmware function becomes a Pebble SDK API, and how the change
  reaches app developers and the C API reference on this site.
permalink: /pebbleos/exposing-apis/
generate_toc: true
search_index: true
search_group: PebbleOS
---

Watchapps do not link against the firmware. The firmware build generates the
app SDK from its own sources, so a new function in `fw/applib` is not visible
to apps until it is registered for export and the SDK revision is bumped.
This page summarises the process; the imported
[Exposing functions to the SDK](/pebbleos/docs/development/sdk_export/) page
is the full description and the one to follow when making the change.


## What Changes Together

Three edits make a function available to apps:

* Implement the function in the matching `fw/applib/.../<area>.c` and `.h`,
  declare its `sys_*` syscall in `fw/syscall/syscall.h`, and define the
  syscall with `DEFINE_SYSCALL`.
* Register the symbol in `tools/generate_native_sdk/exported_symbols.json`
  under the matching group, with an `addedRevision` equal to the new SDK
  revision.
* Increment `PROCESS_INFO_CURRENT_SDK_VERSION_MINOR` in
  `fw/process_management/pebble_process_info.h` and add a ledger comment
  above it in the existing format, with a `rev` that matches
  `addedRevision`.

The symbol list is the ABI. Functions are ordered by `addedRevision`, so a new
function always goes in a new revision and firmware stays compatible with apps
built against an older `libpebble.a`. The generator fails on exports it cannot
find in the headers and on inconsistent revision numbers, but it does not
compile the resulting `pebble.h`.

{% alert important %}
Exports cannot be added to a firmware and SDK combination that has already
been released. An app built against a newer SDK calls a trampoline that
indexes past the end of an older firmware's function table. New exports ship
as a new firmware together with a new SDK build.
{% endalert %}


## What the Generator Produces

`tools/generate_native_sdk/generate_pebble_native_sdk_files.py` runs as part
of the normal firmware build and writes:

* `build/sdk/<platform>/include/pebble.h`, the declarations apps compile
  against, plus `pebble_worker.h` and the version and font headers.
* `build/sdk/<platform>/lib/libpebble.a`, trampolines that call the exported
  functions through the function table in flash.
* `build/fw/pebble.auto.c`, the `g_pbl_system_tbl` table of function pointers
  compiled into the firmware image.

`pbl build sdk` adds the rest of the distribution: the project templates, the
resource pipeline and the `waf` binary app developers build with.


## How a Change Reaches Developers

* The change is merged to pebbleos `main` and included in a firmware release
  tag. Watches receive the firmware through the Pebble mobile app.
* The SDK built from that release is what `pebble sdk install` downloads.
  Apps that call the new function need that SDK, and the watch needs that
  firmware or a later one.
* The C API reference at [/docs/c/](/docs/c/) is generated from the pebbleos
  tag recorded in the `EMERY_SDK_VERSION` file of the
  [sdk-docs repository]({{ site.links.site_repo }}). The function appears
  there once that file moves to a tag that contains the change.

Documentation for the new function lives in its header comment, which
Doxygen turns into the reference entry. Group it with the `@addtogroup`
blocks around the existing functions so it lands in the right section of the
reference.
