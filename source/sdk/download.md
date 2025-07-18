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
title: Pebble SDK Installation
permalink: /sdk/download/
menu_section: sdk
menu_subsection: download
generate_toc: true
scripts:
  - sdk/index
---

## Install dependencies

The Pebble SDK requires some dependencies. Run the command below that corresponds to your operating system.

### Mac OS X

```bash
brew update
brew install glib
brew install pixman
```

### Linux (Ubuntu)

```bash
sudo apt install libsdl1.2debian libfdt1
```

### Windows

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