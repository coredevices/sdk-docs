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
title: Installing the Pebble SDK on Mac OS X
description: Detailed installation instructions for the Pebble SDK on Mac OS X.
menu_subsection: install
menu_platform: mac
generate_toc: true
permalink: /sdk/install/mac/
---

These are the manual installation instructions for installing the Pebble SDK
from a download bundle. We recommend you 
[install the SDK using Homebrew](/sdk/download) instead, if possible.

### Compatibility

> **Python version**: the Pebble SDK requires Python 2.7. At this time, the
> Pebble SDK is not compatible with Python 3. However, some newer
> distributions come with both Python 2.7 and Python 3 installed, which can
> cause problems. You can use </br>`python --version` to determine which is being
> used. This means you may need to run `pip2` instead of `pip` when prompted to
> do so below.

### Download and install the Pebble SDK

1. Install the [Xcode Command Line Tools][xcode-command-line-tools] from
   Apple if you do not have them already.

{% include sdk/steps_install_sdk.md mac=true %}

{% include sdk/steps_python.md mac=true %}

### Pebble SDK, fonts and freetype

To manipulate and generate fonts, the Pebble SDK requires the freetype library.
If you intend to use custom fonts in your apps, please use
[homebrew][homebrew-install] to install the freetype library.

```bash
brew install freetype
```

### Install Pebble emulator dependencies

The Pebble emulator requires some libraries that you may not have installed on
your system.

The easiest way to install these dependencies is to use [homebrew][homebrew-install].

```bash
brew update
brew install boost-python
brew install glib
brew install pixman
```

> If you have installed Python using Homebrew, you **must** install boost-python
> from source. You can do that with `brew install boost-python --build-from-source` .

{% include sdk/steps_getting_started.md %}

{% include sdk/steps_help.md %}

[xcode-command-line-tools]: https://developer.apple.com/downloads/
[homebrew-install]: http://brew.sh/
