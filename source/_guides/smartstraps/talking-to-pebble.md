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

title: Talking To Pebble
description: |
  Information on how to implement the smartstrap protocol to talk to the Pebble
  accessory port.
guide_group: smartstraps
order: 2
related_docs:
  - Smartstrap
related_examples:
  - title: Smartstrap Button Counter
    url: https://github.com/pebble-examples/smartstrap-button-counter
  - title: Smartstrap Library Test
    url: https://github.com/pebble-examples/smartstrap-library-test
---

In order to communicate successfully with Pebble, the smartstrap hardware must
correctly implement the smartstrap protocol as defined in 
{% guide_link smartstraps/smartstrap-protocol %}.


## Arduino Library

For developers prototyping with some of the most common Arduino boards
(based on the AVR ATmega 32U4, 2560, 328, or 328P chips), the simplest way of
doing this is to use the
[ArduinoPebbleSerial](https://github.com/pebble/arduinopebbleserial) library.
This open-source reference implementation takes care of the smartstrap protocol
and allows easy communication with the Pebble accessory port.

Download the library as a .zip file. In the Arduino IDE, go to 'Sketch' ->
'Include Library' -> 'Add .ZIP LIbrary...'. Choose the library .zip file. This
will import the library into Arduino and add the appropriate include statement
at the top of the sketch:

```c++
#include <ArduinoPebbleSerial.h>
```

After including the ArduinoPebbleSerial library, begin the sketch with the
standard template functions (these may already exist):

```c++
void setup() {

}

void loop() {

}
```


## Connecting to Pebble

Declare the buffer to be used for transferring data (of type `uint8_t`), and its
maximum length. This should be large enough for managing the largest possible
request from the watch, but not so large that there is no memory left for the
rest of the program:

> Note: The buffer **must** be at least 6 bytes in length to handle internal
> protocol messages.

```c++
// The buffer for transferring data
static uint8_t s_data_buffer[256];
```

Define which service IDs the strap will support. See
{% guide_link smartstraps/smartstrap-protocol#generic-service-profile "Generic Service Profile" %}
for details on which values may be used here. An example service ID and
attribute ID both of value `0x1001` are shown below:

```c
static const uint16_t s_service_ids[] = {(uint16_t)0x1001};
static const uint16_t s_attr_ids[] = {(uint16_t)0x1001};
```

The last decision to be made before connection is which baud rate will be used.
This will be the speed of the connection, chosen as one of the available baud
rates from the `Baud` `enum`:

```c
typedef enum {
  Baud9600,
  Baud14400,
  Baud19200,
  Baud28800,
  Baud38400,
  Baud57600,
  Baud62500,
  Baud115200,
  Baud125000,
  Baud230400,
  Baud250000,
  Baud460800,
} Baud;
```

This should be chosen as the highest rate supported by the board used, to allow
the watch to save power by sleeping as much as possible. The recommended value
is `Baud57600` for most Arduino-like boards.


### Hardware Serial

If using the hardware UART for the chosen board (the `Serial` library),
initialize the ArduinoPebbleSerial library in the `setup()` function to prepare
for connection:

```c++
// Setup the Pebble smartstrap connection
ArduinoPebbleSerial::begin_hardware(s_data_buffer, sizeof(s_data_buffer),
                                                  Baud57600, s_service_ids, 1);
```


### Software Serial

Alternatively, software serial emulation can be used for any pin on the chosen
board that 
[supports interrupts](https://www.arduino.cc/en/Reference/AttachInterrupt). In
this case, initialize the library in the following manner, where `pin` is the
compatible pin number. For example, using Arduino Uno pin D8, specify a value of
`8`. As with `begin_hardware()`, the baud rate and supported service IDs must
also be provided here:

```c++
int pin = 8;

// Setup the Pebble smartstrap connection using one wire software serial
ArduinoPebbleSerial::begin_software(pin, s_data_buffer, sizeof(s_data_buffer),
                                                   Baud57600, s_service_ids, 1);
```


## Checking Connection Status

Once the smartstrap has been physically connected to the watch and the
connection has been established, calling `ArduinoPebbleSerial::is_connected()`
will allow the program to check the status of the connection, and detect
disconnection on the smartstrap side. This can be indicated to the wearer using
an LED, for example:

```c++
if(ArduinoPebbleSerial::is_connected()) {
  // Connection is valid, turn LED on
  digitalWrite(7, HIGH);
} else {
  // Connection is not valid, turn LED off
  digitalWrite(7, LOW);
}
```


## Processing Commands

In each iteration of the `loop()` function, the program must allow the library
to process any bytes which have been received over the serial connection using
`ArduinoPebbleSerial::feed()`. This function will return `true` if a complete
frame has been received, and set the values of the parameters to inform the
program of which type of frame was received:

```c++
size_t length;
RequestType type;
uint16_t service_id;
uint16_t attribute_id;

// Check to see if a frame was received, and for which service and attribute
if(ArduinoPebbleSerial::feed(&service_id, &attribute_id, &length, &type)) {
  // We got a frame!
  if((service_id == 0) && (attribute_id == 0)) {
    // This is a raw data service frame
    // Null-terminate and display what was received in the Arduino terminal
    s_data_buffer[min(length_read, sizeof(s_data_buffer))] = `\0`;
    Serial.println(s_data_buffer);
  } else {
    // This may be one of our service IDs, check it.
    if(service_id == s_service_ids[0] && attribute_id == s_attr_ids[0]) {
      // This frame is for our supported service!
      s_data_buffer[min(length_read, sizeof(s_data_buffer))] = `\0`;
      Serial.print("Write to service ID: ");
      Serial.print(service_id);
      Serial.print(" Attribute ID: ");
      Serial.print(attribute_id);
      Serial.print(": ");
      Serial.println(s_data_buffer);
    }
  }
}
```

If the watch is requesting data, the library also allows the Arduino to respond
back using `ArduinoPebbleSerial::write()`. This function accepts parameters to
tell the connected watch which service and attribute is responding to the read
request, as well is whether or not the read was successful:

> Note: A write to the watch **must** occur during processing for a
> `RequestType` of `RequestTypeRead` or `RequestTypeWriteRead`.

```c++
if(type == RequestTypeRead || type == RequestTypeWriteRead) {
  // The watch is requesting data, send a friendly response
  char *msg = "Hello, Pebble";

  // Clear the buffer
  memset(s_data_buffer, 0, sizeof(s_data_buffer));

  // Write the response into the buffer
  snprintf((char*)s_data_buffer, sizeof(s_data_buffer), "%s", msg);

  // Send the data to the watch for this service and attribute
  ArduinoPebbleSerial::write(true, s_data_buffer, strlen((char*)s_data_buffer)+1);
}
```


## Notifying the Watch

To save power, it is strongly encouraged to design the communication scheme in
such a way that avoids needing the watch to constantly query the status of the
smartstrap, allowing it to sleep. To aid in this effort, the ArduinoPebbleSerial
library includes the `ArduinoPebbleSerial::notify()` function to cause the
watchapp to receive a ``SmartstrapNotifyHandler``.

For example, to notify the watch once a second:

```c++
// The last time the watch was notified
static unsigned long s_last_notif_time = 0;

void loop() {

  /* other code */

  // Notify the watch every second
  if (millis() - s_last_notif_time  > 1000) {
    // Send notification with our implemented serviceID  and attribute ID
    ArduinoPebbleSerial::notify(s_service_ids[0], s_attr_ids[0]);

    // Record the time of this notification
    s_last_notif_time = millis();
  }
}
```
