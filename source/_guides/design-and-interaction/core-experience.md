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

title: Core Experience Design
description: |
  How design guidelines shape the core Pebble app experience.
guide_group: design-and-interaction
menu: true
permalink: /guides/design-and-interaction/core-experience/
generate_toc: true
order: 1
---

The core Pebble experience includes several built-in system apps that use
repeatable design and interaction concepts in their implementation. These
are:

* Apps are designed with a single purpose in mind, and they do it well.

* Fast animations are used to draw attention to changing or updating
  information.

* Larger, bolder fonts to highlight important data.

* A preference for displaying multiple data items in a paginated format rather
  than many 'menus within menus'. This is called the 'card' pattern and is
  detail in
  {% guide_link design-and-interaction/recommended#display-data-sets-using-cards "Display Data Sets Using Cards" %}.

* Colors are used to enhance the app's look and feel, and are small in number.
  Colors are also sometimes used to indicate state, such as the temperature in a
  weather app, or to differentiate between different areas of a layout.


## System Experience Design

The core system design and navigation model is a simple metaphor for time on the
user's wrist - a linear representation of the past, present, and future. The
first two are presented using the timeline design, with a press of the Up button
displaying past events (also known as pins), and a press of the Down button
displaying future events. As was the case for previous versions of the system
experience, pressing the Select button opens the app menu. This contains the
system apps, such as Music and Notifications, as well as all the 3rd party apps
the user has installed in their locker.

![system-navigation](/images/guides/design-and-interaction/system-navigation.png)

Evidence of the concepts outlined above in action can be seen within the core
system apps in firmware 3.x. These are described in detail in the sections
below.


### Music

![music](/images/guides/design-and-interaction/music.png)

The Music app is designed with a singular purpose in mind - display the current
song and allow control over playback. To achieve this, the majority of the
screen space is devoted to the most important data such as the song title and
artist. The remainder of the space is largely used to display the most immediate
controls for ease of interaction in an action bar UI element.

The 'previous track' and 'next track' icons on the action bar are ones with
pre-existing affordances which do not require specific instruction for new users
thanks to their universal usaging other media applications. The use of the '...'
icon is used as an additional commonly understood action to indicate more
functionality is available. By single-pressing this action, the available
actions change from preview/next to volume up/volume down, reverting on a
timeout. This is preferable to a long-press, which is typically harder to
discover without an additional prompt included in the UI.

A press of the Back button returns the user to the appface menu, where the Music
appface displays the name and artist of the currently playing track, in a
scrolling 'marquee' manner. If no music is playing, no information is shown
here.


### Notifications

![notifications](/images/guides/design-and-interaction/notifications.png)

The system Notifications app allows a user to access all their past received
notifications in one place. Due to the fact that the number of notifications
received can be either small or large, the main view of the app is implemented
as a menu, with each item showing each notification's icon, title and the first
line of the body content. In this way it is easy for a user to quickly scroll
down the list and identify the notification they are looking for based on these
first hints.

The first item in the menu is a 'Clear All' option, which when selected prompts
the user to confirm this action using a dialog. This dialog uses the action bar
component to give the user the opportunity to confirm this action with the
Select button, or to cancel it with the Back button.

Once the desired item has been found, a press of the Select button opens a more
detailed view, where the complete notification content can be read, scrolling
down if needed. The fact that there is more content available to view is hinted
at using the arrow marker and overlapping region at the bottom of the layout.


### Alarms

![alarms](/images/guides/design-and-interaction/alarms.png)

The Alarms app is the most complex of the system apps, with multiple screens
dedicated to input collection from the user. Like the Watchfaces and Music apps,
the appface in the system menu shows the time of the next upcoming scheduled
alarm, if any. Also in keeping with other system apps, the main screen is
presented using a menu, with each item representing a scheduled alarm. Each
alarm is treated as a separate item, containing different settings and values.

A press of the Select button on an existing item will open the action menu
containing a list of possible actions, such as 'Delete' or 'Disable'. Pressing
Select on the top item ('+') will add a new item to the list, using multiple
subsequent screens to collect data about the alarm the user wishes to schedule.
Using multiple screens avoids the need for one screen to contain a lot of input
components and clutter up the display. In the time selection screen, the current
selection is marked using a green highlight. The Up and Down buttons are used to
increase and decrease the currently selected field respectively.

Once a time and recurring frequency has been chosen by the user, the new alarm
is added to the main menu list. The default state is enabled, marked by the word
'ON' to the right hand side, but can be disabled in which case 'OFF' is
displayed instead.


### Watchfaces

![watchfaces](/images/guides/design-and-interaction/watchfaces.png)

The Watchfaces system app is similar to the Notifications app, in that it uses a
menu as its primary means of navigation. Each watchface available in the user's
locker is shown as a menu item, with a menu icon if one has been included by the
watchface developer. The currently active watchface is indicated by the presence
of 'Active' as that item's subtitle.

Once the user has selected a new watchface, they are shown a confirmation dialog
to let them know their choice was successful. If the watchface is not currently
loaded on the watch, a progress bar is shown briefly while the data is loaded.
Once this is done the newly chosen watchface is displayed.


### Settings

![settings](/images/guides/design-and-interaction/settings.png)

The Settings app uses the system appface to display the date, the battery charge
level, and the Bluetooth connection without the need to open the app proper. If
the user does open the app, they are greeted with a menu allowing a choice of
settings category. This approach saves the need for a single long list of
settings that would require a lot of scrolling.

Once a category has been chosen, the app displays another menu filled with
interactive menu rows that change various settings. Each item shows the name of
the setting in bold as the item title, with the current state of the setting
shown as the subtitle.

When the user presses Select, the state of the currently selected setting is
changed, usually in a binary rotation of On -> Off states. If the setting does
not operate with a binary state (two states), or has more than two options, an
action menu window is displayed with the available actions, allowing the user to
select one with the Select button.

A press of the Back button from a category screen returns the user to the
category list, where they can make another selection, or press Back again to
return to the app menu.


### Sports API

{% screenshot_viewer %}
{
  "image": "/images/guides/design-and-interaction/sports.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}
{% endscreenshot_viewer %}

The Sports API app is designed around displaying the most immediate relevant
data of a particular sporting activity, such as running or cycling. A suitable
Android or iOS companion app pushes data to this app using the
{% guide_link communication/using-the-sports-api "PebbleKit Sports API" %}
at regular intervals. This API enables third-party sports app developers to
easily add support for Pebble without needing to create and maintain their own
watchapp.

The high contrast choice of colors makes the information easy to read at a
glance in a wide variety of lighting conditions, ideal for use in outdoor
activities. The action bar is also used to present the main action available to
the user - the easily recognizable 'pause' action to suspend the current
activity for a break. This is replaced by the equally recognizable 'play' icon,
the action now used to resume the activity.

This API also contains a separate Golf app for PebbleKit-compatible apps to
utilize in tracking the user's golf game.

{% screenshot_viewer %}
{
  "image": "/images/guides/design-and-interaction/golf.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}
{% endscreenshot_viewer %}

The Golf app uses a similar design style with larger fonts for important numbers
in the center of the layout, with the action bar reserved for additional input,
such as moving between holes. Being an app that is intended to be in use for
long periods of time, the status bar is used to display the current time for
quick reference without needing to exit back to the watchface.


## Timeline Experience Design

Evidence of guided design can also be found in other aspects of the system, most
noticeably the timeline view. With pins containing possibly a large variety of
types of information, it is important to display a view which caters for as many
types as possible. As detailed in
{% guide_link pebble-timeline/pin-structure "Creating Pins" %},
pins can be shown in two different ways; the event time, icon and title on two
lines or a single line, depending on how the user is currently navigating the
timeline. When a pin is highlighted, as much information is shown to the user as
possible.

![timeline](/images/guides/design-and-interaction/timeline.png)

Users access the timeline view using Up and Down buttons from the watchface to
go into the past and future respectively. The navigation of the timeline also
uses animations for moving elements that gives life to the user interface, and
elements such as moving the pin icon between windows add cohesion between the
different screens. A press of the Select button opens the pin to display all the
information it contains, and is only one click away.

A further press of the Select button opens the pin's action menu, containing a
list of all the actions a user may take. These actions are directly related to
the pin, and can be specified when it is created. The system provides two
default actions: 'Remove' to remove the pin from the user's timeline, and 'Mute
[Name]' to mute all future pins from that source. This gives the user control
over which pins they see in their personal timeline. Mute actions can be
reversed later in the mobile app's 'Apps/Timeline' screen.


## What's Next?

Read {% guide_link design-and-interaction/recommended %} for tips on creating an
intuitive app experience.
