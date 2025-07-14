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

title: Debugging
description: |
  How to find and fix common compilation and runtime problems in apps.
guide_group: debugging
permalink: /guides/debugging/
menu: false
generate_toc: false
related_docs:
  - Logging
hide_comments: true
---

When writing apps, everyone makes mistakes. Sometimes a simple typo or omission
can lead to all kinds of mysterious behavior or crashes. The guides in this
section are aimed at trying to help developers identify and fix a variety of
issues that can arise when writing C code (compile-time) or running the compiled
app on Pebble (runtime).

There are also a few strategies outlined here, such as app logging and other
features of the `pebble` {% guide_link tools-and-resources/pebble-tool %} that
can indicate the source of a problem in the vast majority of cases.


## Contents

{% include guides/contents-group.md group=page.group_data %}
