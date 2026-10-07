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

title: Preparing a Submission
description: |
  What a Pebble appstore listing is made of, and the sizes and formats
  required for screenshots, icons and banners.
guide_group: appstore-publishing
order: 0
---

An appstore listing is built from the `.pbw` file, some text fields and a set
of images. This guide lists what is required so that everything is ready
before the submission starts. All three publishing routes described in
{% guide_link appstore-publishing/publishing-an-app %} use the same listing
fields and the same image sizes.


## The `.pbw` File

The appstore reads the app's type (watchface or watchapp), UUID, version and
target platforms from the `.pbw` file. These values come from
`package.json`, so check them before building the release:

* `watchapp.watchface` decides whether the listing is a watchface or a
  watchapp. This cannot be changed in the Developer Dashboard.

* `uuid` must be unique across the whole appstore. If another app already uses
  it, the submission is rejected. Each app keeps its UUID for all later
  releases, since the UUID is how a new release is matched to the existing
  listing.

* `version` must contain only numbers and dots, and each segment must be 255 or
  less. Each release of an app must have a version that has not been used
  before.

* `targetPlatforms` decides which platforms the `.pbw` contains binaries
  for. The appstore reads the platform list from `targetPlatforms` when it
  is present and otherwise from the binaries in the `.pbw`, and offers each
  binary to the watches that can run it: an aplite binary also serves
  basalt, diorite, flint and emery, a basalt binary also serves emery, a
  diorite binary also serves flint and emery, and a chalk binary also serves
  gabbro. Build for the newer platforms directly to use their full display.
  Read {% guide_link tools-and-resources/app-metadata %} for details.

The `.pbw` file can be at most 4.4 MB.


## Listing Fields

| Field | Watchface | Watchapp | Notes |
|-------|-----------|----------|-------|
| App name | Required | Required | Defaults to the name in the `.pbw`. |
| Description | Required | Required | Plain text. |
| Category | - | Required | One of Daily, Tools & Utilities, Notifications, Remotes, Health & Fitness, Games. Watchfaces are listed under Faces automatically. |
| Website URL | Optional | Optional | |
| Source code URL | Optional | Optional | |
| Release notes | Optional | Optional | Per release. |
| Companion app | - | Optional | Name, Play Store URL and a 144×144 icon for an Android companion app. |

> Note: The appstore does not support the timeline web API. Apps that use
> {% guide_link pebble-timeline/timeline-local-pins "local pins" %} work
> as normal.


## Images

All images are PNG, JPEG or GIF, at most 4.4 MB each. GIFs keep their
animation. Screenshots must have exactly the dimensions of the platform's
display and must not be framed in a watch outline.

| Image | Size | Notes |
|-------|------|-------|
| Screenshots for aplite, basalt, diorite, flint | 144×168 | Up to 5 per platform. |
| Screenshots for chalk | 180×180 | Up to 5. |
| Screenshots for emery | 200×228 | Up to 5. |
| Screenshots for gabbro | 260×260 | Up to 5. |
| Banner | 720×320 | Optional. One per platform. Shown at the top of the listing. |
| Small icon | 80×80 | Watchapps only. |
| Large icon | 144×144 | Watchapps only. |

Icons are optional. When one or both icons are missing, the appstore generates
them from the app name.

Screenshots can be taken from the emulator with the `pebble` tool. The
`--all-platforms` and `--gif-all-platforms` flags of `pebble screenshot`
save one image per target platform under `screenshots/` in the project
directory, already at the correct size:

```nc|text
$ pebble screenshot --all-platforms
```

Read {% guide_link tools-and-resources/pebble-tool#screenshot "pebble screenshot" %}
for the other options.


## Visibility

Every app has one of three visibility settings. It is chosen when the app is
submitted and can be changed at any time from the Developer Dashboard.

| Setting | Search and browsing | Direct link and install |
|---------|---------------------|-------------------------|
| Listed | Yes | Yes |
| Unlisted | No | Yes |
| Hidden | No | No |

Apps submitted from the Developer Dashboard, the `pebble` tool or CloudPebble
start as Listed. Use Unlisted for a beta that is shared by link only, and
Hidden to take an app offline. Hiding an app does not remove it from watches
where it is already installed, and cached appstore pages can take up to ten
minutes to disappear.

Visibility applies to the app as a whole. Each release also has its own
published or draft state, and only published releases can be installed.
