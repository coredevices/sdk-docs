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

title: PebbleKit Android
description: How to use PebbleKit to communicate with a watchapp on Android.
guide_group: communication
order: 2
---

[PebbleKit Android](https://github.com/pebble/pebble-android-sdk/) is a Java
library that works with the Pebble SDK and can be embedded in any Android
application. Using the classes and methods in this library, an Android companion
app can find and exchange data with a Pebble watch.

This section assumes that the reader is familiar with basic Android development
and Android Studio as an integrated development environment. Refer to the
[Android Documentation](http://developer.android.com/sdk/index.html) for more
information on installing the Android SDK.

Most PebbleKit Android methods require a `Context` parameter. An app can use
`getApplicationContext()`, which is available from any `Activity`
implementation.


### Setting Up PebbleKit Android

Add PebbleKit Android to an Android Studio project in the
`app/build.gradle` file:

```
dependencies {
  compile 'com.getpebble:pebblekit:{{ site.data.sdk.pebblekit-android.version }}'
}
```


### Sending Messages from Android

Since Android apps are built separately from their companion Pebble apps, there is
no way for the build system to automatically create matching appmessage keys.
You must therefore manually specify them in `package.json`, like so:

```js
{
  "ContactName": 0,
  "Age": 1
}
```

These numeric values can then be used as appmessage keys in your Android app.

Messages are constructed with the `PebbleDictionary` class and sent to a C
watchapp or watchface using the `PebbleKit` class. The first step is to create a
`PebbleDictionary` object:

```java
// Create a new dictionary
PebbleDictionary dict = new PebbleDictionary();
```

Data items are added to the 
[`PebbleDictionary`](/docs/pebblekit-android/com/getpebble/android/kit/util/PebbleDictionary) 
using key-value pairs with the methods made available by the object, such as
`addString()` and `addInt32()`. An example is shown below:

```java
// The key representing a contact name is being transmitted
final int AppKeyContactName = 0;
final int AppKeyAge = 1;

// Get data from the app
final String contactName = getContact();
final int age = getAge();

// Add data to the dictionary
dict.addString(AppKeyContactName, contactName);
dict.addInt32(AppKeyAge, age);
```

Finally, the dictionary is sent to the C app by calling `sendDataToPebble()`
with a UUID matching that of the C app that will receive the data:

```java
final UUID appUuid = UUID.fromString("EC7EE5C6-8DDF-4089-AA84-C3396A11CC95");

// Send the dictionary
PebbleKit.sendDataToPebble(getApplicationContext(), appUuid, dict);
```

Once delivered, this dictionary will be available in the C app via the
``AppMessageInboxReceived`` callback, as detailed in
{% guide_link communication/sending-and-receiving-data#inbox-received %}.


### Receiving Messages on Android

Receiving messages from Pebble in a PebbleKit Android app requires a listener to
be registered in the form of a `PebbleDataReceiver` object, which extends
`BroadcastReceiver`:

```java
// Create a new receiver to get AppMessages from the C app
PebbleDataReceiver dataReceiver = new PebbleDataReceiver(appUuid) {

  @Override
  public void receiveData(Context context, int transaction_id,
                                                    PebbleDictionary dict) {
    // A new AppMessage was received, tell Pebble
    PebbleKit.sendAckToPebble(context, transaction_id);
  }

};
```

<div class="alert alert--fg-white alert--bg-dark-red">
{% markdown %}
**Important**

PebbleKit apps **must** manually send an acknowledgement (Ack) to Pebble to
inform it that the message was received successfully. Failure to do this will
cause timeouts.
{% endmarkdown %}
</div>

Once created, this receiver should be registered in `onResume()`, overridden
from `Activity`:

```java
@Override
public void onResume() {
  super.onResume();

  // Register the receiver
  PebbleKit.registerReceivedDataHandler(getApplicationContext(), dataReceiver);
}
```

> Note: To avoid getting callbacks after the `Activity` or `Service` has exited,
> apps should attempt to unregister the receiver in `onPause()` with
> `unregisterReceiver()`.

With a receiver in place, data can be read from the provided 
[`PebbleDictionary`](/docs/pebblekit-android/com/getpebble/android/kit/util/PebbleDictionary)
using analogous methods such as `getString()` and `getInteger()`. Before reading
the value of a key, the app should first check that it exists using a `!= null`
check.

The example shown below shows how to read an integer from the message, in the
scenario that the watch is sending an age value to the Android companion app:

```java
@Override
public void receiveData(Context context, int transaction_id,
                                                      PebbleDictionary dict) {
  // If the tuple is present...
  Long ageValue = dict.getInteger(AppKeyAge);
  if(ageValue != null) {
    // Read the integer value
    int age = ageValue.intValue();
  }
}
```


### Other Capabilities

In addition to sending and receiving messages, PebbleKit Android also allows
more intricate interactions with Pebble. See the
[PebbleKit Android Documentation](/docs/pebblekit-android/com/getpebble/android/kit/PebbleKit/) 
for a complete list of available methods. Some examples are shown below of what
is possible:

* Checking if the watch is connected:

    ```java
    boolean connected = PebbleKit.isWatchConnected(getApplicationContext());
    ```

* Registering for connection events with `registerPebbleConnectedReceiver()` and
  `registerPebbleDisconnectedReceiver()`, and a suitable `BroadcastReceiver`.

    ```java
    PebbleKit.registerPebbleConnectedReceiver(getApplicationContext(),
                                                      new BroadcastReceiver() {

      @Override
      public void onReceive(Context context, Intent intent) { }

    });
    ```

* Registering for Ack/Nack events with `registerReceivedAckHandler()` and
  `registerReceivedNackHandler()`.

    ```java
    PebbleKit.registerReceivedAckHandler(getApplicationContext(),
                                  new PebbleKit.PebbleAckReceiver(appUuid) {

      @Override
      public void receiveAck(Context context, int i) { }

    });
    ```

* Launching and killing the watchapp with `startAppOnPebble()` and
  `closeAppOnPebble()`.

    ```java
    PebbleKit.startAppOnPebble(getApplicationContext(), appUuid);
    ```
