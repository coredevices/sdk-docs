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

title: Building with AI Coding Agents
description: |
  How to give an AI coding agent the Pebble documentation, project
  instructions and emulator commands it needs to build and check a Pebble app.
guide_group: ai-agents
menu: false
permalink: /guides/ai-agents/
hide_comments: true
---

AI coding agents such as Claude Code, Cursor and Codex can write Pebble apps
when they can read the SDK documentation, know how the project is set up and
can run the result in the emulator. This guide describes what the developer
site and the `pebble` tool provide for each of these.


## Building a Watchface with an Agent

The quickest way to see what an agent can do is to point it at the
[Pebble agent skill](#the-pebble-agent-skill) and ask for a watchface. With
the Pebble SDK installed, start Claude Code, Codex or Cursor in an empty
directory and use a prompt like this:

```text
Install the Pebble agent skill from
https://github.com/coredevices/pebble-watchface-agent-skill (follow its
README), then use it to build a watchface for Pebble Time 2 that shows the
time in large digits with the date underneath. Build it, install it in the
emulator and show me a screenshot.
```

The agent clones the skill, copies it into the project, then creates the
watchface, runs `pebble build`, installs the result in the emulator with
`pebble install --emulator emery`, takes a screenshot with `pebble screenshot`
and compares it with the request before reporting back. Ask for changes in the
same session ("make the digits bold", "add a battery meter") and it repeats the
build and screenshot. To install on a watch, see
{% guide_link tools-and-resources/developer-connection %}.


## Documentation for Agents

Most guide and reference pages on this site have a Markdown version. Replace
the trailing `/` or `/index.html` of the page URL with `.md`. For example, the
Markdown version of
`https://developer.repebble.com/guides/events-and-services/buttons/` is
`https://developer.repebble.com/guides/events-and-services/buttons.md`. The
Markdown version has no navigation or scripts, and its links point to the
Markdown versions of the other pages.

[`/llms.txt`](/llms.txt) is an index of every page with a one-line
description, grouped by section. It starts with a short block that states the
current SDK version, the target platforms and what the SDK no longer
supports. Give an agent this URL and tell it to read the `.md` version of any
page it needs.

Larger files are available for agents that read a whole section at once:

| File | Contents |
|------|----------|
| [`/llms-full.txt`](/llms-full.txt) | Every page |
| [`/guides/llms-full.txt`](/guides/llms-full.txt) | All guides |
| [`/guides/alloy/llms-full.txt`](/guides/alloy/llms-full.txt) | The Alloy guides |
| [`/docs/c/llms-full.txt`](/docs/c/llms-full.txt) | The C API reference |
| [`/docs/pebblekit-js/llms-full.txt`](/docs/pebblekit-js/llms-full.txt) | The PebbleKit JS reference |

[`/api-index.json`](/api-index.json) lists every C and PebbleKit JS symbol
with its kind, signature, brief description, the platforms it is available on
and the page that documents it. Agents can look up a function there instead
of searching the reference pages.

Add a line like the following to a prompt or an instruction file. For
example:

```text
Pebble SDK docs: https://developer.repebble.com/llms.txt. Fetch the .md version of any page before using an API.
```


## Agent Instruction Files

Most agents read an instruction file from the project directory before they
start. `pebble new-project` writes these files when given the `--ai` flag:

```nc|text
$ pebble new-project --ai myproject
```

The command writes `CLAUDE.md` for Claude Code and `.cursor/rules/pebble.mdc`
for Cursor from the same template. The files describe the project layout,
the target platforms, the build, install and screenshot commands, how to use
the emulator without a display, and where the documentation is. The flag also
works with `--alloy` for an Alloy project.

To add the files to an existing project, run the command in another directory
and copy the files into the project.

Other agents read other file names. The content is the same, so copy
`CLAUDE.md` to the name the agent expects and edit the parts that describe the
project.


## The Pebble Agent Skill

[pebble-watchface-agent-skill](https://github.com/coredevices/pebble-watchface-agent-skill)
is a skill for Claude Code that builds complete watchfaces and watchapps from
a description. It chooses between a watchface and a watchapp and between C
and Alloy, writes the project files, runs `pebble build`, installs the result
in the emulator, takes a screenshot, checks the screenshot against the request
and repeats until it matches. It then generates the app icons and preview
images, and can publish the app with `pebble publish`.

The skill targets emery (Pebble Time 2) by default and supports the other
platforms as a second pass. Alloy projects are limited to emery and gabbro.

To install it, clone the repository and follow its README, which lists the
agents it supports.


## Working with the Emulator

An agent can check its own work when it can install the app and see the
screen. These commands do that without a physical watch:

```nc|text
$ pebble build
$ pebble install --emulator emery
$ pebble screenshot --no-open --emulator emery screenshot.png
$ pebble emu-button click select --emulator emery
$ pebble logs --emulator emery
```

`pebble screenshot --no-open` saves the image without opening it in a viewer,
so the agent can read the file. `pebble emu-button` presses `back`, `up`,
`select` or `down`; use `--duration` for a long press and `--repeat` to scroll.
`pebble logs` shows `APP_LOG()` output from the running app.

In an environment without a display, such as a container or CI, add `--vnc`
to every command that uses `--emulator`.

If the emulator gets into a strange state, such as a screenshot that shows a
different app or an install that times out, `pebble kill` stops it and
`pebble wipe` resets its storage; then install again.

> Note: `pebble screenshot` does not create directories. Create the output
> directory before taking a screenshot into it.


## Target Platforms and the SDK Version

State the SDK version and the target platforms in the instruction file or the
prompt, together with the following:

* The target platforms, as listed in `targetPlatforms` in `package.json`. The
  current platforms are aplite, basalt, chalk, diorite, emery, flint and
  gabbro. See {% guide_link tools-and-resources/hardware-information %} for
  screen sizes and colors, and
  {% guide_link best-practices/building-for-every-pebble %} for the
  compile-time defines.

* The SDK version. The current version is {{ site.data.sdk.c.version }};
  `pebble sdk list` lists the available SDK versions.

* Alloy runs on emery and gabbro only. A project that targets older watches
  has to be written in C.

* The timeline web API is no longer available. The Pebble mobile app does not
  sync pins from a server. Use
  {% guide_link pebble-timeline/timeline-local-pins "local pins" %} instead.
