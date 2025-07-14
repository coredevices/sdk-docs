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
title: Pebble SDK Download
permalink: /sdk/download/
menu_section: sdk
menu_subsection: download
generate_toc: true
scripts:
  - sdk/index
---

## Get the Latest Pebble Tool

The `pebble` tool allows you to quickly switch between different SDK versions.
The instructions to obtain the tool vary depending on your platform. All
specific instructions are shown on this page.


## Mac OS X

The Pebble SDK can be installed automatically using Homebrew, or manually if
preferred. If you already use at least version 4.0 of the `pebble` tool, you can
install the latest SDK by running the following command:

```bash
$ pebble sdk install latest
```


### With Homebrew

If you previously used Homebrew to install older Pebble SDKs, run:

```bash
$ brew update && brew upgrade pebble-sdk
```

If you've never used Homebrew to install the Pebble SDK, run:

```bash
$ brew update && brew install pebble/pebble-sdk/pebble-sdk
```


### Without Homebrew

If you would prefer to not use Homebrew and would like to manually install the
Pebble SDK:

1. Download the 
   [SDK package]({{ site.links.pebble_tool_root }}pebble-sdk-{{ site.data.sdk.pebble_tool.version }}-mac.tar.bz2).

2. Follow the [Mac manual installation instructions](/sdk/install/mac/).


## Linux

Linux users should install the SDK manually using the instructions below:

1. Download the relevant package:
   [Linux (32-bit)]({{ site.links.pebble_tool_root }}pebble-sdk-{{ site.data.sdk.pebble_tool.version }}-linux32.tar.bz2) |
   [Linux (64-bit)]({{ site.links.pebble_tool_root }}pebble-sdk-{{ site.data.sdk.pebble_tool.version }}-linux64.tar.bz2).

2. Install the SDK by following the
   [manual installation instructions](/sdk/install/linux/).


## Windows

Installing the Pebble SDK on Windows is not officially supported at this time.
However, you can choose from alternative strategies to develop watchfaces and
watchapps on Windows, which are detailed below.


### Use CloudPebble

[CloudPebble]({{site.links.cloudpebble}}) is the official online development
environment for writing Pebble apps. It allows you to create, edit, build and
distribute applications in your web browser without installing anything on your
computer.

**Pebble strongly recommends [CloudPebble]({{site.links.cloudpebble}}) for
Windows users.**


### Use a Virtual Machine

You can also download and run the Pebble SDK in a virtual machine.

 1. Install a virtual machine manager such as
   [VirtualBox](http://www.virtualbox.org) (free) or
   [VMWare Workstation](http://www.vmware.com/products/workstation/).
 2. Install [Ubuntu Linux](http://www.ubuntu.com/) in a virtual machine.
 3. Follow the standard [Linux installation instructions](/sdk/install/linux/).


## Testing Beta SDKs

Beta SDKs are released in the run up to stable SDK releases, and give interested
developers a chance to test out new features and APIs and provide feedback.

You can opt-in to the beta channel to receive beta SDKs. Once the beta period ends,
you will be notified of the update to the final stable version.

<div class="alert alert--fg-white alert--bg-dark-red">
{% markdown %}
**IMPORTANT**

Apps built with a beta SDK **must not** be uploaded to the developer portal, as
users not yet on the new firmware version will be unable to install them.
{% endmarkdown %}
</div>

Once you have the latest `pebble` tool, you can easily access and try out new
beta SDKs we release from time to time by switching to the 'beta' sdk channel:

```bash
$ pebble sdk set-channel beta
```

Install the latest beta SDK:

```bash
$ pebble sdk install latest
```
