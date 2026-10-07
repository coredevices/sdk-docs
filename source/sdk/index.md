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

layout: sdk/markdown
title: Installing the Pebble SDK
permalink: /sdk/
menu_section: sdk
menu_subsection: install
generate_toc: true
scripts:
  - sdk/index
---

The easiest way to start building a Pebble watchface or app is with [CloudPebble](https://cloudpebble.repebble.com) - no installation required. It runs entirely in your browser!

Otherwise, if you are somewhat command-line knowledgeable, you can follow the instructions below to install the SDK locally on your computer.

## Install dependencies

#### MacOS

You will need to install Node.js and libpng. The easiest way is with [Homebrew](https://brew.sh/):

```bash
brew install node libpng
```

#### Ubuntu

You will need to install a few dependencies to make the SDK run:

```bash
sudo apt install nodejs npm libsdl2-2.0-0 libglib2.0-0 libpixman-1-0 zlib1g libsndio7.0
```

> Note: if you already have `node` installed, you can install only:

```bash
sudo apt install libsdl2-2.0-0 libglib2.0-0 libpixman-1-0 zlib1g libsndio7.0
```

#### Fedora

```bash
sudo dnf install nodejs SDL2 glib2 pixman zlib sndio
```

#### Windows

The Pebble SDK does not run on Windows, but you can use WSL. Install Ubuntu
in WSL, and then use the instructions above to install dependencies.

## Download the Pebble CLI

Install [uv](https://docs.astral.sh/uv/getting-started/installation/), a fast package manager for Python.

Then, run:

```bash
uv tool install pebble-tool
```

> Note: The `pebble` tool requires Python 3.10 to 3.13. Python 3.14 is not
> supported yet.

## Platform Support

Each Pebble watch is identified by a platform name in the SDK:

| Platform | Watches |
|----------|---------|
| `aplite` | Pebble, Pebble Steel |
| `basalt` | Pebble Time, Pebble Time Steel |
| `chalk` | Pebble Time Round |
| `diorite` | Pebble 2 |
| `flint` | Pebble 2 Duo |
| `emery` | Pebble Time 2 |
| `gabbro` | Pebble Round 2 |

Not every language and feature is available on every platform:

| Feature | Platforms | Notes |
|---------|-----------|-------|
| C SDK | All | |
| Alloy (JavaScript on the watch) | `emery`, `gabbro` | `flint` is not supported yet. `aplite`, `basalt`, `chalk` and `diorite` are not supported. See {% guide_link alloy %}. |
| PebbleKit JS | All | Runs on the phone, in the Pebble mobile app. |
| Rocky.js | None | Removed from the firmware. Use Alloy instead. |
| Touch | `emery`, `gabbro` | Watchapps only. Watchfaces cannot receive touch events. See {% guide_link events-and-services/touch %}. |
| Heart rate monitor | `diorite` (except Pebble 2 SE), `emery` | See {% guide_link events-and-services/hrm %}. |
| Speaker | `flint`, `emery` | See {% guide_link events-and-services/speaker %}. |
| Microphone | All except `aplite` | See {% guide_link events-and-services/dictation %}. |

Watchfaces cannot receive button or touch events on any platform. See
{% guide_link tools-and-resources/hardware-information %} for the full
hardware comparison.

The `sdkVersion` field in `package.json` stays `"3"` for every app, including
apps built with SDK 4.x. The version of the `pebble` tool (5.x) is not the
version of the SDK (4.x); run `pebble sdk list` to see which SDKs are
installed.

## Next Steps

Now that you have the Pebble SDK downloaded and installed on your computer,
it is time to create your first app!

#### Create a Pebble app

Install the latest SDK:

```bash
pebble sdk install latest
```

Create a project (for example, called myproject):

```bash
pebble new-project myproject
```

Compile the project (after `cd`ing to your project directory):

```bash
pebble build
```

Install the app on an emulator for the Pebble Time:

```bash
pebble install --emulator basalt
```

Or, install the app on the watch through the Pebble mobile app (install it
from [repebble.com/app](https://repebble.com/app)). In the Pebble mobile app,
sign in with your Pebble account, open the *Devices* tab, tap the three dot icon
on your watch and enable the *Dev Connection* toggle. Then, on your computer,
sign in to the same Pebble account and install:

```bash
pebble login
pebble install --cloudpebble
```

See {% guide_link tools-and-resources/developer-connection %} for details and
for the LAN connection, which works without signing in.

#### Learn more

The best way to learn is by checking out our examples apps: [weather](https://github.com/pebble-examples/pebblekit-js-weather/), [simple game](https://github.com/pebble-hacks/pandas-and-bananas/), [concentricity watchface](https://github.com/pebble-examples/concentricity/), and [many more](/examples)! Or try [tutorials](/tutorials/) for a step-by-step guide on how
to write a simple C Pebble application.

### Installation Problems?

On Linux, check the following first:

* On WSL2, install `build-essential` before installing the SDK:
  `sudo apt install build-essential`.
* The emulator needs glibc 2.38 or newer. Ubuntu 22.04 ships an older glibc,
  so use Ubuntu 24.04 or newer.
* On Fedora, the emulator needs `libsndio`: `sudo dnf install sndio`.

Check the [FAQ](/faqs/) next - common install, emulator, and `pebble` tool errors are answered there.

If you're still stuck, ask on the [Pebble Developer Forum][dev-forum] or in `#sdk-dev` on the
[Rebble Discord][rebble-discord]. Please provide as many details as you can about the issues
you may have encountered.

**Tip:** Copying and pasting commands from your Terminal output will help a great deal.

[dev-forum]: https://forum.repebble.com/c/developers-ask-questions-and-get-help/7
[rebble-discord]: https://discord.com/invite/aRUAYFN
