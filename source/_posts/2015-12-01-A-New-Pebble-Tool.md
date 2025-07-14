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

title: Introducing Pebble Tool 4.0
author: katharine
tags:
- Freshly Baked
---

I am pleased to today announce that version 4.0-rc4 of the `pebble` tool is now
available. The key new feature is a new paradigm for dealing with firmware and
SDK versions. This makes it much easier to deal with differing SDK versions, or
to test code on multiple (emulated) firmware versions.

_A note: while the tool is now at version 4.0, the SDK, firmware and mobile apps
will not be following. Pebble tool versioning is now completely independent of
the rest of the Pebble ecosystem._




Managing SDKs
------------

The pebble tool now manages SDKs for you, without you needing to download and
install the entire SDK manually each time. The first time you need an SDK, the
latest one will be automatically installed for you. After that, you can use the
SDK operations that live under the `pebble sdk` subcommand.

To see a list of available SDKs, use `pebble sdk list`:

```nc|text
katharine@kbrmbp ~> pebble sdk list
Installed SDKs:
3.7 (active)

Available SDKs:
3.6.2
3.4
3.3
3.2.1
3.1
3.0
2.9
```

You can install any SDK using `pebble sdk install`, like so:

```nc|text
katharine@kbrmbp ~> pebble sdk install 3.6.2
Installing SDK...
Do you accept the Pebble Terms of Use and the Pebble Developer License? (y/n) y
Downloading...
100%[======================================================]   1.40 MB/s 0:00:01
Extracting...
Preparing virtualenv... (this may take a while)
Installing dependencies...
Done.
Installed.
```

You can switch between active SDKs using `pebble sdk activate <version>`, like
`pebble sdk activate 3.7`. Once you activate an SDK, it will be used for all
`build` and `install` commands.

Switching on the fly
--------------------

A number of commands now take an optional `--sdk` flag, which will override the
current active SDK. This enables you to easily run one command with a different
SDK version — for instance, compiling with 3.6.2 and then running on 3.7:

```nc|text
katharine@kbrmbp ~> pebble build --sdk 3.6.2
# ...
katharine@kbrmbp ~> pebble install --emulator basalt --sdk 3.7
# ...
```

This is supported by `pebble build` as well as any command that supports
`--emulator`. Additionally, you can now run emulators for multiple SDKs
simultaneously by passing different values for `--sdk`.

Benefits
--------

Beyond the obvious benefit of easier SDK management, the new system also
produces much smaller SDKs. Each SDK used to be a 38 MB download, which
decompressed to 143 MB, plus another hundred megabytes for the toolchain.
Most of this is now downloaded only once, as part of the initial pebble tool
setup. After that, each SDK is only a 2 MB download, which expands to 4 MB on
disk.

The new pebble tool can also alert you to new SDKs as they become available,
enabling you to install them with a single command.

Try it out!
-----------

To try out our new pebble tool, read the instructions on the [SDK
Beta](/sdk/beta) page.

Please [contact us](/contact/) if you run into any issues installing or using
`pebble` v4.0, or if you have any feedback. You can also frequently find me
on ~~Slack~~ Discord — [join us]({{ site.links.discord_invite }})!
