---
# Copyright 2026 Core Devices LLC
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

title: Native Functions (FFI)
description: |
  Call native C functions directly from JavaScript in your Alloy app using the
  Foreign Function Interface.
guide_group: alloy
order: 12
---

The Foreign Function Interface (FFI) lets your Alloy app call native C
functions directly from JavaScript. This is useful for performance-critical
code, for reusing existing C libraries, or for reaching low-level
functionality that isn't exposed through a JavaScript API.

> **Platform Support**: Like the rest of Alloy, FFI is available on Emery
> (Pebble Time 2) and Gabbro (Pebble Time 2 round).

An FFI binding has three parts:

1. The **native C source** that implements the functions.
2. An **`ffi` block** in `manifest.json` that lists the C sources and declares
   each function's signature.
3. The **`Natives` global** in your JavaScript, through which the functions are
   called.

## 1. Write the native C functions

Add one or more C files alongside your `main.js` (for example
`src/embeddedjs/add.c`). The C function names must match the names you declare
in the manifest:

```c
// add.c
#include <stdint.h>

int32_t add(int32_t a, int32_t b) {
    return a + b;
}

int32_t addSquares(int32_t a, int32_t b) {
    return (a * a) + (b * b);
}
```

Functions can take and return buffers and strings as well as numbers:

```c
// hello.c
#include <stdint.h>
#include <string.h>

// Fill the caller-provided buffer with bytes derived from `greeting`.
void hello(char *greeting, uint8_t *bytes, uint32_t length) {
    size_t len = strlen(greeting);
    for (uint32_t i = 0; i < length; i++) {
        bytes[i] = (uint8_t)greeting[i % len];
    }
}
```

## 2. Declare the functions in the manifest

In `src/embeddedjs/manifest.json`, add an `ffi` block listing your C `sources`
and the `functions` with their argument and return types:

```json
{
    "include": [
        "$(MODDABLE)/examples/manifest_mod.json",
        "$(MODDABLE)/examples/manifest_typings.json"
    ],
    "modules": {
        "*": "./main"
    },
    "ffi": {
        "sources": [
            "./add.c",
            "./hello.c"
        ],
        "functions": {
            "add": {
                "arguments": [ "int32_t", "int32_t" ],
                "returns": "int32_t"
            },
            "addSquares": {
                "arguments": [ "int32_t", "int32_t" ],
                "returns": "int32_t"
            },
            "hello": {
                "arguments": [ "char *", "uint8_t*", "uint32_t" ],
                "returns": "void"
            }
        }
    }
}
```

### Supported types

| C type | JavaScript value |
|--------|------------------|
| `int32_t`, `uint8_t`, `uint32_t` | `Number` |
| `char*` (argument) | `String` |
| `char*`, `const char*` (return) | `String` |
| `uint8_t*`, `void*` | `ArrayBuffer` (pass `.buffer` from a typed array or `DataView`) |
| `void` | `undefined` |

Numeric arguments are passed by value. Buffers are passed by reference, so a C
function can read from and write into an `ArrayBuffer` you pass in.

## 3. Make the machine FFI-aware

The C entry point (`src/c/mdbl.c`) must pass the generated `fxBuildFFI` symbol
when it creates the Moddable machine:

```c
#include <pebble.h>

int main(void) {
    Window *w = window_create();
    window_stack_push(w, true);

    moddable_createMachine(&(ModdableCreationRecord){
        .recordSize = sizeof(ModdableCreationRecord),
#ifdef PBL_DEBUG
        .flags = kModdableCreationFlagDebug,
#endif
        .fxBuildFFI = fxBuildFFI,
    });

    window_destroy(w);
    return 0;
}
```

## 4. Call the functions from JavaScript

All declared functions are available on the global `Natives` object:

```js
console.log("Hello, FFI.");

trace(`Natives.add(2, 3) = ${ Natives.add(2, 3) }\n`);
trace(`Natives.addSquares(3, 4) = ${ Natives.addSquares(3, 4) }\n`);

const bytes = new Uint8Array(5);
Natives.hello("hello", bytes.buffer, bytes.length);
trace(`bytes = ${ bytes }\n`);
```

Wrap calls in a `try`/`catch` to handle errors thrown across the boundary:

```js
try {
    const result = Natives.add(2, 3);
} catch (error) {
    console.log("FFI Error: " + error);
}
```

## Further reading

The FFI mechanism comes from the Moddable SDK. See the
[XS FFI documentation](https://www.moddable.com/documentation/xs/XS%20FFI)
for the full set of supported types and behaviors, and the
[`helloffi` example](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/helloffi)
for a complete project.
