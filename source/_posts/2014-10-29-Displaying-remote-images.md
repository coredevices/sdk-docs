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

title: Displaying remote images in a Pebble app
author: thomas
tags:
 - Beautiful Code
---

> A picture is worth a thousand words.

The old adage applies just as well to your Pebble apps! One of the most common
requests when [we attend hackathons](/community/events/) is "How do I transfer an image
from the Internet to my Pebble app?".

Today we introduce a new example that demonstrates downloading a PNG file from
the Internet and loading it on Pebble.  We will also cover how to prepare your
images so that they take as little memory as possible and load quickly on Pebble.

The code is available in our 
[pebble-examples github account][pebble-faces]. Continue reading for
more details!


## Downloading images to Pebble

The first step to display a remote image is to download it onto the phone. To do
this we built a simple library that can be easily reused: NetDownload. It is
based on [PebbleKit JavaScript](/guides/communication/using-pebblekit-js) and
``AppMessage``. The implementation is in
[`pebble-js-app.js`][pebble-js-app.js] for the JavaScript part and in
[`netdownload.c`][netdownload.c] for the C part.

Let's walk through the download process:

 - The C application initializes the library with a call to
   `netdownload_initialize()`. The library in turns initializes the AppMessage
   framework.
 - The [`show_next_image()` function][netdownload-call] calls `netdownload_request(char *url)` to
   initiate a download. This function sends an AppMessage to the JavaScript with
   two elements. One is the URL to be downloaded and the second one is the
   maximum transmission size supported by the watch (this is provided by
   ``app_message_inbox_size_maximum()``).
 - The JavaScript receives this message, tries to download the resource from
   the Internet (via `downloadBinaryResource()`) and saves it as byte array.
 - The image is then split into chunks (based on the maximum transmission size)
   and sent to the watch. The first message contains the total size of the image
   so the watchapp can allocate a buffer large enough to receive the entire
   image. We use the JavaScript success and error callbacks to resend chunks as necessary.
 - After the last chunk of data, we send a special message to tell the app that
   we are done sending. The app can then check that the size matches what was
   announced and if everything is ok, it calls the download successful callback
   that was defined when initializing the library.

## Loading PNG images on Pebble

Instead of converting images to the native PBI format of Pebble, this example
transmits the image in PNG format to the watch and uses a PNG library to decompress
the image and to display it on the screen. The PNG library used is 
[uPNG by Sean Middleditch and Lode Vandevenne][upng].

This approach is very convenient for multiple reasons:

 - It is often easier to generate PNG images on your server instead of the
   native PBI format of Pebble.
 - PNG images will be smaller and therefore faster to transfer on the network
   and over Bluetooth.

It does have one drawback though and that is that the PNG library uses
approximately 5.5kB of code space.

In the NetDownload callback we receive a pointer to a byte-array and its length.
We simply pass them to `gbitmap_create_with_png_data()` (provided by `png.h`)
and in return we get a ``GBitmap`` that we can display like any other
``GBitmap`` structure.

## Preparing your images

Because your PNG file will be transferred to Pebble and loaded into the limited
memory available on the watch, it is very important to make sure that the PNG is
as small as possible and does not contain useless information.

Specifically:

 - The image should be 144x168 pixels (fullscreen) or smaller
 - It should be in black and white
 - It should not contain any metadata (like the author name, gps location of the
   pictures, etc)

To prepare your image, we recommend using Image Magick (careful! Graphics Magick
is a different library and does not support some of the options recommended
below, it is important to use Image Magick!)

    convert myimage.png \
      -adaptive-resize '144x168>' \
      -fill '#FFFFFF00' -opaque none \
      -type Grayscale -colorspace Gray \
      -colors 2 -depth 1 \
      -define png:compression-level=9 -define png:compression-strategy=0 \
      -define png:exclude-chunk=all \
      myimage.pbl.png

Notes:

 - `-fill #FFFFFF00 -opaque none` makes the transparent pixels white
 - `-adaptive-resize` with `>` at end means resize only if larger, and maintains aspect ratio
 - we exclude PNG chunks to reduce size (like when image was made, author)

If you want to use [dithering](http://en.wikipedia.org/wiki/Dither) to simulate Gray, you can use this command:

    convert myimage.png \
      -adaptive-resize '144x168>' \
      -fill '#FFFFFF00' -opaque none \
      -type Grayscale -colorspace Gray \
      -black-threshold 30% -white-threshold 70% \
      -ordered-dither 2x1 \
      -colors 2 -depth 1 \
      -define png:compression-level=9 -define png:compression-strategy=0 \
      -define png:exclude-chunk=all \
      myimage.pbl.png

For more information about PNG on Pebbles, how to optimize memory usage and tips
on image processing, please refer to the 
[Advanced techniques videos](/community/events/developer-retreat-2014/) 
from the Pebble Developer Retreat 2014.

## Connecting the pieces

The main C file (`pebble-faces.c`) contains a list of images to load and
everytime you shake your wrist it will load the next one. Take a few minutes to
test this out and maybe this technique will find its way into your next watchface!

[pebble-faces]: {{site.links.examples_org}}/pebble-faces
[netdownload.c]: {{site.links.examples_org}}/pebble-faces/blob/master/src/netdownload.c
[pebble-js-app.js]: {{site.links.examples_org}}/pebble-faces/blob/master/src/js/pebble-js-app.js
[netdownload-call]: {{site.links.examples_org}}/pebble-faces/blob/master/src/pebble-faces.c#L25
[upng]: https://github.com/elanthis/upng
