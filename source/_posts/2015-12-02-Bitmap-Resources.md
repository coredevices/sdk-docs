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

title: Unifying bitmap resources 
author: katharine
tags:
- Freshly Baked
---

With the upcoming release of firmware 3.8 on Pebble and Pebble Steel, and the
associated SDK 3.8, we have decided to redesign how image resources work in
Pebble apps.




Why change?
-----------

First, some history: when SDK 1 was originally released, and continuing up to
SDK 2.9, there was a single image type, `png`. A `png` resource would take a PNG
as input and spit out a custom, uncompressed, 1-bit-per-pixel image format we
called "pbi". This was the only bitmap format Pebble supported, and life was
simple.

With the release of SDK 3.0, we added firmware support for a new image format:
PNG (with some restrictions). This enabled Pebble to directly read compressed
images, and those images could be 1-bit, 2-bit, 4-bit or 8-bit palettised. The
existing `png` resource type was changed to produce these images instead of the
old PBI format, and everyone had smaller image resources.

Unfortunately, "png" isn't the best option for all cases. The old 1-bit format
supported some [compositing operations](``GCompOp``) that other image formats
do not support. We added the `pbi` format to achieve this legacy behavior.
Additionally, PNG decompression isn't free: loading a PNG resource requires
enough memory to hold the compressed image, the uncompressed image, and some
scratch space. This was often offset by the benefits of palettised images with
fewer bits per pixel, but sometimes it didn't fit. We added `pbi8`, which
produced 8-bit-per-pixel PBI images. This still left it impossible to generate
a palettized PBI, even though the format does exist.

As a further complication, since SDK 1 and continuing through the present day,
`pbi` (and `pbi8`) images have cropped transparent borders around the outside.
However, `png` images (as of SDK 3) do _not_ crop like this. The cropping
behavior was originally a bug, and is generally undesirable, but must be
maintained for backwards compatibility.

There is one additional exception to all of this: until SDK 3.8, the Aplite platform still
interprets `png` to mean `pbi`. It also interprets `pbi8` to mean `pbi`. When
we built the 3.8 SDK, we changed `png` to really mean `png` on Aplite.
Unfortunately, the more limited memory of the Aplite platform meant that these
PNGs sometimes did not have enough space to decompress. The only workaround was
to duplicate resources and use `targetPlatforms` to specify a `pbi` resource for
Aplite and a `png` resource for Basalt and Chalk.

The easiest answer was to keep `png` as an alias for `pbi` on Aplite—but then
there's no way of generating a real PNG for Aplite. Furthermore, the `png`,
`pbi` and `pbi8` trio was getting confusing, so we decided to do something else.

"bitmap" to the rescue
----------------------

As of SDK 3.8, `png`, `pbi` and `pbi8` **are all deprecated**. We are instead
introducing a new resource type, `bitmap`. This new resource type unifies all
the existing types, allows the SDK to use its best judgement, increases the
flexibility available to developers, and takes the guesswork out of advanced
image manipulation. It also removes the generally undesirable forced cropping
behavior.

The simplest option is to only specify that you want a `bitmap` resource, and
by default the SDK will do the most reasonable thing:

```js
{
	"type": "bitmap",
	"name": "IMAGE_BERRY_PUNCH",
	"file": "images/berry-punch.png"
}
```

This will create an image with the smallest possible in-memory representation,
which will depend on the number of colors. On Aplite, where memory is tight,
it will optimize for low memory consumption by creating a pbi. On all other
platforms, where there is more memory to spare, it will create a png.

This behavior can be overridden using the following attributes:

* `memoryFormat`: This determines the `GBitmapFormat` that the resulting image
  will have. The default value is `Smallest`, which picks the value that will
  use the least memory. If you have specific requirements, you can specify:
  `SmallestPalette`, `1BitPalette`, `2BitPalette`, `4BitPalette`, `1Bit` or
  `8Bit`. If an image cannot be represented in the requested format, a build
  error will result. This, for instance, enables palette manipulation with
  static checking for confidence that you will have an appropriate palette to
  manipulate.
* `spaceOptimization`: This determines whether we should optimize the image for
  resource space (`storage`) or memory (`memory`). The default depends on the
  memory available on the platform: Aplite defaults to `memory`, while other
  platforms default to `storage`.
* `storageFormat`: This explicitly states whether an image should be stored on
  flash as a PNG or pbi image. In most cases you should not specify this, and
  instead depend on `spaceOptimization`. However, if you read resources
  directly, this option exists to force a value.

So if you want an image that will always have a 2-bit palette and use as little
memory as possible, you can do this:

```js
{
	"type": "bitmap",
	"name": "IMAGE_TIME_TURNER",
	"file": "images/time-turner.png",
	"memoryFormat": "2BitPalette",
	"spaceOptimization": "memory"
}
```

The resulting image will always have `GBitmapFormat2BitPalette`, even if it
could have a 1-bit palette. If it has more than four colors, the build will
fail.

In SDK 3.8-beta8, this would result in a 2-bit palettized pbi. However, this
is not guaranteed: we can change the format in the future, as long as the result
has ``GBitmapFormat2BitPalette`` and we prefer to optimise for memory
consumption where possible. 

Finally, note that some combinations are impossible: for instance, a `1Bit`
image can never be stored as a PNG, so `"storageFormat": "png"` combined with
`"memoryFormat": "1Bit"` will be a compile error.

Migration
---------

If you have an existing app, how do you migrate it to use the new `bitmap` type?

If you were depending on the `pbi` cropping behavior, you will have to manually
crop your image. Beyond that, this table gives the equivalences:

| SDK 3.7 type | `bitmap` specification                       |
|--------------|----------------------------------------------|
| `png`        | `{"type": "bitmap"}`                         |
| `pbi`        | `{"type": "bitmap", "memoryFormat": "1Bit"}` |
| `pbi8`       | `{"type": "bitmap", "storageFormat": "pbi"}` |

`png-trans` has been left out of this entire exercise. Its behavior is unchanged:
it will produce two pbis with `GBitmapFormat1Bit`. However, `png-trans` is also
deprecated and discouraged. As of SDK 3.8, all platforms support transparency
in images, and so should use `bitmap` instead.

If you have any questions, you can [find us on Discord]({{ site.links.discord_invite }})
or [contact us](/contact/).
