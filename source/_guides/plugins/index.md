---
title: Plugins (Preview)
description: |
  How a .pbw's JavaScript can provide data sources and actions to other apps
  through the Pebble mobile app, and how a watchapp reads them from PebbleKit
  JS. Preview: off by default and subject to change.
guide_group: plugins
permalink: /guides/plugins/
menu: false
generate_toc: false
hide_comments: true
---

A plugin is JavaScript in a `.pbw` that runs on the phone, inside the Pebble
mobile app, and offers two things to other apps: *sources*, data that any
watchface or watchapp can read, and *actions*, operations such as turning a
light off or adding a task that any watchapp can trigger. A watchface that
shows the weather no longer needs its own weather API and key; it subscribes
to `weather/location` and whichever weather plugin the user has installed
answers. The Pebble mobile app exposes some of its own data as built-in
plugins, and the [Index 01](/index-01/) assistant will call plugin actions as
tools.

{% alert important %}
Plugins are a preview. The API will change before plugins are released to all
users, and the Pebble mobile app ships with them turned off. Do not publish
apps that use or provide plugins to the appstore yet.
{% endalert %}

The documentation is maintained alongside the implementation and the example
plugins in the
[Pebble mobile app repository](https://github.com/coredevices/mobileapp/tree/master/test-apps),
and is reproduced here.

## Contents

{% include guides/contents-group.md group=page.group_data %}
