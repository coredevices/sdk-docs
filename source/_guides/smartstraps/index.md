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
  Information on creating and talking to smartstraps.
guide_group: smartstraps
menu: false
permalink: /guides/smartstraps/
generate_toc: false
hide_comments: true
related_docs:
  - Smartstrap
related_examples:
  - title: Smartstrap Button Counter
    url: https://github.com/pebble-examples/smartstrap-button-counter
  - title: Smartstrap Library Test
    url: https://github.com/pebble-examples/smartstrap-library-test
---

The smart accessory port on the back of Pebble Time, Pebble Time Steel, and
Pebble Time Round makes it possible to create accessories with electronics
built-in to improve the capabilities of the watch itself. Wrist-mounted pieces
of hardware that interface with a Pebble watch are called smartstraps and can
potentially host many electronic components from LEDs, to temperature sensors,
or even external batteries to boost battery life.

This section of the developer guides details everything a developer
should need to produce a smartstrap for Pebble; from 3D CAD diagrams, to
electrical characteristics, to software API and protocol specification details.


## Contents

{% include guides/contents-group.md group=page.group_data %}


## Availablility

The ``Smartstrap`` API is available on the following platforms and firmwares.

| Platform | Model | Firmware |
|----------|-------|----------|
| Basalt | Pebble Time/Pebble Time Steel | 3.4+ |
| Chalk | Pebble Time Round | 3.6+ |

Apps that use smartstraps but run on incompatible platforms can use compile-time
defines to provide alternative behavior in this case. Read
{% guide_link best-practices/building-for-every-pebble %} for more information
on supporting multiple platforms with differing capabilities.


## Video Introduction

Watch the video below for a detailed introduction to the Smartstrap API by Brian
Gomberg (Firmware team), given at the 
[PebbleSF Meetup](http://www.meetup.com/PebbleSF/).

[EMBED](//www.youtube.com/watch?v=uB9r2lw7Bt8)
