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

layout: guides/default
title: Developer Guides
description: |
  Details of all the guides available for use for building watchapps and
  companion phone apps.
permalink: /guides/
hide_comments: true
generate_toc: false
---

This is the main page for the Developer Guides, containing a large number of
resources for developing all kinds of Pebble watchapps. New and experienced
developers can use these resources to help build their skill set when writing
for Pebble.

## What's Here?

To help guide towards the most relevant information, the developer guides are
split up into the following sections. A complete list of every available guide
is available in the [Table of Contents](/guides/toc).

{% for category in site.data.guide-categories %}
### {{ category.title }}
{% for group in site.data.guides %}
  {% assign grp = group[1] %}
  {% if grp.category == category.id %}
  * [**{{ grp.title }}**]({{ grp.url }}) - {{ grp.description }}
  {% endif %}
{% endfor %}
{% endfor %}