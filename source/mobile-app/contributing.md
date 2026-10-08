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
layout: mobile-app
title: Contributing to the Mobile App
description: |
  How to send a change to the Pebble mobile app repository, what the
  maintainers ask for in a pull request, and how the code is licensed.
permalink: /mobile-app/contributing/
generate_toc: true
search_index: true
search_group: Mobile App
---

The Pebble mobile app is developed at
[github.com/coredevices/mobileapp](https://github.com/coredevices/mobileapp).
The public repository is a copy of the internal one that Core Devices works
in, synced by hand, so it can lag behind. Changes arrive as pull requests.


## Sending a Change

* Fork the repository and make the change on a branch.
* Open a pull request against `main`. Say in the description what the
  change does and how you tested it.
* If you used AI to write any of the code, say so in the description. The
  maintainers do not accept changes that the author has not read and
  understood.
* Contributions to `libpebble3` need the
  [Contributor License Agreement](https://cla-assistant.io/coredevices/libpebble3).
  There is no sign-off requirement on commits.

Core Devices has a small mobile team, and reviewing a change can mean
testing it with hardware and maintaining it afterwards, so a review can take
some time. A pull request that adds a feature the team has not planned is
more likely to wait than a fix.

Bugs in the app are reported from the app itself, under *Settings*, *Get
Help*, *New Bug Report*, rather than as GitHub issues. The in-app report
attaches the logs the team needs.


## Forks

Maintaining a fork is fine. A fork may not use "Pebble" in its name except
to refer to the watch, so "Awesome App for Pebble" is acceptable and "Pebble
Awesome" is not. The repository README has the details.


## License

The app is dual-licensed by Core Devices LLC. It can be used under the
[GNU GPLv3](https://github.com/coredevices/mobileapp/blob/main/LICENSE), or
under a paid
[commercial license](https://github.com/coredevices/mobileapp/blob/main/LICENSE-COMMERCIAL)
agreed with Core Devices. The GPL grant carries an additional permission to
distribute builds through the Apple App Store.
