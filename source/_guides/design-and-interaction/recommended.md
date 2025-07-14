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

title: Recommended Guidelines and Patterns
description: |
  Pebble's recommended guidelines for creating awesome app experiences.
guide_group: design-and-interaction
menu: true
permalink: /guides/design-and-interaction/recommended/
generate_toc: true
order: 2
---

This page contains recommendations for things to consider when designing an
app's visual styles and interaction patterns. The aim here is to encourage
efficiency through optional conformity to common ideas and concepts, and to
breed a consistent experience for users across apps. Developers can also find
suggested interface styles to use when building the navigation of apps to best
display the information contained within.


## Tips for UI Design

To achieve an effective, clear, and intuitive design developers should:

* Keep layouts **simple**, with only as much information displayed as is
  **immediately required**. This encourages quick usage of the app, distracting
  the user for the minimal amount of time necessary for the app to achieve its
  goals.

* Give priority to the **most commonly used/main purpose** functionality of the
  app in the UI. Make it easy to use the biggest features, but still easy to
  find additional functionality that would otherwise be hidden.

* Use **larger fonts** to highlight the **most important data** to be read at a
  glance. Consider font size 28 for larger items, and a minimum of 18 for
  smaller ones.

* Take advantage of colors to convey additional **information without any text**
  if they are already associated as such, such as green for a task complete.

* Try to avoid any colors used in places they may have a **pre-conceived
  meaning** which does not apply, such as red text when there are no errors.

* Use animations to embody the layout with **character** and flourish, as well
  as to **draw the eye** to updated or changing information.

* Ensure the UI gives **direct feedback** to the user's input, or else they may
  think their button presses are having no effect.


## Tips for UI Interaction

* Avoid using the Pebble buttons for actions **not** already associated with
  them, unless clearly marked in the UI using an ``ActionBarLayer`` or similar
  method. When using the Up and Down buttons for 'previous item' and 'next item'
  respectively, there may be no need for a visual cue.

* Use iconography with **pre-existing visual associations** (such as a 'stop'
  icon) to take advantage of the inherent behavior the user will have when
  seeing it. This can avoid the need for explicit instructions to train the user
  for an app's special case.

* Ensure the navigation between app ``Window``s is **logical** with the input
  given and the information displayed. For example, an app showing bus
  timetables should use higher level screens for quickly navigating to a
  particular area/station, with lower level views reserved for scrolling through
  the actual timetable data.

* If possible, **preserve the state of the app** and/or previous navigation if
  the app is commonly used for a repetitive task. In the bus timetable example,
  the user may only look up two stations for a to-from work journey. Learn this
  behavior and store it with the [Persistent Storage API](``Storage``) to
  intelligently adapt the UI on subsequent launches to show the relevant
  information. This helps the user avoid navigating through multiple menus every
  time they launch the app.


## Common Design Styles

The following are common design styles that have been successfully used in
system and 3rd party apps, and are recommended for use in the correct manner.


### Display Data Sets Using Cards

![card >{pebble-screenshot,pebble-screenshot--time-red}](/images/guides/design-and-interaction/card.gif)

The 'card' style aims to reduce the number of menu levels needed to access as
much relevant information as possible. Instead of a menu to select a data set
leading to a menu to explore each item in that set, a single ``Window`` is
designed that displays an entire data set. This view then uses the Pebble Up and
Down buttons to scroll through complete data sets in an array of many sets.

