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
title: PebbleOS
description: |
  What PebbleOS is, which watches it runs on, how it relates to the SDK and
  the Pebble mobile app, and where the firmware documentation starts.
permalink: /pebbleos/
generate_toc: true
search_index: true
search_group: PebbleOS
---

PebbleOS is the firmware that runs on Pebble watches. Its source is developed
in the open at [github.com/coredevices/pebbleos](https://github.com/coredevices/pebbleos)
under the Apache License 2.0. This section of the site is for developers who
want to build, run or change the firmware itself. To write watchapps and
watchfaces, start with [Installing the Pebble SDK](/sdk/) and the
[Guides](/guides/) instead.

The pages under [PebbleOS documentation](#where-the-documentation-starts) are
generated from the `docs/` directory of the pebbleos repository on every build
of this site, from the `main` branch. The same content is published at
[pebbleos-core.readthedocs.io](https://pebbleos-core.readthedocs.io). Each
imported page ends with the PebbleOS commit it was generated from and a link to
its source file.


## Start Here

The steps below take a build from nothing to running in the emulator and
installed on a watch. Each step links to the imported page that covers it, so
the instructions themselves come from the pebbleos repository.

<!-- A pebbleos pull request adds a single quickstart page under
     docs/development/. Once that page is imported, this list can collapse
     to one link to it. -->

1. Set up the build environment.
   [Prerequisites](/pebbleos/docs/development/getting_started/#prerequisites)
   installs the
   [PebbleOS SDK](/pebbleos/docs/development/getting_started/#pebbleos-sdk)
   toolchain bundle and the
   [system packages](/pebbleos/docs/development/getting_started/#system-level-dependencies),
   then [gets the source](/pebbleos/docs/development/getting_started/#get-the-source-code)
   with its submodules and installs the
   [Python dependencies](/pebbleos/docs/development/getting_started/#python-dependencies).
2. Configure and build for an emulator board.
   [Build](/pebbleos/docs/development/qemu/#build) on the QEMU page runs
   `pbl configure --board qemu_flint` and `pbl build`.
   [Choosing your target](/pebbleos/docs/development/options/#choosing-your-target)
   lists the boards and revisions `pbl configure` accepts.
3. Run the build. [Run](/pebbleos/docs/development/qemu/#run) starts the
   emulator with `pbl qemu`, and
   [Install PBW applications](/pebbleos/docs/development/qemu/#install-pbw-applications)
   installs an app into it with the `pebble` tool.
4. Configure and build again for the board of your watch, from the table
   under [Boards](#boards), and install it.
   [Loading firmware via Bluetooth](/pebbleos/docs/development/building_fw/#loading-firmware-via-bluetooth)
   bundles a `.pbz` with `pbl bundle` and sideloads it from the Pebble mobile
   app. This is the route for a sealed watch.
   [Loading firmware with a firmware development kit](/pebbleos/docs/development/building_fw/#loading-firmware-with-a-firmware-development-kit)
   flashes a board with its debug connector exposed using `pbl flash`.

Read [Installing a Custom Build](#installing-a-custom-build) before step 4.


## Installing a Custom Build

{% alert important %}
A custom build can leave the watch unable to boot. The causes seen most often:

* Flashing a build configured for a different board. `pbl flash` writes
  whatever the build directory was configured for and does not check the
  board it is connected to. Over Bluetooth, the Pebble mobile app refuses a
  `.pbz` whose `hwrev` does not match the watch. `pebble fw install` prints
  the `hwrev` but does not check it.
* Erasing the bootloader or PRF. `pbl flash` writes only the firmware image,
  but `pbl erase` erases the start of the bootloader with the openocd runner
  and the whole flash with the sftool runner. PRF can also be replaced over
  Bluetooth with a bundle built with `--variant prf`; a PRF that does not run
  removes the fallback.
* Firmware and system resources from different builds. On a firmware
  development kit the resources are flashed separately, with
  `pbl flash --resources` or `pbl image_resources`. Firmware that finds its
  resources missing or corrupt reboots into PRF.
* A build that crashes or hangs before Bluetooth is up, so the phone cannot
  send a new firmware to it.
* Interrupting `pbl flash`, which leaves a partial image in the firmware
  slot. An interrupted Bluetooth update does not: the image is staged in a
  separate slot and is only marked for installation once both the firmware
  and the resources have arrived.
{% endalert %}

When a firmware fails to start, the bootloader records the attempt in the
boot bits and after repeated failures boots PRF instead. From PRF the Pebble
mobile app installs a firmware again. To get to PRF by hand, hold *Back*,
*Up* and *Select* together for five seconds, or run `pebble fw enter-prf`.
[Recovery Firmware](/pebbleos/contributing/#recovery-firmware) has the
details.

If the bootloader or PRF has been erased, the watch can only be programmed
through its debug connector: over SWD with openocd on Pebble 2 Duo, and over
the serial adapter with sftool, which does not depend on the bootloader, on
Pebble Time 2 and Pebble Round 2. A sealed watch has no accessible debug
connector; a
[firmware development kit](/pebbleos/contributing/#the-firmware-development-kit)
does.


## Boards

The firmware is configured for one board at a time with
`pbl configure --board <board>`. The repository at `main` defines these boards:

| Board | Watch | Platform | SoC |
|-------|-------|----------|-----|
| `asterix` | Pebble 2 Duo | flint | Nordic nRF52840 |
| `obelix` | Pebble Time 2 | emery | SiFli SF32LB52 |
| `getafix` | Pebble Round 2 | gabbro | SiFli SF32LB52 |
| `qemu_flint` | Emulator | flint | QEMU, Cortex-M4 |
| `qemu_emery` | Emulator | emery | QEMU, Cortex-M33 |
| `qemu_gabbro` | Emulator | gabbro | QEMU, Cortex-M33 |

The platform column is the name the SDK uses for the same hardware, for
example in `targetPlatforms` in `package.json`. The
{% guide_link tools-and-resources/hardware-information "Hardware Information" %}
guide lists what each platform has, such as display size and sensors.

Hardware revisions are selected with an `@` suffix, for example
`pbl configure --board obelix@pvt`. The revisions each board supports are
listed in `boards/<board>/<board>.yml`. The repository has no board
definitions for the watches made by Pebble Technology Corporation (the aplite,
basalt, chalk and diorite platforms).

> Note: The imported documentation has a board page for Asterix only. The
> `obelix`, `getafix` and QEMU boards are documented by their `Kconfig` and
> `defconfig` files in the repository.


## How the Firmware, the SDK and the Mobile App Relate

Watchapps do not link against the firmware. The firmware build generates the
app SDK from its own sources: `pebble.h` with the exported declarations, and
`libpebble.a` with trampolines that call into the firmware through a function
table compiled into the firmware image. Apps run as unprivileged processes
and reach OS state through syscalls. The imported
[Exposing functions to the SDK](/pebbleos/docs/development/sdk_export/) page
describes how a firmware function becomes an SDK API.

The SDK that developers install with `pebble sdk install` is built from a
firmware release. The C API reference on this site at [/docs/c/](/docs/c/) is
generated from the pebbleos release tag recorded in the site's
`EMERY_SDK_VERSION` file. The firmware documentation in this section tracks
`main`, so it can describe functions that are not yet in a released SDK.

The Pebble mobile app pairs with the watch over Bluetooth, installs apps and
firmware updates, and runs the PebbleKit JS side of apps. During development
it also carries the
{% guide_link tools-and-resources/developer-connection "Developer Connection" %}
that the `pebble` tool uses to install and debug apps on a watch. Its source
is at [github.com/coredevices/mobileapp](https://github.com/coredevices/mobileapp).

> Note: Two different things are called an SDK. The Pebble SDK builds
> watchapps. The PebbleOS SDK at
> [github.com/coredevices/PebbleOS-SDK](https://github.com/coredevices/PebbleOS-SDK)
> is the toolchain bundle for building the firmware: the ARM GNU toolchain,
> Pebble QEMU and flashing tools. The imported pages mean the second one.


## Where the Documentation Starts

* [Prerequisites](/pebbleos/docs/development/getting_started/) sets up a
  build environment and gets the source. The rest of the Development pages
  cover the `pbl` tool, configuration options, building and flashing,
  testing, the emulator, debugging and contributing.
* [Architecture overview](/pebbleos/docs/architecture/) is a tour of the
  source tree with links to the design documents.
* [Boards](/pebbleos/docs/boards/) describes the hardware and how to connect
  a programmer.
* [Reference](/pebbleos/docs/reference/) holds protocol specifications, file
  formats and external resources.
* The [Firmware API Reference](/pebbleos/apidoc/index.html) is the Doxygen
  output for the firmware's public headers under `include/`: kernel, drivers,
  services and subsystems. It describes interfaces inside the firmware; the
  [C API reference](/docs/c/) is the one to use when writing apps.

[Contributing to PebbleOS](/pebbleos/contributing/) collects the steps for
getting a change merged and answers to the questions that come up most often
on the forum.
