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

title: Datalogging
description: |
  Information on how to collect data batches using the Datalogging API.
guide_group: communication
order: 1
related_examples:
  - title: Tricorder
  - url: https://github.com/pebble-examples/tricorder
---

In addition to the more realtime ``AppMessage`` API, the Pebble SDK also
includes the ``Datalogging`` API. This is useful for applications where data can
be sent in batches at time intervals that make the most sense (for example, to
save battery power by allowing the watch to spend more time sleeping).

Datalogging also allows upto 640 kB of data to be buffered on the watch until a
connection is available, instead of requiring a connection be present at all
times. If data is logged while the watch is disconnected, it will be transferred
to the Pebble mobile app in batches for processing at the next opportunity. The
data is then passed on to any 
{% guide_link communication/using-pebblekit-android %} or 
{% guide_link communication/using-pebblekit-ios %} companion
app that wishes to process it.


## Collecting Data

Datalogging can capture any values that are compatible with one of the
``DataLoggingItemType`` `enum` (byte array, unsigned integer, and integer)
values, with common sources including accelerometer data or compass data.


### Creating a Session

Data is logged to a 'session' with a unique identifier or tag, which allows a
single app to have multiple data logs for different types of data. First, define
the identifier(s) that should be used where appropriate:

```c
// The log's ID. Only one required in this example
#define TIMESTAMP_LOG 1
```

Next, a session must first be created before any data can be logged to it. This
should be done during app initialization, or just before the first time an app
needs to log some data:

```c
// The session reference variable
static DataLoggingSessionRef s_session_ref;
```

```c
static void init() {
  // Begin the session
  s_session_ref = data_logging_create(TIMESTAMP_LOG, DATA_LOGGING_INT, sizeof(int), true);

  /* ... */
}
```

> Note: The final parameter of ``data_logging_create()`` allows a previous log
> session to be continued, instead of starting from screatch on each app launch.


### Logging Data

Once the log has been created or resumed, data collection can proceed. Each call
to ``data_logging_log()`` will add a new entry to the log indicated by the
``DataLoggingSessionRef`` variable provided. The success of each logging
operation can be checked using the ``DataLoggingResult`` returned:

```c
const int value = 16;
const uint32_t num_values = 1;

// Log a single value
DataLoggingResult result = data_logging_log(s_session_ref, &value, num_values);

// Was the value successfully stored? If it failed, print the reason
if(result != DATA_LOGGING_SUCCESS) {
  APP_LOG(APP_LOG_LEVEL_ERROR, "Error logging data: %d", (int)result);
}
```


### Finishing a Session

Once all data has been logged or the app is exiting, the session must be
finished to signify that the data is to be either transferred to the connected
phone (if available), or stored for later transmission. 

```c
// Finish the session and sync data if appropriate
data_logging_finish(s_session_ref);
``` 

> Note: Once a session has been finished, data cannot be logged to its
> ``DataLoggingSessionRef`` until it is resumed or began anew.


## Receiving Data

> Note: Datalogging data cannot be received via PebbleKit JS.

Data collected with the ``Datalogging`` API can be received and processed in a
mobile companion app using PebbleKit Android or PebbleKit iOS. This enables it
to be used in a wide range of general applications, such as detailed analysis of
accelerometer data for health research, or transmission to a third-party web
service.


### With PebbleKit Android

PebbleKit Android allows collection of data by registering a
`PebbleDataLogReceiver` within your `Activity` or `Service`. When creating a
receiver, be careful to provide the correct UUID to match that of the watchapp
that is doing that data collection. For example:

```java
// The UUID of the watchapp
private UUID APP_UUID = UUID.fromString("64fcb54f-76f0-418a-bd7d-1fc1c07c9fc1");
```

Use the following overridden methods to collect data and determine when the
session has been finished by the watchapp. In the example below, each new
integer received represents the uptime of the watchapp, and is displayed in an
Android `TextView`:

```java
// Create a receiver to collect logged data
PebbleKit.PebbleDataLogReceiver dataLogReceiver = 
        new PebbleKit.PebbleDataLogReceiver(APP_UUID) {

  @Override
  public void receiveData(Context context, UUID logUuid, Long timestamp, 
                                                          Long tag, int data) {
    // super() (removed from IDE-generated stub to avoid exception)

    Log.i(TAG, "New data for session " + tag + "!");

    // Cumulatively add the new data item to a TextView's current text
    String current = dataView.getText().toString();
    current += timestamp.toString() + ": " + data 
                + "s since watchapp launch.\n";
    dataView.setText(current);
  }

  @Override
  public void onFinishSession(Context context, UUID logUuid, Long timestamp, 
                                                                    Long tag) {
    Log.i(TAG, "Session " + tag + " finished!");
  }

};

// Register the receiver
PebbleKit.registerDataLogReceiver(getApplicationContext(), dataLogReceiver);
```

<div class="alert alert--fg-white alert--bg-dark-red">
{% markdown %}
**Important**

If your Java IDE automatically adds a line of code to call super() when you
create the method, the code will result in an UnsupportedOperationException.
Ensure you remove this line to avoid the exception.
{% endmarkdown %}
</div>

Once the `Activity` or `Service` is closing, you should attempt to unregister
the receiver. However, this is not always required (and will cause an exception
to be thrown if invoked when not required), so use a `try, catch` statement:

```java
@Override
protected void onPause() {
  super.onPause();

  try {
    unregisterReceiver(dataLogReceiver);
  } catch(Exception e) {
    Log.w(TAG, "Receiver did not need to be unregistered");
  }
}
```


### With PebbleKit iOS

The process of collecing data via a PebbleKit iOS companion mobile app is
similar to that of using PebbleKit Android. Once your app is a delegate of
``PBDataLoggingServiceDelegate`` (see 
{% guide_link communication/using-pebblekit-ios %} for details), 
simply register the class as a datalogging delegate:

```objective-c
// Get datalogging data by becoming the delegate
[[PBPebbleCentral defaultCentral] 
                      dataLoggingServiceForAppUUID:myAppUUID].delegate = self;
```

Being a datalogging delegate allows the class to receive two additional
[callbacks](/docs/pebblekit-ios/Protocols/PBDataLoggingServiceDelegate/) for when new data
is available, and when the session has been finished by the watch. Implement
these callbacks to read the new data:

```objective-c
- (BOOL)dataLoggingService:(PBDataLoggingService *)service
              hasSInt32s:(const SInt32 [])data
           numberOfItems:(UInt16)numberOfItems
              forDataLog:(PBDataLoggingSessionMetadata *)log {
  NSLog(@"New data received!");
  
  // Append newest data to displayed string
  NSString *current = self.dataView.text;
  NSString *newString = [NSString stringWithFormat:@"New item: %d", data[0]];
  current = [current stringByAppendingString:newString];
  self.dataView.text = current;
  
  return YES;
}

- (void)dataLoggingService:(PBDataLoggingService *)service
            logDidFinish:(PBDataLoggingSessionMetadata *)log {
  NSLog(@"Finished data log: %@", log);
}
```


### Special Considerations for iOS Apps

* The logic to deal with logs with the same type of data (i.e., the same
  tag/type) but from different sessions (different timestamps) must be created
  by the developer using the delegate callbacks.

* To check whether the data belongs to the same log or not, use `-isEqual:` on
  `PBDataLoggingSessionMetadata`. For convenience,
  `PBDataLoggingSessionMetadata` can be serialized using `NSCoding`.

* Using multiple logs in parallel (for example to transfer different kinds of
  information) will require extra logic to re-associate the data from these
  different logs, which must also be implemented by the developer.

