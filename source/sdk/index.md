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

The easiest way to start building a Pebble watchface or app is with the [Cloud IDE](/sdk/cloud) - no installation required. It runs entirely in your browser!

Otherwise, if you are somewhat command-line knowledgeable, you can follow the instructions below to install the SDK locally on your computer.

## Install dependencies

#### MacOS

You will need to install Node.js. The easiest way is with [Homebrew](https://brew.sh/):

```bash
brew install node
```

When you install the Pebble CLI below using `uv`, it will automatically download and use the correct Python version for you - no need to install it manually!

#### Ubuntu

You will need to install a few dependencies to make the SDK run:

```bash
sudo apt install nodejs npm libsdl1.2debian libfdt1
```

When you install the Pebble CLI below using `uv`, it will automatically download and use the correct Python version for you - no need to install Python manually!

> Note: if you already have `node` installed, you can install only:

```bash
sudo apt install libsdl1.2debian libfdt1
```

#### Windows

The Pebble SDK does not run on Windows, but you can use WSL.  Install Ubuntu
in WSL, and then use the instructions above to install dependencies.

## Download the Pebble CLI

Install [uv](https://docs.astral.sh/uv/getting-started/installation/), a fast package manager for Python.

Then, run:

```bash
uv tool install pebble-tool --python 3.13
```

> Note: pebble-tool requires Python 3.10, 3.11, 3.12, or 3.13 (higher than 3.9 and lower than 3.14).

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

Or, install the app/watchface on your phone. 

Requires the new Pebble mobile app (install at [rePebble.com/app](https://repebble.com/app)) -> go to Devices -> tap 3 dots -> Enable Dev Connect -> Sign into GitHub. Then back on your computer, run

```bash
pebble login # Sign into GitHub
pebble install --cloudpebble
```

#### Learn more

The best way to learn is by checking out our examples apps: [weather](https://github.com/pebble-examples/pebblekit-js-weather/), [simple game](https://github.com/pebble-hacks/pandas-and-bananas/), [concentricity watchface](https://github.com/pebble-examples/concentricity/), and [many more](/examples)! Or try [tutorials](/tutorials/) for a step-by-step guide on how
to write a simple C Pebble application.

### Installation Problems?

If you have any issues with downloading or installing the Pebble SDK, feel free to post your comments in `#sdk-dev` in the
[Rebble Discord][rebble-discord]. Please provide as many details as you can about the issues
you may have encountered.

**Tip:** Copying and pasting commands from your Terminal output will help a great deal.

[rebble-discord]: https://discord.com/invite/aRUAYFN