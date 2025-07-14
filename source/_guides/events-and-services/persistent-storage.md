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

title: Persistent Storage
description: |
  Using persistent storage to improve your app's UX.
guide_group: events-and-services
order: 7
related_docs:
  - Storage
---

Developers can use the ``Storage`` API to persist multiple types of data between
app launches, enabling apps to remember information previously entered by the
user. A common use-case of this API is to enable the app to remember
configuration data chosen in an app's configuration page, removing the
tedious need to enter the information on the phone every time the watchapp is
launched. Other use cases include to-to lists, stat trackers, game highscores
etc.

Read {% guide_link user-interfaces/app-configuration %} for more information on
implementing an app configuration page.


## Persistent Storage Model

Every app is allocated 4 kB of persistent storage space and can write values to
storage using a key, similar to ``AppMessage`` dictionaries or the web
`localStorage` API. To recall values, the app simply queries the API using the
associated key . Keys are specified in the `uint32_t` type, and each value can
have a size up to ``PERSIST_DATA_MAX_LENGTH`` (currently 256 bytes).

When an app is updated the values saved using the ``Storage`` API will be
persisted, but if it is uninstalled they will be removed.

Apps that make large use of the ``Storage`` API may experience small pauses due
to underlying housekeeping operations. Therefore it is recommended to read and
write values when an app is launching or exiting, or during a time the user is
waiting for some other action to complete.


## Types of Data

Values can be stored as boolean, integer, string, or arbitrary data structure
types. Before retrieving a value, the app should check that it has been
previously persisted. If it has not, a default value should be chosen as
appropriate.

```c
uint32_t key = 0;
int num_items = 0;

if (persist_exists(key)) {
  // Read persisted value
  num_items = persist_read_int(key);
} else {
  // Choose a default value
  num_items = 10;

  // Remember the default value until the user chooses their own value
  persist_write_int(key, num_items);
}
```

The API provides a 'read' and 'write' function for each of these types,
with builtin data types retrieved through assignment, and complex ones into a
buffer provided by the app. Examples of each are shown below.


### Booleans

```c
uint32_t key = 0;
bool large_font_size = true;
```

```c
// Write a boolean value
persist_write_bool(key, large_font_size);
```

```c
// Read the boolean value
bool large_font_size = persist_read_bool(key);
```


### Integers

```c
uint32_t key = 1;
int highscore = 432;
```

```c
// Write an integer
persist_write_int(key, highscore);
```

```c
// Read the integer value
int highscore = persist_read_int(key);
```


### Strings

```c
uint32_t key = 2;
char *string = "Remember this!";
```

```c
// Write the string
persist_write_string(key, string);
```

```c
// Read the string
char buffer[32];
persist_read_string(key, buffer, sizeof(buffer));
```


### Data Structures

```c
typedef struct {
  int a;
  int b;
} Data;

uint32_t key = 3;
Data data = (Data) {
  .a = 32,
  .b = 45
};
```

```c
// Write the data structure
persist_write_data(key, &data, sizeof(Data));
```

```c
// Read the data structure
persist_read_data(key, &data, sizeof(Data));
```

> Note: If a persisted data structure's field layout changes between app
> versions, the data read may no longer be compatible (see below).


## Versioning Persisted Data

As already mentioned, automatic app updates will persist data between app
versions. However, if the format of persisted data changes in a new app version
(or keys change), developers should version their storage scheme and correctly
handle version changes appropriately.

One way to do this is to use an extra persisted integer as the storage scheme's
version number. If the scheme changes, simply update the version number and
migrate existing data as required. If old data cannot be migrated it should be
deleted and replaced with fresh data in the correct scheme from the user. An
example is shown below:

```c
const uint32_t storage_version_key = 786;
const int current_storage_version = 2;
```

```c
// Store the current storage scheme version number
persist_write_int(storage_version_key, current_storage_version);
```

In this example, data stored in a key of `12` is now stored in a key of `13` due
to a new key being inserted higher up the list of key values.

```c
// The scheme has changed, increment the version number
const int current_storage_version = 3;
```

```c
static void migrate_storage_data() {
  // Check the last storage scheme version the app used
  int last_storage_version = persist_read_int(storage_version_key);

  if (last_storage_version == current_storage_version) {
    // No migration necessary
    return;
  }

  // Migrate data
  switch(last_storage_version) {
    case 0:
      // ...
      break;
    case 1:
      // ...
      break;
    case 2: {
      uint32_t old_highscore_key = 12;
      uint32_t new_highscore_key = 13;

      // Migrate to scheme version 3
      int highscore = persist_read_int(old_highscore_key);
      persist_write_int(new_highscore_key, highscore);

      // Delete old data
      persist_delete(old_highscore_key);
      break;
  }

  // Migration is complete, store the current storage scheme version number
  persist_write_int(storage_version_key, current_storage_version);
}
```


## Alternative Method

In addition to the ``Storage`` API, data can also be persisted using the
`localStorage` API in PebbleKit JS, and communicated with the watch over
``AppMessage`` when the app is lanched. However, this method uses more power and
fails if the watch is not connected to the phone.

