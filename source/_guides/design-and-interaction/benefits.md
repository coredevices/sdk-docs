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

title: Benefits of Design Guidelines
description: |
  Learn the main concepts of design guidelines, why they are needed, and how
  they can help developers.
guide_group: design-and-interaction
menu: true
permalink: /guides/design-and-interaction/benefits/
generate_toc: true
order: 0
---

## What are Design Guidelines?

Design guidelines are a set of concepts and rules used to create an app's user
interface. These define how the layout on-screen at any one time should be used
to maximize the efficiency of presenting data to the user, as well as quickly
informing them how to choose their next action. An app creator may look to other
popular apps to determine how they have helped their users understand their
app's purpose, either through the use of iconography or text highlighting. They
may then want to use that inspiration to enable users of the inspiring app to
easily use their own app. If many apps use the same visual cues, then future
users will already be trained in their use when they discover them.


## What are Interaction Patterns?

Similar to design guidelines, interaction patterns define how to implement app
interactivity to maximize its efficiency. If a user can predict how the app will
behave when they take a certain action, or be able to determine which action
fits that which they want to achieve without experimentation, then an intuitive
and rewarding experience will result.

In addition to purely physical actions such as button presses and accelerometer
gestures, the virtual navigation flow should also be considered at the design
stage. It should be intuitive for the user to move around the app screens to
access the information or execute the commands as they would expect on a first
guess. An easy way to achieve this is to use a menu with the items clearly
labelling their associated actions. An alternative is to use explicit icons to
inform the user implicitly of their purpose without needing to label them all.


## Why are They Needed?

Design guidelines and interaction patterns exist to help the developer help the
user by ensuring user interface consistency across applications on the platform.
It is often the case that the developer will have no problem operating their own
watchapp because they have been intimately familiar with how it is supposed to
work since its inception. When such an app is given to users, they may receive
large amounts of feedback from confused users who feel they do not know if an
app supports the functionality they though it did, or even how to find it. By
considering a novice user from the beginning of the UI design and
implementation, this problem can be avoided.

A Pebble watchapp experience is at its best when it can be launched, used for
its purpose in the smallest amount of time, and then closed back to the
watchface. If the user must spend a long time navigating the app's UI to get to
the information they want, or the information takes a while to arrive on every
launch, the app efficiency suffers. To avoid this problem, techniques such as
implementing a list of the most commonly used options in an app (according to
the user or the whole user base) to aid fast navigation, or caching remotely
fetched data which may still be relevant from the last update will improve the
user experience.

From an interaction pattern point of view, a complex layout filled with abstract
icons may confuse a first-time user as to what each of them represents. Apps can
mitigate this problem by using icons that have pre-established meanings across
languages, such as the 'Play/Pause' icon or the 'Power' icon, seen on many forms
of devices.


## What Are the Benefits?

The main benefits of creating and following design guidelines and common
interaction patterns are summarized as follows:

* User interface consistency, which breeds familiarity and predictability.

* Clarity towards which data is most important and hence visible and usable.

* Reduced user confusion and frustration, leading to improved perception of
  apps.

* No need to include explicit usage instructions in every app to explain how it
  must be used.

* Apps that derive design from the system apps can benefit from any learned
  behavior all Pebble users may develop in using their watches out the box.

* Clearer, more efficient and better looking apps!


## Using Existing Affordances

Developers can use concepts and interaction patterns already employed in system
apps and popular 3rd party apps to lend those affordances to your own apps. An
example of this in mobile apps is the common 'swipe down to refresh' action. By
using this action in their app, many mobile app makers can benefit from users
who have already been trained to perform this action, and can free up their
app's UI for a cleaner look, or use the space that would have been used by a
'refresh' button to add an additional feature.

In a similar vein, knowing that the Back button always exits the current
``Window`` in a Pebble app, a user does not have to worry about knowing how to
navigate out of it. Similarly, developers do not have to repeatedly implement
exiting an app, as this action is a single, commonly understood pattern - just
press the Back button! On the other hand, if a developer overrides this action a
user may be confused or frustrated when the app fails to exit as they would
expect, and this could mean a negative opinion that could have been avoided.


## What's Next?

Read {% guide_link design-and-interaction/core-experience %} to learn how design
guidelines helped shape the core Pebble system experience.
