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

title: Migrating Older Apps
description: |
  Details on how to update older apps affected by API changes.
guide_group: migration
menu: false
permalink: /guides/migration/
generate_toc: false
hide_comments: true
---

When the Pebble SDK major version is increased (such as from 2.x to 3.x), some
breaking API and build process changes are made. This means that some apps
written for an older SDK may no longer compile with the newer one.

To help developers transition their code, these guides detail the specific
changes they should look out for and highlighting the changes to APIs they may
have previously been using. When breaking changes are made in the future, new
guides will be added here to help developers make the required changes.


## Contents

{% include guides/contents-group.md group=page.group_data %}
