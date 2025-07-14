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

title: Service Architecture
description: |
  Find out what the timeline is, how it works and how developers can take
  advantage of it in their apps.
guide_group: pebble-timeline
order: 4
---

Every item on the timeline is called a 'pin'. A pin can have information
attached to it which is used to show it to the user, such as layout, title,
start time and actions. When the user is viewing their timeline, they can use
the information provided about the immediate past and future to make decisions
about how they plan the rest of their day and how to respond to any missed
notifications or events.

While the system and mobile application populate the user's timeline
automatically with items such as calendar appointments and weather details, the
real value of the timeline is realized by third party apps. For example, a
sports app could show a pin representing an upcoming match and the user could
tell how much time remained until they needed to be home to watch it.

Developers can use a watchapp to subscribe their users to one of two types pin:

* Personal pins pushed to a user's timeline token. These pins are only delivered
  to the user the token belongs to, allows a high degree of personalization in
  the pin's contents.

* Channels called 'topics' (one more more, depending on their preferences),
  allow an app to push pins to a large number of users at once. Topics are
  created on a per-app basis, meaning a user receiving pins for a 'football'
  topic from one app will not receive pins from another app using the same topic
  name.

Developers can use the PebbleKit JS API to combine the user's preferences with
their location and data from other web-connected sources to make pin updates
more personal, or more intelligently delivered.

The public timeline web API is used to push data from a own backend server to
app users according to the topics they have subscribed to, or to individual
users. Methods for doing this are discussed below under 
[Three Ways to Use Pins](#three-ways-to-use-pins).


## Architecture Overview

![diagram](/images/guides/3.0/timeline-architecture.png)

The timeline architecture consists of multiple components that work together to
bring timely and relevant data, events, and notifications to the user without
their intervention. These components are discussed in more detail below.


### Public Web API

The Pebble timeline web API (detailed in 
{% guide_link pebble-timeline/timeline-public %}) manages the currently
available topics, published pins, and timeline-enabled apps' data. All pins that
are delivered to users pass through this service. When a developer pushes a pin
it is sent to this service for distribution to the applicable users.


### Pebble Mobile App

The Pebble mobile app is responsible for synchronizing the pins visible on the
watch with those that are currently available in the cloud. The PebbleKit JS
APIs allow a developer to use a configuration page (detailed in 
{% guide_link user-interfaces/app-configuration %}) or onboard menu to give
users the choice of which pins they receive via the topics they are subscribed
to. Developers can also send the user's token to their own server to maintain a
custom list of users, and provide a more personal service.

The Pebble mobile app is also responsible for inserting pins directly into the
user's timeline for their upcoming calendar events and missed calls. These pins
originate on the phone and are sent straight to the watch, not via the public
web API. Alarm pin are also inserted directly from the watch itself.


### Developer's App Server/Service

When a developer wants to push pins, they can do so from their own third-party
server. Such a server will generate pins using topics that the watchapp
subscribes to (either for all users or just those that elect to be subscribed)
or user tokens received from PebbleKit JS to target individual users. See
{% guide_link pebble-timeline/timeline-public %} for information on
how to do this.


## Three Ways to Use Pins

The timeline API is flexible enough to enable apps to use it to send data to
users in three distinct ways.


### Push to All Users

![all-users](/images/guides/timeline/all-users.png)

The most basic subscription method involves subscribing a user to a topic that
is global to the app. This means all users of the app will receive the pins
pushed to that topic. To do this, a developer can choose a single topic name
such as 'all-users' and subscribe all users to that topic when the app is first
installed, or the user opts in to receive pins.

Read {% guide_link pebble-timeline/timeline-public#shared-pins "Shared Pins" %} 
to find out how to create topics.


### Let Users Choose Their Pins

![some-users](/images/guides/timeline/some-users.png)

Developers can also use a configuration page in their app to allow users to
subscribe to different topics, leeting them customize their experience and only
receive pins they want to see. In the image above, the pin broadcast with the
topic 'baseball' is received by users 1 and 3, but not User 2 who has only
subscribed to the 'golf' topic.


### Target Individual Users

![individual](/images/guides/timeline/individual.png)

Lastly, developers can use the timeline token to target individual users. This
adds another dimension to how personal an app can become, allowing apps to be
customized to the user in more ways than just their topic preferences. The image
above shows a pin pushed from an app's pin server to just the user with the
matching `X-User-Token`. For example, an app tracking the delivery of a user's
packages will only be applicable to that user.

See {% guide_link pebble-timeline/timeline-public#create-a-pin "Create a Pin" %} 
to learn how to send a pin to a single user.
