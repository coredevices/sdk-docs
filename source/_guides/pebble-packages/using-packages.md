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

title: Using Pebble Packages
description: How to use Pebble Packages
permalink: /guides/pebble-packages/using-packages/
generate_toc: true
guide_group: pebble-packages
---

## Getting started

Using pebble packages is easy:

1. Find a package. We will have a searchable listing soon, but for now you
   can [browse the pebble-package keyword on npm](https://www.npmjs.com/browse/keyword/pebble-package).
2. Run `pebble package install pebble-somelib` to install pebble-somelib.
3. Use the package.

It is possible to use _some_ standard npm packages. However, packages that
depend on being run in node, or in a real web browser, are likely to fail. If
you install an npm package, you can use it in the usual manner, as described
below.

### C code

Packages should document their specific usage. However, in general,
for C packages you can include their headers and call them like so:

```c
#include <pebble-somelib/somelib.h>

int main() {
  somelib_do_the_thing();
}
```

All of the package's include files will be in a folder named after the package.
Packages may have any structure inside that folder, so you are advised to
read their documentation.

{% alert notice %}
**Tip**: If you want to use an
``Event Service``,
you should use the
[pebble-events](https://www.npmjs.com/package/pebble-events) package to
avoid conflicting with handlers registered by packages.
{% endalert %}

### JavaScript code

JavaScript packages are used via the `require` function. In most cases you can
just `require` the package by name:

```js
var somelib = require('pebble-somelib');

somelib.doTheThing();
```

### Resources

If the package you are using has included image resources, you can reference
them directly using their `RESOURCE_ID_*` identifiers.

```c
static GBitmap *s_image_01;
s_image_01 = gbitmap_create_with_resource(RESOURCE_ID_MEDIA_PACKAGE_IMAGE_01_TINY);
```

### Published Media

If the package you are using has defined `publishedMedia` resources, you can
either reference the resources using their resource identifier (as above), or
you can create an alias within the `package.json`. The `name` you specify in
your own project can be used to reference that `publishedMedia` item for
AppGlances and Timeline pins, eg. `PUBLISHED_ID_<name>`

For example, if the package exposes the following `publishedMedia`:

```javascript
"resources": {
  //...
  "publishedMedia": [
    {
      "name": "MEDIA_PACKAGE_IMAGE_01",
      "glance": "MEDIA_PACKAGE_IMAGE_01_TINY",
      "timeline": {
        "tiny": "MEDIA_PACKAGE_IMAGE_01_TINY",
        "small": "MEDIA_PACKAGE_IMAGE_01_SMALL",
        "large": "MEDIA_PACKAGE_IMAGE_01_LARGE"
      }
    }
  ]
}
```

You could define the following `name` and `alias` with a unique `id` in your
`package.json`:

```javascript
"resources": {
  //...
  "publishedMedia": [
    {
      "name": "SHARED_IMAGE_01",
      "id": 1,
      "alias": "MEDIA_PACKAGE_IMAGE_01"
    }
  ]
}
```

You can then proceed to use that `name`, prefixed with `PUBLISHED_ID_`, within
your code:

```c
const AppGlanceSlice entry = (AppGlanceSlice) {
  .layout = {
    .icon = PUBLISHED_ID_SHARED_IMAGE_01,
    .subtitle_template_string = "message"
  }
};
```
