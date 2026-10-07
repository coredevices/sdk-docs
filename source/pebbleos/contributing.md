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
title: Contributing to PebbleOS
description: |
  How to set up a firmware build, send a change to the pebbleos repository,
  and install a custom build on a watch or the emulator.
permalink: /pebbleos/contributing/
generate_toc: true
search_index: true
search_group: PebbleOS
---

PebbleOS is developed at
[github.com/coredevices/pebbleos](https://github.com/coredevices/pebbleos).
Changes arrive as pull requests, bugs are tracked in the repository's issues,
and discussion happens in the repository's Discussions, on the
[forum](https://forum.repebble.com) and on
[Discord]({{ site.links.discord_invite }}). This page points to the imported
documentation for each step and answers the questions that come up most often.


## Setting Up a Build

* Follow [Prerequisites](/pebbleos/docs/development/getting_started/) to
  install the PebbleOS SDK toolchain bundle, the system packages and the
  Python environment, and to clone the repository with its submodules.
* [The `pbl` CLI](/pebbleos/docs/development/pbl/) is the command you drive
  the build with: `pbl configure --board <board>`, then `pbl build`.
  [Configuration Options](/pebbleos/docs/development/options/) lists the
  `-D` options `pbl configure` accepts.
* [QEMU](/pebbleos/docs/development/qemu/) runs a build without hardware.
  Configure one of the `qemu_flint`, `qemu_emery` or `qemu_gabbro` boards and
  run `pbl qemu`. The `pebble` tool installs `.pbw` files into the running
  emulator with `pebble install --qemu`.
* [Building firmware](/pebbleos/docs/development/building_fw/) covers
  flashing a board with `pbl flash` and bundling a `.pbz` for a sealed watch.
* [Debugging](/pebbleos/docs/development/debugging/) covers `pbl debug`, the
  `pbl` GDB commands and reading logs.


## Sending a Change

The [Contribution Guidelines](/pebbleos/docs/development/contributing/) are
the rules the repository enforces. In short:

* Every commit carries a Developer Certificate of Origin sign-off. Commit
  with `git commit -s` so git adds the `Signed-off-by:` line, using the same
  name and email as the commit author.
* Each commit is one logical change, with a message in the form
  `area: description`, for example `applib: add touch service`.
* C code is formatted with clang-format and Python with ruff.
* A change that adds a function apps can call also needs the steps on
  [Exposing functions to the SDK](/pebbleos/docs/development/sdk_export/).

Changes to the firmware documentation go in the `docs/` directory of the
pebbleos repository, not on this site. The imported pages are regenerated
from there.


## Installing a Custom Build on a Watch

A sealed watch takes firmware over Bluetooth as a `.pbz` bundle. After
`pbl build`, run `pbl bundle`; the bundle is written to `build/`. Copy it to
the phone, then in the Pebble mobile app:

* Open *Settings* and turn on *Show debug options*.
* Open the *Devices* tab, tap your watch, then *Firmware Update Debug*.
* Tap *Sideload FW* and choose the `.pbz` file.

The `pebble` tool can also install a bundle onto a connected watch:

```nc|text
$ pebble fw install build/<bundle>.pbz
```

[Building firmware](/pebbleos/docs/development/building_fw/) has the current
steps, including a scripted route over `adb` on Android. A board with its
debug connector exposed is flashed directly with `pbl flash` instead.


## Recovery Firmware

The watch keeps a second, minimal firmware image called PRF (Pebble Recovery
Firmware). The bootloader falls back to it when the main firmware cannot
boot, and the Pebble mobile app reinstalls the main firmware from it. PRF is
built from the same source as a separate variant, `pbl configure
--variant prf`; the [Architecture overview](/pebbleos/docs/architecture/)
describes how the two images relate.

To reboot a running watch into PRF, hold *Back*, *Up* and *Select* together,
or run:

```nc|text
$ pebble fw enter-prf
```

`pebble fw install` takes a `--slot` option for bundles that contain more
than one firmware image.


## Emulator Support for Pebble Time 2 and Pebble Round 2

There is no QEMU model of the SiFli SF32LB52 SoC used in Pebble Time 2
(`obelix`) and Pebble Round 2 (`getafix`). The `qemu_emery` and
`qemu_gabbro` boards run the emery and gabbro platform code on the
repository's QEMU SoC target (`soc/qemu`, a Cortex-M33 machine), so the UI,
app behaviour and the Pebble protocol can be tested without the real
hardware. The SoC drivers of the physical watches are not exercised by the
emulator.


## The Firmware Development Kit

The imported pages mention a firmware development kit. It is a watch
mainboard with its debug connector exposed together with a programming
board, which lets `pbl flash`, `pbl console` and `pbl debug` talk to the
board over SWD and a serial port. For Pebble 2 Duo this is the Core B2B v2
board described on the [Asterix board page](/pebbleos/docs/boards/asterix/).
Without one, a custom build is installed as a `.pbz` bundle as described
above.
