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

title: Bringing the Family Back Together - 3.x on Aplite is Almost Here!
author: chrislewis
tags:
- Freshly Baked
banner: /images/blog/3.x-on-tintin.png
---

The time has almost come for Pebble Classic and Pebble Steel to get firmware
3.x!

This is great news for users who get access to all the improvements and fixes
since 2.x, as well as new features such as timeline, Quiet Time, no more eight
app limit, Standby Mode, and last but not least one new color (gray)!

But let us not forget about Basalt and Chalk app developers, who also have a lot
to get excited about - a huge new user base of Aplite watch wearers!

This blog post aims to help developers using SDK 2.x features and APIs to
migrate their apps to a single 3.x codebase. As well as bringing compatibility
to all older watches when they upgrade to firmware 3.x, these changes will also
serve to remove a lot of complex and ugly conditional code that has needed to
exist in the meantime. Let's fix some apps!


## Get the Beta SDK

To try out the beta SDK, read the instructions on the [SDK Beta](/sdk/beta)
page.


## Mandatory Changes

To be compatible with users who update their Pebble Classic or Pebble Steel to
firmware 3.x the following important changes **MUST** be made:

* If you are adding support for Aplite, add `aplite` to your `targetPlatforms`
  array in `appinfo.json`, or tick the 'Build Aplite' box in 'Settings' on
  CloudPebble.

* Recompile your app with at least Pebble SDK 3.8 (coming soon!). The 3.x on
  Aplite files will reside in `/aplite/` instead of the `.pbw` root folder.
  Frankenpbws are **not** encouraged - a 2.x compatible release can be uploaded
  separately (see [*Appstore Changes*](#appstore-changes)).

* Update any old practices such as direct struct member access. An example is
  shown below:

    ```c
    // 2.x - don't do this!
    GRect bitmap_bounds = s_bitmap->bounds;

    // 3.x - please do this!
    GRect bitmap_bounds = gbitmap_get_bounds(s_bitmap);
    ```

* If your app uses either the ``Dictation`` or ``Smartstrap`` APIs, you must
  check that any code dependent on these hardware features fails gracefully when
  they are not available. This should be done by checking for `NULL` or
  appropriate `enum` values returned from affected API calls. An example is
  shown below:

    ```c
    if(smartstrap_subscribe(handlers) != SmartstrapResultNotPresent) {
      // OK to use Smartstrap API!
    } else {
      // Not available, handle gracefully
      text_layer_set_text(s_text_layer, "Smartstrap not available!");
    }

    DictationSession *session = dictation_session_create(size, callback, context);
    if(session) {
      // OK to use Dictation API!
    } else {
      // Not available, handle gracefully
      text_layer_set_text(s_text_layer, "Dictation not available!");
    }
    ```


## Appstore Changes

To handle the transition as users update their Aplite to firmware 3.x (or choose
not to), the appstore will include the following changes:

* You can now have multiple published releases. When you publish a new release,
  it doesn’t unpublish the previous one. You can still manually unpublish
  releases whenever they want.

* The appstore will provide the most recently compatible release of an app to
  users. This means that if you publish a new release that has 3.x Aplite
  support, the newest published release that supports 2.x Aplite will be
  provided to users on 2.x Aplite.

* There will be a fourth Asset Collection type that you can create: Legacy
  Aplite. Apps that have different UI designs between 2.x and 3.x on Aplite
  should use the Legacy Aplite asset collection for their 2.x assets.


## Suggested Changes

To fully migrate to SDK 3.x, we also suggest you make these non-essential
changes:

* Remove any code conditionally compiled with `PBL_SDK_2` defines. It will no
  longer be compiled at all.

* Ensure that any use of ``app_message_inbox_size_maximum()`` and
  ``app_message_outbox_size_maximum()`` does not cause your app to run out of
  memory. These calls now create ``AppMessage`` buffers of 8k size by default.
  Aplite apps limited to 24k of RAM will quickly run out if they use much more
  memory.

* Colors not available on the black and white Aplite display will be silently
  displayed as the closet match (black, gray, or white). We recommend checking
  every instance of a `GColor`to ensure each is the correct one.

* In addition to the point above, investigate how the contrast and readability
  of your app can be improved by making use of gray (either `GColorLightGray` or
  `GColorDarkGray`). Examples of this can be seen in the system UI in the banner
  at the top of this blog post.

* Apps using image resources should take advantage of the new `bitmap` resource
  type, which optimizes image files for you. Read the
  [*Unifying Bitmap Resources*](/blog/2015/12/02/Bitmap-Resources/)
  blog post to learn more.


## Questions?

That's it! It will be quite straightforward to update most of your apps, but if
you do have any problems or queries, feel free to
[contact us](/contact/) or find us on [Discord]({{ site.links.discord_invite }}).
