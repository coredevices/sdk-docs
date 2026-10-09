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

title: Alloy Reference
description: |
  Where the Alloy APIs are documented, and the details that are not obvious
  from the other guides: font names, resource IDs, modules, memory and
  TypeScript.
guide_group: alloy
order: 18
---

Alloy is built from three layers: the XS JavaScript engine and the Moddable SDK
modules (Piu, Poco, the ECMA-419 sensor and network classes), the Pebble
modules that expose the watch (`pebble/button`, `pebble/message`,
`pebble/vibes` and so on), and the Pebble firmware underneath. Documentation is
spread across the same three places.


## Where the Documentation Is

* The guides in this section describe the Pebble modules and how to use Piu
  and Poco on the watch. Start with
  {% guide_link alloy/getting-started %}.

* The Moddable SDK documentation at
  [moddable.com/documentation](https://www.moddable.com/documentation/) covers
  Piu, Poco (under Commodetto), the XS engine, the `manifest.json` format and
  the ECMA-419 classes. Alloy ships Moddable SDK 8.3; features added later are
  not available.

* The TypeScript declarations in the SDK are the most precise reference for
  the Pebble modules. They are at
  `toolchain/moddable/typings/pebble/` inside the SDK directory
  (`~/Library/Application Support/Pebble SDK/SDKs/current` on macOS,
  `~/.pebble-sdk/SDKs/current` on Linux), one `.d.ts` file per module.

* The [pebble-examples](https://github.com/Moddable-OpenSource/pebble-examples)
  repository has a small example for each API. Its README lists the
  JavaScript features that are left out of the XS build and what the "dead
  strip" error means.


## System Fonts

Poco and Piu load the watch's built-in fonts by family name and size. Poco
takes them directly:

```js
const font = new render.Font("Gothic-Bold", 24);
```

Piu uses a CSS-style string. The weight becomes part of the family name, so
`"bold 24px Gothic"` selects `Gothic-Bold` at 24 and `"black 30px Bitham"`
selects `Bitham-Black` at 30. A string with no weight selects the `-Regular`
variant.

Both look the name and size up in a fixed table in the firmware. The size must
match exactly; there is no scaling. If nothing matches, the constructor throws
`font not found`. The table maps to the C `FONT_KEY_*` constants as follows:

| Alloy family | Sizes | C constant |
|--------------|-------|------------|
| `Gothic-Regular` | 9, 14, 18, 24, 28 | `FONT_KEY_GOTHIC_09` ... `FONT_KEY_GOTHIC_28` |
| `Gothic-Bold` | 14, 18, 24, 28 | `FONT_KEY_GOTHIC_14_BOLD` ... `FONT_KEY_GOTHIC_28_BOLD` |
| `Bitham-Black` | 30 | `FONT_KEY_BITHAM_30_BLACK` |
| `Bitham-Bold` | 42 | `FONT_KEY_BITHAM_42_BOLD` |
| `Bitham-Light` | 42, 34, 18 | `FONT_KEY_BITHAM_42_LIGHT`, `FONT_KEY_BITHAM_34_LIGHT_SUBSET`, `FONT_KEY_BITHAM_18_LIGHT_SUBSET` |
| `Bitham-Medium` | 42, 34 | `FONT_KEY_BITHAM_42_MEDIUM_NUMBERS`, `FONT_KEY_BITHAM_34_MEDIUM_NUMBERS` |
| `Roboto-Condensed` | 21 | `FONT_KEY_ROBOTO_CONDENSED_21` |
| `Roboto-Bold` | 49 | `FONT_KEY_ROBOTO_BOLD_SUBSET_49` |
| `DroidSerif-Bold` | 28 | `FONT_KEY_DROID_SERIF_28_BOLD` |
| `Leco-Bold` | 20, 26, 32, 36, 38 | `FONT_KEY_LECO_20_BOLD_NUMBERS`, `FONT_KEY_LECO_26_BOLD_NUMBERS_AM_PM`, `FONT_KEY_LECO_32_BOLD_NUMBERS`, `FONT_KEY_LECO_36_BOLD_NUMBERS`, `FONT_KEY_LECO_38_BOLD_NUMBERS` |
| `Leco-Regular` | 42 | `FONT_KEY_LECO_42_NUMBERS` |
| `Leco-Light` | 28 | `FONT_KEY_LECO_28_LIGHT_NUMBERS` |

The firmware table also lists `Gothic-Regular` and `Gothic-Bold` at size 36,
which have no `FONT_KEY_*` constant in the C SDK. The Leco fonts and the
`SUBSET` Bitham fonts contain digits and a few symbols only; see
{% guide_link app-resources/system-fonts %} for the glyph sets. There is no
Alloy name for `FONT_KEY_LECO_60_NUMBERS_AM_PM` or
`FONT_KEY_LECO_60_BOLD_NUMBERS_AM_PM`.

Fonts from the project's resources are loaded by resource ID instead of by
name, with the same constructor: `new render.Font(3)`.


## Resource IDs

`Poco.PebbleBitmap(id)`, `Poco.PebbleDrawCommandImage(id)` and
`Poco.PebbleDrawCommandSequence(id)` take a number: the resource ID the
build assigned. IDs start at 1 and follow the order of the `resources.media`
array in `package.json`, counting only the resources built for the current
platform:

```json
"resources": {
  "media": [
    { "type": "png", "name": "BACKGROUND", "file": "images/background.png" },
    { "type": "raw", "name": "HOURS", "file": "pdc/hours.pdc" }
  ]
}
```

With this manifest `new Poco.PebbleBitmap(1)` loads `background.png` and
`new Poco.PebbleDrawCommandImage(2)` loads `hours.pdc`. Inserting a resource
in the middle of the list shifts every ID after it, and so do these cases:

* A resource with `targetPlatforms` that excludes the current platform is
  skipped on that platform, so the IDs after it differ between platforms.

* When `publishedMedia` is present, the build reserves ID 1 for the timeline
  lookup table and the first media resource becomes ID 2.

* The compiled JavaScript is added as a resource named `MOD` after the
  project's media, and resources from Pebble Packages come after it.

The build writes the final assignment to
`build/<platform>/src/resource_ids.auto.h` as `RESOURCE_ID_<name>` defines.
Check that file after changing `package.json` rather than counting by hand.

The names in `package.json` are not available to the JavaScript at runtime.
To avoid hard-coded numbers, keep one module that defines the IDs in the same
order as the manifest and import it everywhere:

```js
// resources.js
export default {
  BACKGROUND: 1,
  HOURS: 2,
};
```

Piu's `Texture` and `SVGImage` classes accept either a number, which is a
Pebble resource ID as above, or a string path, which is a Moddable resource
listed in the `resources` section of `src/embeddedjs/manifest.json`.


## Modules and manifest.json

Every JavaScript file that is imported must be listed in
`src/embeddedjs/manifest.json`. The template contains:

```json
{
  "include": [
    "$(MODDABLE)/examples/manifest_mod.json",
    "$(MODDABLE)/examples/manifest_typings.json"
  ],
  "modules": {
    "*": "./main"
  }
}
```

Under `"*"` each file becomes a module named after its file name, so
`"*": ["./main", "./clock"]` makes `import Clock from "clock"` work. A key
other than `"*"` gives the module a different specifier, for example
`"piu/Controller": "./modules/piuController"`, and a path ending in `/*`
includes every file in a directory. A `"platforms"` block selects modules per
platform, with the keys `"pebble/emery"` and `"pebble/gabbro"`.

Each module costs memory at startup. Prefer a few larger modules over many
small ones.


## The connected Event

`watch.addEventListener("connected", handler)` fires when the connection to
the phone changes, in either direction. It does not fire when the listener
is added, and the handler receives no argument. Read `watch.connected.app`
and `watch.connected.pebblekit` for the current state, once at startup and
again inside the handler:

```js
function update() {
  console.log(`phone connected: ${watch.connected.app}`);
}
watch.addEventListener("connected", update);
update();
```

The firmware can take 15 to 30 seconds to report a dropped connection.


## Memory

The JavaScript engine runs inside the app's RAM. By default the template's
`src/c/mdbl.c` passes `NULL` to `moddable_createMachine()`, which gives the
engine a 32 kB static pool that it divides between the slot heap (objects and
values), the chunk heap (strings and buffers) and the stack, growing as
needed.

When the engine cannot allocate, the app exits and the watch shows a dialog
titled *Alloy: Fatal Error* with the engine's message, most often
`memory full`. The same message appears in the app logs as
`fxAbort memory full`. Other messages in that dialog are
`JavaScript stack overflow`, `not enough keys` and `dead strip`, the last one
meaning the code used a JavaScript feature that is left out of the XS build.

Apps that need more than the default pass a `ModdableCreationRecord`:

```c
#include <pebble.h>

int main(void) {
  Window *w = window_create();
  window_stack_push(w, true);

  moddable_createMachine(&(ModdableCreationRecord){
    .recordSize = sizeof(ModdableCreationRecord),
    .stack = 5120,
    .slot = 31744,
    .chunk = 19456
  });

  window_destroy(w);
  return 0;
}
```

All three sizes are in bytes, and either all three or none must be set. When
their total exceeds 32 kB the engine uses exactly these sizes and does not
grow further, so size them for the app's peak use. The watch's app RAM is
128 kB on both emery and gabbro, shared with the Pebble UI library and the
native part of the app.


## TypeScript

Name the source files `.ts` instead of `.js` and list them in `manifest.json`
as usual. The build runs `tsc`, which must be installed and on the `PATH`;
the SDK does not include it. The `manifest_typings.json` include in the
template adds the Pebble and Moddable declarations to the compiler's
configuration, so no `tsconfig.json` is needed. The
[hellotypescript](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellotypescript)
example is the smallest working project.


## Examples and SDK Versions

The examples in pebble-examples target SDK 4.33.1, with these exceptions:

* `piu/apps/words` and `piu/watchfaces/wallpaper` import
  `embedded:storage/key-value` as a module. The released firmware rejects
  this import, so both fail to load. Use `device.keyValue.open()` as shown in
  {% guide_link alloy/storage %}.

* `piu/watchfaces/cupertino`, `helsinki`, `redmond` and `zurich` list `flint`
  in `targetPlatforms`. Alloy does not run on Pebble 2 Duo, so build and
  install them for emery or gabbro only.

* `piu/watchfaces/wallpaper` lists `gabbro` but its `manifest.json` only has
  modules for emery, so the gabbro build fails. It also needs a local
  WebSocket server to download images from.
