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

title: Smartstraps
description: |
  Historical record of the smartstrap accessory port on Pebble Time, Pebble
  Time Round and Pebble 2.
guide_group: smartstraps
menu: false
permalink: /guides/smartstraps/
generate_toc: false
hide_comments: true
---

> Note: Smartstraps are not supported on Pebble 2 Duo, Pebble Time 2, Pebble
> Round 2 or newer watches, and support will not be added.

Smartstraps were accessories that connected to the smart accessory port on the
back of Pebble Time, Pebble Time Steel, Pebble Time Round and Pebble 2. The
port carried power and a one-wire serial bus, and the `Smartstrap` C API let an
app exchange data with the strap.

Pebble 2 Duo, Pebble Time 2, Pebble Round 2 and newer watches do not have the
accessory port, and the `Smartstrap` API is not part of the current SDK
reference. This page is kept as a historical record.

The original guides on smartstrap hardware, the serial protocol and the C API
remain in the
[repository history](https://github.com/coredevices/sdk-docs/tree/c4ef713%5E/source/_guides/smartstraps).
