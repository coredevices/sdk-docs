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

layout: docs/markdown
title: SDK Documentation
permalink: /docs/
---

Welcome to the API Documentation section of the Pebble Developers site!

Here you will find complete listings of all the classes, objects, methods and
functions available across all the parts of the Pebble API.

## Pebble Smartwatch APIs

Pebble's smartwatch APIs provide developers with a means of developing
applications that run natively on Pebble smartwatches.

### [Pebble C API](/docs/c/)

The Pebble C API, used for creating native **watchapps and watchfaces** in C.
The Pebble C API can be used in combination with *any* of the PebbleKit APIs
listed below to extend the application's functionality.

### [Pebble JavaScript API](/docs/rockyjs/)

Pebble's embedded JavaScript API, used for creating native **watchfaces** in
JavaScript. The embedded JavaScript API can be used in combination with
PebbleKit JS to extend the application's functionality.

## PebbleKit APIs

The PebbleKit APIs provides developers with a means to extend their application's
functionality by communicating with an application on the mobile device it is
paired to.

### [PebbleKit JS](/docs/pebblekit-js/)

PebbleKit JS enables developers to extend their Pebble projects by adding a
JavaScript component that is managed by the Pebble mobile app. PebbleKit JS is
capable of bidirectional communication with with application running on the
Pebble smartwatch

### [PebbleKit iOS](/docs/pebblekit-ios/)

PebbleKit iOS is an Objective-C library that enables developers to create
companion apps for iOS devices that are capable for bi-directional communication
with their Pebble API projects.

### [PebbleKit Android](/docs/pebblekit-android/)

PebbleKit Android is a Java library that enables developers to create companion
apps for Android devices that are capable for bi-directional communication with
their Pebble API projects.

{% comment %}
## Web APIs

### [Timeline API](/docs/web-timeline/)

The Timeline API enables developers to create applications that interact with
the user's Timeline, by creating and editing Timeline Pins.

### [AppGlance API](/docs/web-appglance)

The AppGlance web API enables developers to create applications that push
information to the application's glance in the user's launcher.
 {% endcomment %}
