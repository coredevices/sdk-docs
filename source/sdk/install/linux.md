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
title: Installing the Pebble SDK on Linux
description: Detailed installation instructions for the Pebble SDK on Linux.
menu_subsection: install
menu_platform: linux
generate_toc: true
permalink: /sdk/install/linux/
---

> **Important**: The Pebble SDK is officially supported on
> Ubuntu GNU/Linux 12.04 LTS, Ubuntu 13.04, Ubuntu 13.10 and Ubuntu 14.04 LTS.
>
> The SDK should also work on other distributions with minor adjustments.
>
> **Python version**: the Pebble SDK requires Python 2.7. At this time, the
> Pebble SDK is not compatible with Python 3. However, some newer
> distributions come with both Python 2.7 and Python 3 installed, which can
> cause problems. You can use </br>`python --version` to determine which is being
> used. This means you may need to run `pip2` instead of `pip` when prompted to
> do so below.

## Download and install the Pebble SDK

{% include sdk/steps_install_sdk.md mac=false %}

{% include sdk/steps_python.md mac=false %}

## Install Pebble emulator dependencies

The Pebble emulator requires some libraries that you may not have installed on
your system.

```bash
sudo apt-get install libsdl1.2debian libfdt1 libpixman-1-0
```

{% include sdk/steps_getting_started.md %}

{% include sdk/steps_help.md %}
