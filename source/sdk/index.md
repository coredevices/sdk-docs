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

## Install dependencies

The Pebble SDK requires some dependencies. Run the command below that corresponds to your operating system.

#### MacOS

```bash
brew install glib
brew install pixman
```

#### Ubuntu

```bash
sudo apt install libsdl1.2debian libfdt1
```

#### Windows

The Pebble SDK does not natively support Windows, but you can use WSL. Once you've installed Ubuntu in WSL, run:

```bash
sudo apt install python3-pip python3-venv nodejs npm libsdl1.2debian libfdt1
```

## Download the Pebble CLI

Install [uv](https://docs.astral.sh/uv/getting-started/installation/), a fast package manager for Python.

Then, run:

```bash
uv tool install pebble-tool
```

The `pebble` tool allows you to create, build, and install Pebble projects on your watch and an emulator.

## Next Steps

Now that you have the Pebble SDK downloaded and installed on your computer,
it is time to learn how to write your first app!

You should checkout the [Tutorials](/tutorials/) for a step-by-step look at how
to write a simple C Pebble application.

### Installation Problems?

If you have any issues with downloading or installing the Pebble SDK, feel free to post your comments in `#sdk-dev` in the
[Rebble Discord][rebble-discord]. Please provide as many details as you can about the issues
you may have encountered.

**Tip:** Copying and pasting commands from your Terminal output will help a great deal.

[rebble-discord]: https://discord.com/invite/aRUAYFN