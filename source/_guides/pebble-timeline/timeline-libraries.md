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

title: Libraries for Pushing Pins
description: |
  A list of libraries available for interacting with the Pebble timeline.
guide_group: pebble-timeline
order: 1
related_examples:
 - title: Hello Timeline
   url: https://github.com/pebble-examples/hello-timeline
 - title: Timeline TV Tracker
   url: https://github.com/pebble-examples/timeline-tv-tracker
 - title: Timeline Push Pin
   url: https://github.com/pebble-examples/timeline-push-pin
---

This page contains libraries that are currently available to interact with
the timeline. You can use these to build apps and services that push pins to
your users.

## timeline.js

**JavaScript Code Snippet** - [Available on GitHub](https://gist.github.com/pebble-gists/6a4082ef12e625d23455)

**Install**

Copy into the `src/pkjs/` directory of your project, add `enableMultiJS: true` in
`package.json`, then `require` and use in `index.js`.

**Example**

```js
var timeline = require('./timeline');

// Push a pin when the app starts
Pebble.addEventListener('ready', function() {
  // An hour ahead
  var date = new Date();
  date.setHours(date.getHours() + 1);

  // Create the pin
  var pin = {
    "id": "example-pin-0",
    "time": date.toISOString(),
    "layout": {
      "type": "genericPin",
      "title": "Example Pin",
      "tinyIcon": "system://images/SCHEDULED_EVENT"
    }
  };

  console.log('Inserting pin in the future: ' + JSON.stringify(pin));

  // Push the pin
  timeline.insertUserPin(pin, function(responseText) {
    console.log('Result: ' + responseText);
  });
});
```

## pebble-api

**Node Module** - [Available on NPM](https://www.npmjs.com/package/pebble-api)

**Install**

```bash
npm install pebble-api --save
```

**Example**

```js
var Timeline = require('pebble-api');

var USER_TOKEN = 'a70b23d3820e9ee640aeb590fdf03a56';

var timeline = new Timeline();

var pin = new Timeline.Pin({
  id: 'test-pin-5245',
  time: new Date(),
  duration: 10,
  layout: new Timeline.Pin.Layout({
    type: Timeline.Pin.LayoutType.GENERIC_PIN,
    tinyIcon: Timeline.Pin.Icon.PIN,
    title: 'Pin Title'
  })
});

timeline.sendUserPin(USER_TOKEN, pin, function (err) {
  if (err) {
    return console.error(err);
  }

  console.log('Pin sent successfully!');
});
```

## PebbleTimeline API Ruby

**Ruby Gem** - [Available on RubyGems](https://rubygems.org/gems/pebble_timeline/versions/0.0.1)

**Install**

```bash
gem install pebble_timeline
```

**Example**

```ruby
require 'pebble_timeline'

api = PebbleTimeline::API.new(ENV['PEBBLE_TIMELINE_API_KEY'])

# Shared pins
pins = PebbleTimeline::Pins.new(api)
pins.create(id: "test-1", topics: 'test', time: "2015-06-10T08:01:10.229Z", layout: { type: 'genericPin', title: 'test 1' })
pins.delete("test-1")

# User pins
user_pins = PebbleTimeline::Pins.new(api, 'user', USER_TOKEN)
user_pins.create(id: "test-1", time: "2015-06-12T16:42:00Z", layout: { type: 'genericPin', title: 'test 1' })
user_pins.delete("test-1")
```

## pypebbleapi

**Python Library** - [Available on pip](https://pypi.python.org/pypi/pypebbleapi/0.0.1)

**Install**

```bash
pip install pypebbleapi
```

**Example**

```python
from pypebbleapi import Timeline, Pin
import datetime

timeline = Timeline(my_api_key)

my_pin = Pin(id='123', datetime.date.today().isoformat())

timeline.send_shared_pin(['a_topic', 'another_topic'], my_pin)
```

## php-pebble-timeline

**PHPebbleTimeline** - [Available on Github](https://github.com/fletchto99/PHPebbleTimeline)

**Install**

Copy the TimelineAPI folder (from the above repository) to your project's directory and include the required files.

**Example**

<div>
{% highlight { "language": "php", "options": { "startinline": true } } %}
//Include the timeline API
require_once 'TimelineAPI/Timeline.php';

//Import the required classes
use TimelineAPI\Pin;
use TimelineAPI\PinLayout;
use TimelineAPI\PinLayoutType;
use TimelineAPI\PinIcon;
use TimelineAPI\PinReminder;
use TimelineAPI\Timeline;

//Create some layouts which our pin will use
$reminderlayout = new PinLayout(PinLayoutType::GENERIC_REMINDER, 'Sample reminder!', null, null, null, PinIcon::NOTIFICATION_FLAG);
$pinlayout = new PinLayout(PinLayoutType::GENERIC_PIN, 'Our title', null, null, null, PinIcon::NOTIFICATION_FLAG);

//Create a reminder which our pin will push before the event
$reminder = new PinReminder($reminderlayout, (new DateTime('now')) -> add(new DateInterval('PT10M')));

//Create the pin
$pin = new Pin('<YOUR USER TOKEN HERE>', (new DateTime('now')) -> add(new DateInterval('PT5M')), $pinlayout);

//Attach the reminder
$pin -> addReminder($reminder);

//Push the pin to the timeline
Timeline::pushPin('sample-userToken', $pin);
{% endhighlight %}
</div>

## PinPusher

**PHP Library** - [Available on Composer](https://packagist.org/packages/valorin/pinpusher)

**Install**

```bash
composer require valorin/pinpusher
```

**Example**

<div>
{% highlight { "language": "php", "options": { "startinline": true } } %}
use Valorin\PinPusher\Pusher;
use Valorin\PinPusher\Pin;

$pin = new Pin(
    'example-pin-generic-1',
    new DateTime('2015-03-19T18:00:00Z'),
    new Pin\Layout\Generic(
        "News at 6 o'clock",
        Pin\Icon::NOTIFICATION_FLAG
    )
);

$pusher = new Pusher()
$pusher->pushToUser($userToken, $pin);
{% endhighlight %}
</div>

## pebble-api-dotnet

**PCL C# Library** - [Available on Github](https://github.com/nothingmn/pebble-api-dotnet)

**Install**

```text
git clone git@github.com:nothingmn/pebble-api-dotnet.git
```

**Example**

In your C# project, define your global API Key.

```csharp
public static string APIKey = "APIKEY";
```

Launch your app on the watch, and make the API call...

Now, on the server, you can use your "userToken" from the client app, and send pins as follows:

```csharp
var timeline = new Timeline(APIKey);
var result = await timeline.SendUserPin(userToken, new Pin()
{
    Id = System.Guid.NewGuid().ToString(),
    Layout = new GenericLayout()
    {
        Title = "Generic Layout",
        Type = LayoutTypes.genericPin,
        SmallIcon = Icons.Notification.Flag
    },
});
```

See more examples on the 
[GitHub repo](https://github.com/nothingmn/pebble-api-dotnet).
