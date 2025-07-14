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

title: Pebble Draw Command File Format
description: |
  The binary file format description for Pebble Draw Command Frames, Images and
  Sequences.
guide_group: app-resources
order: 5
related_docs:
  - Draw Commands
  - LayerUpdateProc
  - Graphics
related_examples:
  - title: PDC Sequence
    url: https://github.com/pebble-examples/pdc-sequence
  - title: Weather Cards Example
    url: https://github.com/pebble-examples/cards-example
---

Pebble [`Draw Commands`](``Draw Commands``) (PDCs) are vector image files that
consist of a binary resource containing the instructions for each stroke, fill,
etc. that makes up the image. The byte format of all these components are
described in tabular form below.

> **Important**: All fields are in the little-endian format!

An example implementation with some
[usage limitations](/tutorials/advanced/vector-animations#creating-compatible-files)
can be seen in
[`svg2pdc.py`]({{site.links.examples_org}}/cards-example/blob/master/tools/svg2pdc.py).


## Component Types

A PDC binary file consists of the following key components, in ascending order
of abstraction:

* [Draw Command](#pebble-draw-command) - an instruction for a single line or
  path to be drawn.

* [Draw Command List](#pebble-draw-command-list) - a set of Draw Commands that
  make up a shape.

* [Draw Command Frame](#pebble-draw-command-frame) - a Draw Command List with
  configurable duration making up one animation frame. Many of these are used in
  a Draw Command Sequence.

* [Draw Command Image](#pebble-draw-command-image) - A single vector image.

* [Draw Command Sequence](#pebble-draw-command-sequence) - A set of Draw Command
  Frames that make up an animated sequence of vector images.


## Versions

| PDC Format Version | Implemented |
|--------------------|-------------|
| 1 | Firmware 3.0 |


## File Format Components

### Point

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| X | 0 | 2 | X axis coordinate. Has one of two formats depending on the Draw Command type (see below):<br/><br>Path/Circle type: signed integer. <br/>Precise path type: 13.3 fixed point. |
| Y | 2 | 2 | Y axis coordinate. Has one of two formats depending on the Draw Command type (see below):<br/><br>Path/Circle type: signed integer. <br/>Precise path type: 13.3 fixed point. |


### View Box

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| Width | 0 | 2 | Width of the view box (signed integer). |
| Height | 2 | 2 | Height of the view box (signed integer). |


### Pebble Draw Command

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| Type | 0 | 1 | Draw command type. Possible values are: <br/><br/>`0` - Invalid <br/>`1` - Path<br/>`2` - Circle<br/>`3` - Precise path |
| Flags | 1 | 1 | Bit 0: Hidden (Draw Command should not be drawn). <br/> Bits 1-7: Reserved. |
| Stroke color | 2 | 1 | Pebble color (integer). |
| Stroke width | 3 | 1 | Stroke width (unsigned integer). |
| Fill color | 4 | 1 | Pebble color (integer). |
| Path open/radius | 5 | 2 | Path/Precise path type: Bit 0 indicates whether or not the path is drawn open (`1`) or closed (`0`).<br/>Circle type: radius of the circle. |
| Number of points | 7 | 2 | Number of points (n) in the point array. See below. |
| Point array | 9 | n x 4 | The number of points (n) points. |


### Pebble Draw Command List

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| Number of commands | 0 | 2 | Number of Draw Commands in this Draw Command List. (`0` is invalid). |
| Draw Command array | 2 | n x size of Draw Command  | List of Draw Commands in the format [specified above](#pebble-draw-command). |


### Pebble Draw Command Frame

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| Duration | 0 | 2 | Duration of the frame in milliseconds. If `0`, the frame will not be shown at all (unless it is the last frame in a sequence). |
| Command list | 2 | Size of Draw Command List | Pebble Draw Command List in the format [specified above](#pebble-draw-command-list). |

### Pebble Draw Command Image

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| Version | 8 | 1 | File version. |
| Reserved | 9 | 1 | Reserved field. Must be `0`. |
| [View box](#view-box) | 10 | 4 | Bounding box of the image. All Draw Commands are drawn relative to the top left corner of the view box. |
| Command list | 14 | Size of Draw Command List | Pebble Draw Command List in the format [specified above](#pebble-draw-command-list). |


### Pebble Draw Command Sequence

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| Version | 8 | 1 | File version. |
| Reserved | 9 | 1 | Reserved field. Must be `0`. |
| [View box](#view-box) | 10 | 4 | Bounding box of the sequence. All Draw Commands are drawn relative to the top left corner of the view box. |
| Play count | 14 | 2 | Number of times to repeat the sequence. A value of `0` will result in no playback at all, whereas a value of `0xFFFF` will repeat indefinitely. |
| Frame count | 16 | 2 | Number of frames in the sequence. `0` is invalid. |
| Frame list | 18 | n x size of Draw Command Frame | Array of Draw Command Frames in the format [specified above](#pebble-draw-command-frame). |


## File Formats

### Pebble Draw Command Image File

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| Magic word | 0 | 4 | ASCII characters spelling "PDCI". |
| Image size | 4 | 4 | Size of the Pebble Draw Command Image (in bytes). |
| Image | 8 | Size of Pebble Draw Command Image. | The Draw Command Image in the format [specified above](#pebble-draw-command-image). |


### Pebble Draw Command Sequence File

| Field | Offset (bytes) | Size (bytes) | Description |
|-------|----------------|--------------|-------------|
| Magic word | 0 | 4 | ASCII characters spelling "PDCS". |
| Sequence size | 4 | 4 | Size of the Pebble Draw Command Sequence (in bytes). |
| Sequence | 8 | Size of Draw Command Sequence | The Draw Command Sequence in the format [specified above](#pebble-draw-command-sequence). |
