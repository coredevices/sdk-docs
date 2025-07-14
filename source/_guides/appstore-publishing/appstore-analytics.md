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

title: Appstore Analytics
description: |
  How to view and use analytics about your app's usage.
guide_group: appstore-publishing
order: 2
---

After publishing an app, developers can view automatic analytical data and
graphs for a variety of metrics. These can be used to help track the performance
of an app, identify when crashes start occuring, measure how fast an update is
adopted, or which platforms are most popular with users.

> Due to latencies in the analytics gathering process, data from the last 7 days
> may not be very accurate.


## Available Metrics

Several different metrics are available to developers, and are reported on a
daily basis. These metrics can be sorted or viewed according to a number of
categories:

* App version - Which release of the app the user is running.

* Hardware platform - Which Pebble hardware version the user is wearing.

* Mobile platform - Which mobile phone platform (such as Android or iOS) the
  user is using.

An example graph is shown with each metric type below, grouped by hardware
platform.


### Installations

The total number of times an app has been installed.

![installations-example](/images/guides/appstore-publishing/installations-example.png)


### Unique Users

The total number of unique users who have installed the app. This is
different to the installation metric due to users installing the same app
multiple times.

![unique-users-example](/images/guides/appstore-publishing/unique-users-example.png)


### Launches

The total number of times the app has been launched.

![launches-example](/images/guides/appstore-publishing/launches-example.png)


### Crash Count

The total number of times the app has crashed. Use the filters to view
crash count by platform or app version to help identify the source of a crash.

![crash-count-example](/images/guides/appstore-publishing/crash-count-example.png)


### Run Time

The total run time of the app in hours.

![run-time-example](/images/guides/appstore-publishing/run-time-example.png)


### Run Time per launch

The average run time of the app each time it was launched in minutes.

![run-time-per-launch-example](/images/guides/appstore-publishing/run-time-per-launch-example.png)


### Buttons Pressed Per Launch

> Watchfaces only

The average number of button presses per launch of the app.

![buttons-pressed-example](/images/guides/appstore-publishing/buttons-pressed-example.png)


### Timeline: Users Opening Pin

> Timeline-enabled apps only

The number of users opening timeline pins associated with the app.

![opening-pin-example](/images/guides/appstore-publishing/opening-pin-example.png)


### Timeline: Pins Opened

> Timeline-enabled apps only

The number of timeline pins opened.

![pins-opened-example](/images/guides/appstore-publishing/pins-opened-example.png)


### Timeline: Users Launching App from Pin

> Timeline-enabled apps only

The number of users launching the app from a timeline pin.

![launching-app-from-pin-example](/images/guides/appstore-publishing/launching-app-from-pin-example.png)


### Timeline: Times App Launched from Pin

> Timeline-enabled apps only

Number of times the app was launched from a timeline pin.

![times-launched-example](/images/guides/appstore-publishing/times-launched-example.png)


## Battery Stats

In addition to installation, run time, and launch statistics, developers can
also view a battery grade for their app. Grade 'A' is the best available,
indicating that the app is very battery friendly, while grade 'F' is the
opposite (the app is severely draining the user's battery).

> An app must reach a certain threshold of data before battery statistics can be
> reliably calculated. This is around 200 users.

This is calculated based upon how much a user's battery decreased while the app
was open, and so does not take into other factors such as account notifications
or backlight activity during that time.

![grade](/images/guides/appstore-publishing/grade.png)

Clicking 'View More Details' will show a detailed breakdown for all the data
available across all app versions.

![grade-versions](/images/guides/appstore-publishing/grade-versions.png)
