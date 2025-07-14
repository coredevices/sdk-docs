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

title: Example Implementations
description: |
  Resources and code samples to implement common design and UI patterns.
guide_group: design-and-interaction
menu: true
permalink: /guides/design-and-interaction/implementation/
generate_toc: true
order: 4
---

This guide contains resources and links to code examples that may help
developers implement UI designs and interaction patterns recommended in the
other guides in this section.


## UI Components and Patterns

Developers can make use of the many UI components available in SDK 3.x in
combination with the
{% guide_link design-and-interaction/recommended#common-design-styles "Common Design Styles" %} 
to ensure the user experience is consistent and intuitive. The following
components and patterns are used in the Pebble experience, and listed in the
table below. Some are components available for developers to use in the SDK, or
are example implementations designed for adaptation and re-use.

| Pattern | Screenshot | Description |
|---------|------------|-------------|
| [`Menu Layer`](``MenuLayer``) | ![](/images/guides/design-and-interaction/menulayer.png) | Show many items in a list, allow scrolling between them, and choose an option. |
| [`Status Bar`](``StatusBarLayer``) | ![](/images/guides/design-and-interaction/alarm-list~basalt.png) | Display the time at the top of the Window, optionally extended with additional data. |
| [`Radio Button List`]({{site.links.examples_org}}/ui-patterns/blob/master/src/windows/radio_button_window.c) | ![](/images/guides/design-and-interaction/radio-button.png) | Allow the user to specify one choice out of a list. |
| [`Checkbox List`]({{site.links.examples_org}}/ui-patterns/blob/master/src/windows/checkbox_window.c) | ![](/images/guides/design-and-interaction/checkbox-list.png) | Allow the user to choose multiple different options from a list. |
| [`List Message`]({{site.links.examples_org}}/ui-patterns/blob/master/src/windows/list_message_window.c) | ![](/images/guides/design-and-interaction/list-message.png) | Provide a hint to help the user choose from a list of options. |
| [`Message Dialog`]({{site.links.examples_org}}/ui-patterns/blob/master/src/windows/dialog_message_window.c) | ![](/images/guides/design-and-interaction/dialog-message.gif) | Show an important message using a bold fullscreen alert. |
| [`Choice Dialog`]({{site.links.examples_org}}/ui-patterns/blob/master/src/windows/dialog_choice_window.c) | ![](/images/guides/design-and-interaction/dialog-choice-patterns.png) | Present the user with an important choice, using the action bar and icons to speed up decision making. |
| [`PIN Entry`]({{site.links.examples_org}}/ui-patterns/blob/master/src/windows/pin_window.c) | ![](/images/guides/design-and-interaction/pin.png) | Enable the user to input integer data. |
| [`Text Animation`]({{site.links.examples_org}}/ui-patterns/blob/master/src/windows/text_animation_window.c) | ![](/images/guides/design-and-interaction/text-change-anim.gif) | Example animation to highlight a change in a text field. |
| [`Progress Bar`]({{site.links.examples_org}}/ui-patterns/blob/master/src/windows/progress_bar_window.c) | ![](/images/guides/design-and-interaction/progress-bar.gif) | Example progress bar implementation on top of a ``StatusBarLayer``. |
| [`Progress Layer`]({{site.links.examples_org}}/ui-patterns/blob/master/src/windows/progress_layer_window.c) | ![](/images/guides/design-and-interaction/progresslayer.gif) | Example implementation of the system progress bar layer. |


## Example Apps

Developers can look at existing apps to begin to design (or improve) their user
interface and interaction design. Many of these apps can be found on the
appstore with links to their source code, and can be used as inspiration.


### Cards Example (Weather)

The weather [`cards-example`]({{site.links.examples_org}}/cards-example)
embodies the 'card' design pattern. Consisting of a single layout, it displays
all the crucial weather-related data in summary without the need for further
layers of navigation. Instead, the buttons are reserved for scrolling between
whole sets of data pertaining to different cities. The number of 'cards' is
shown in the top-right hand corner to let the user know that there is more data
present to be scrolled through, using the pre-existing Up and Down button action
affordances the user has already learned. This helps avoid implementing a novel
navigation pattern, which saves time for both the user and the developer.

![weather >{pebble-screenshot,pebble-screenshot--time-red}](/images/guides/design-and-interaction/weather.gif)

When the user presses the appropriate buttons to scroll through sets of data,
the changing information is animated with fast, snappy, and highly visible
animations to reinforce the idea of old data moving out of the layout and being
physically replaced by new data.
