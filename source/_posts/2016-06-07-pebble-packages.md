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

title: Introducing Pebble Packages
author: katharine
tags:
- Freshly Baked
---

I am thrilled to announce that, as part of SDK 3.13 and Pebble Tool 4.3, we have
launched our own packaging system: Pebble Packages!



There are already a healthy selection of Pebble libraries to be had, such as
Yuriy's excellent [EffectLayer](https://github.com/ygalanter/EffectLayer),
Reboot's Ramblings'
[palette manipulator](https://github.com/rebootsramblings/GBitmap-Colour-Palette-Manipulator),
or even our own [weather library](https://github.com/pebble-hacks/owm-weather).
However, using them today is inelegant: you generally have to copy/paste all of
the library code into your own project and follow some other setup instructions:
assigning appmessage keys, editing resources into your appinfo.json, or similar.

Starting today, using a Pebble Package can be as simple as running
`pebble package install pebble-owm-weather`. A Pebble Package can contain
both C code for the watch and JavaScript code for the phone. Furthermore, it can
also contain any resources, and define its own appmessage keys. All numeric
identifiers will be resolved at app build time to ensure there are never any
conflicts. This helps to enable zero-setup packages of all kinds.

To make the usage of appmessages in Pebble Packages possible, we have also
substantially improved the functionality of the old `appKeys` section of
appinfo.json. We will now automatically insert the keys into your C code with
the prefix `MESSAGE_KEY_`. You can also access their numeric values from
JavaScript by requiring the `message_keys` module:
`var keys = require('message_keys')`.

Packages would be nothing without a package manager, so we have built our
packaging system on top of the excellent [npm](https://npmjs.com) package manager. This gives
us support for dependency management, versioning, package hosting, and more. Furthermore,
some traditional JavaScript modules on npm will work out of the box, as long as
they don't depend on running in node or on a browser. As part of this
move we have **deprecated appinfo.json**: we now use `package.json` instead.
The latest version of the Pebble Tool can convert your project when you run
`pebble convert-project`. Old-style projects continue to be supported, but
cannot use the package manager.

For your convenience, we have provided some wrappers around npm functionality:

* `pebble package install` to safely install a package.
* `pebble package uninstall` to uninstall a package.
* `pebble package login` to log in to or create your npm account.
* `pebble package publish` to publish your package to npm.

We also have UI in CloudPebble to enter your dependencies.

You can browse the available packages on npm under the
[pebble-package](https://www.npmjs.com/browse/keyword/pebble-package) keyword,
and read our guides on [using](/guides/pebble-packages/using-packages/) and
[creating](/guides/pebble-packages/creating-packages/) Pebble Packages.

I'm looking forward to seeing what you make!