An example of this is the
{% guide_link design-and-interaction/implementation#cards-example-weather "cards-example" %} 
example app, which displays all weather data in a single view and pages through
sets of data for separate locations with the Up and Down buttons. This style of
UI design allows access to lots of information without navigating through
several menus to view it.


### List Options with a Menu

{% screenshot_viewer %}
{
  "image": "/images/guides/design-and-interaction/list.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}
{% endscreenshot_viewer %}

The style is one of the most basic, tried and true styles. Using the
``MenuLayer`` UI component, the user may choose between multiple app functions
by scrolling with the Up and Down buttons, an interaction pattern afforded to
the developer by the core system experience. Using a menu, a user can navigate
straight to the part of the app or specific action they want.


### Execute Actions with an ActionBarLayer

{% screenshot_viewer %}
{
  "image": "/images/guides/design-and-interaction/actionbar.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}
{% endscreenshot_viewer %}

The ``ActionBarLayer`` allows easy association of app functionality with the
Pebble buttons. By setting icons to each of the three positions, a user can see
which actions they can perform at a glance and execture them with a single
button press. When pressed, the icon is animated to provide immediate visual
feedback.

An example of this is the system Music app, that uses the ``ActionBarLayer`` to
inform the user that the Up and Down buttons skip tracks. In this case, the
Select button is displayed with elipses, indicating further actions are
available. A press of this button changes the set of actions on the Up and Down
buttons, enabling them to modify the playback volume instead.

A collection of icons for common actions is available for use by developers, and
can be found in the {% guide_link app-resources/app-assets %} guide.


### Allow Extended Options with an Action Menu

![actionmenu](/images/guides/design-and-interaction/actionmenu.png)

If an app screen demands a larger range of available actions than the
``ActionBarLayer`` will allow, present these as a list that slides into
view with a press of the Select button using an action menu. This menu contains
all the available options, and can contain multiple sub-menus, providing levels.
The user can keep track of which level they are currently looking at using the
breadcrumb dots on the left-hand side of the screen when the action menu is
displayed.

Once an action has been chosen, the user should be informed of the success or
failure of their choice using a new alert dialog window. In the system action
menus, these screens use an eye-catching animation and bold label to convey the
result of the action. This feedback is important to prevent the user from
getting frustrated if they perceive their input has no result, as well as to
reassure them that their action has succeeded without a problem.


### Get User Input with a Form

![list](/images/guides/design-and-interaction/alarm-list-config.png)

Apps such as the system Alarm app make use of a list of configurable items, with
each active alarm treated as a menu item with properties. The status of each
item is displayed in a menu, with the Select button initiating configuration of
that item.

When an item is being configured, the data requried to create the item should be
obtained from the user through the use of a form, with manipulable elements. In
the Alarms example, each integer required to schedule an alarm is obtained with
a number field that can have its value incrememted or decremented using the
intuitive Up and Down buttons. The current form element is highlighted with
color, and advancing to the next element is done with the Select button,
doubling as a 'Confirm' action when the end of the form is reached.


### Prompting User Action on the Phone

In some applications, user input is required in the app's configuration page (as
detailed in {% guide_link user-interfaces/app-configuration %}) before the app
can perform its task. An example of this is a feed reader app, that will need
the user to input the URL of their preferred news feed before it can fetch the
feed content. In this case, the watchapp should display a prominent (full-
screen if possible) dialog telling the user that input to the phone app for
configuration is required.

![action-required >{pebble-screenshot,pebble-screenshot--time-red}](/images/guides/design-and-interaction/action-required.png)

Once the user has performed the required action on the phone, the
[`webviewclosed`](/guides/communication/using-pebblekit-js/)
event should signify that the app can proceed, and that the required data is now
available.

It should not be the case that this action is required every time the app is
started. In most cases, the input data from the user can be stored with
[Peristent Storage](``Storage``) on the watch, or
[`localStorage`](/guides/communication/using-pebblekit-js/)
on the phone. If the app must get input on every launch (such as a mode
selection), this should be done through a form or menu on the watch, so as to
avoid needing to use the phone.


### Show Time and Other Data with the Status Bar

{% screenshot_viewer %}
{
  "image": "/images/guides/design-and-interaction/alarm-list.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}
{% endscreenshot_viewer %}

Under SDK 2.x, the status bar was displayed to users in all menus and watchapps
except watchfaces, or where the developer had explicitly disabled it. This was
useful for showing the time and battery level, but arguably not essential all
the time.

In SDK 3.x, only apps that are designed to be running for extended periods of
time (such as Music and the Sports API app) show the time, using the
``StatusBarLayer`` UI component. The battery level can easily be seen from the
Settings appface, and so it not necessary to be always visible. Another instance
where the status bar is neccessary is in the Alarms app (shown above), where the
user may need to compare with the current time when setting an alarm.

If a constant, minimalistic display of app data is required, the
``StatusBarLayer`` can be used to perform this task. It provides a choice of
separator mode and foreground/background colors, and can also be made
transparent. Since is it just another ``Layer``, it can be easily extended with
additional text, icons, or other data.

For example, the
[`cards-example`]({{site.links.examples_org}}/cards-example) app uses an
extention of the status bar to display the currently selected 'card' (a set of
displayed data). Another example is the progress bar component example from the
[`ui-patterns`]({{site.links.examples_org}}/ui-patterns) app, which
builds upon the dotted separator mode to become a thin progress bar.

When used in conjunction with the ``ActionBarLayer`` (for example, in the Music
system app), the width of the underlying layer should be adjusted such that the
time displayed is shown in the new center of the app area (excluding that taken
up by the action bar itself).


### Show Alerts and Get Decisions with Modal Windows

![dialog-message >{pebble-screenshot,pebble-screenshot--time-red}](/images/guides/design-and-interaction/dialog-message.gif)

When a significant event occurs while using an app, it should be made visible to
the user through the use of a full-screen model dialog. In a similar way that
notifications and reminders alert the user to events, these layouts consist of
only the important information and an associated icon telling the user the
source of the alert, or the reason for its occurrence. This pattern should also
be used to quickly and efficently tell the user that an app-related error has
occured, including steps on how to fix any potential problems.

These alerts can also take the form of requests for important decisions to be
made by the user, such as to remember a choice as the default preference:

{% screenshot_viewer %}
{
  "image": "/images/guides/design-and-interaction/dialog-choice-window.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}
{% endscreenshot_viewer %}

In this way the decision can be passed to the user with an immediately obvious
and actionable set of choices. One the choice has been made, the modal window is
dismissed, and a confirmation of the choice displayed. The user should then be
returned to the previous window to resume their use of the app where they left
off.


### Using Vibrations and Haptic Feedback

The Pebble SDK allows the use of the vibration motor to deliver haptic feedback
to the user. This can take the form of short, long, double pulses or more
detailed vibration sequences, allowing a lot of customization as well as
variation between apps.

To encourage a consistent experience for users, the ``Vibes`` API should be used
with the following points in mind:

* A short pulse should be used to alert the user to the end of a long-running
  in-app event, such as a download completing, preferably when they are not
  looking at the watch.

* A long pulse should be used to alert the user to a failure or error that
  requires attention and some interaction.

* Custom vibration patterns should be used to allow the user to customize haptic
  feedback for different events inside the app.

When the app is open and being actively interacted with no vibration or haptic
feedback should be neccessary on top of the existing visual feedback. However,
some exceptions may occur, such as for visually-impaired users. In these cases
haptic feedback may be very useful in boosting app accessibility.


### Handling Connection Problems

When a watchapp is running, there is no guarantee that the phone connection will
be available at any one time. Most apps will function without this connection,
but if PebbleKit JS, Android, or iOS is required, the user must be informed of
the reason for failure so that they can correct the problem. This check can be
performed at any time using ``connection_service_peek_pebble_app_connection()``.

An example alert layout is shown below.

{% screenshot_viewer %}
{
  "image": "/images/guides/design-and-interaction/no-bt-connection.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}
{% endscreenshot_viewer %}

A similar situation arises if an app that requires information or responses from
a remote web service attempts to do so, but the phone has no Internet
connection. This may be because the user has opted to disable their data
connections, or they may be out of range.

Another example alert layout is shown below for this situation.

{% screenshot_viewer %}
{
  "image": "/images/guides/design-and-interaction/no-inet-connection.png",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"}
  ]
}
{% endscreenshot_viewer %}

If these kinds of situations can cause problems for the operation of the app,
consider using the [`Persistent Storage`](``Storage``) API to cache the most
recently loaded data (such as weather, sports scores or news items) from the
last successful launch, and display this to the user (while making them aware of
the data's age) until new data can be obtained.


### Hiding Timeline-only Apps

Watchapps that consist only of a {% guide_link pebble-timeline "Pebble timeline" %} 
experience will only need to be launched when configured by the user to select
topic subscriptions. In these cases, developers should hide their app from the
launcher menu to prevent the user needlessly launching it.

To find out how to do this using the `hiddenApp` property, see 
{% guide_link tools-and-resources/app-metadata %}.


## Consistent App Configuration

Watchapps and watchfaces that include user configuration normally include a web
page hosted by the app developer, allowing the user to choose from a set of
options and apply them to the app. Such options include aesthetic options such
as color schemes, larger font sizes, replacement images, data source choices,
and others. Traditionally the design of these pages has been left entirely to
the developer on a per-app basis, and this is reflected in the resulting design
consistency.

Read {% guide_link user-interfaces/app-configuration %} to learn more about
configuration page design and implementation.


## What's Next?

Read {% guide_link design-and-interaction/in-the-round %} to read tips and
guidance on designing apps that work well on a round display.
