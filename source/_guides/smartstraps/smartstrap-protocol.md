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

title: Protocol Specification
description: |
  Reference information on the Pebble smartstrap protocol.
guide_group: smartstraps
order: 1
---

This page describes the protocol used for communication with Pebble smartstraps,
intended to gracefully handle bus contention and allow two-way communication.
The protocol is error-free and unreliable, meaning datagrams either arrive
intact or not at all.


## Communication Model

Most smartstrap communication follows a master-slave model with the watch being
the master and the smartstrap being the slave. This means that the watch will
never receive data from the smartstrap which it isn't expecting. The one
exception to the master/slave model is the notification mechanism, which allows
the smartstrap to notify the watch of an event it may need to respond to. This
is roughly equivalent to an interrupt line on an I2C device, but for smartstraps
is done over the single data line (marked 'Data' on diagrams).


## Assumptions

The following are assumed to be universally true for the purposes of the
smartstrap protocol:

1. Data is sent in [little-endian](https://en.wikipedia.org/wiki/Endianness)
   byte order.
2. A byte is defined as an octet (8 bits).
3. Any undefined values should be treated as reserved and should not be used.


## Sample Implementation

Pebble provides complete working sample implementations for common
micro-controllers platforms such as the [Teensy](https://www.pjrc.com/teensy/)
and [Arduino Uno](https://www.arduino.cc/en/Main/arduinoBoardUno).
This means that when using one of these platforms, it is not necessary to
understand all of the details of the low level communications and thus can rely
on the provided library.

[Arduino Pebble Serial Sample Library >{center,bg-dark-red,fg-white}](https://github.com/pebble/ArduinoPebbleSerial/)

Read [*Talking to Pebble*](/guides/smartstraps/talking-to-pebble) for
instructions on how to use this library to connect to Pebble.


## Protocol Layers

The smartstrap protocol is split up into 3 layers as shown in the table below:

| Layer | Function |
|-------|----------|
| [Profile Layer](#profile-layer) | Determines the format of the high-level message being transmitted. |
| [Link Layer](#link-layer) | Provides framing and error detection to allow transmission of datagrams between the watch and the smartstrap. |
| [Physical Layer](#physical-layer) | Transmits raw bits over the electrical connection. |


### Physical Layer

The physical layer defines the hardware-level protocol that is used to send bits
over the single data wire. In the case of the smartstrap interface, there is a
single data line, with the two endpoints using open-drain outputs with an
external pull-up resistor on the smartstrap side. Frames are transmitted over
this data line as half-duplex asynchronous serial (UART).

The UART configuration is 8-N-1: eight data bits, no
[parity bit](https://en.wikipedia.org/wiki/Parity_bit), and one
[stop bit](https://en.wikipedia.org/wiki/Asynchronous_serial_communication). The
default baud rate is 9600 bps (bits per second), but can be changed by the
higher protocol layers. The smallest data unit in a frame is a byte.


**Auto-detection**

The physical layer is responsible for providing the smartstrap auto-detection
mechanism. Smartstraps are required to have a pull-up resistor on the data line
which is always active and not dependent on any initialization (i.e. activating
internal pull-ups on microcontroller pins). The value of the pull-up resistor
must be low enough that adding a 30kΩ pull-down resistor to the data line will
leave the line at >=1.26V (10kΩ is generally recommended). Before communication
with the smartstrap is attempted, the watch will check to see if the pull-up is
present. If (and only if) it is, the connection will proceed.


**Break Character**

A break character is defined by the physical layer and used by the
[link layer](#link-layer) for the notification mechanism. The physical layer for
smartstraps defines a break character as a `0x00` byte with an extra low bit
before the stop bit. For example, in 8-N-1 UART, this means the start bit is
followed by nine low (`0`) bits and a stop bit.


### Link Layer

The link layer is responsible for transmitting frames between the smartstrap and
the watch. The goal of the link layer is to detect transmission errors such as
flipped bits (including those caused by bus contention) and to provide a framing
mechanism to the upper layers.


#### Frame Format

The structure of the link layer frame is shown below. The fields are transmitted
from top to bottom.

> Note: This does not include the delimiting flags or bytes inserted for
> transparency as described in the [encoding](#encoding) section below.

| Field Name | Length |
|------------|--------|
| `version` | 1 byte |
| `flags` | 4 bytes |
| `profile` | 2 bytes |
| `payload` | Variable length (may be empty) |
| `checksum` | 1 byte |


**Version**

The `version` field contains the current version of the link layer of the
smartstrap protocol.

| Version | Description |
|---------|-------------|
| 1 | Initial release version. |


**Flags**

The `flags` field is four bytes in length and is made up of the following
fields.

| Bit(s) | Name | Description |
|--------|------|-------------|
| 0 | `IsRead` | `0`: The smartstrap should not reply to this frame.</br>`1`: This is a read and the smartstrap should reply.</br></br>This field field should only be set by the watch. The smartstrap should always set this field to `0`. |
| 1 | `IsMaster` | `0`: This frame was sent by the smartstrap.</br>`1`: This frame was sent by the watch. |
| 2 | `IsNotification` | `0`: This is not a notification frame.</br>`1`: This frame was sent by the smartstrap as part of the notification.</br></br>This field should only be set by the smartstrap. The watch should always set this field to `0`. |
| 3-31 | `Reserved` | All reserved bits should be set to `0`. |


**Profile**

The `profile` field determines the specific profile used for communication. The
details of each of the profiles are defined in the 
[Profile Layer](#profile-layer) section.

| Number | Value | Name |
|--------|-------|------|
| 1 | `0x0001` | Link Control Profile |
| 2 | `0x0002` | Raw Data Profile |
| 3 | `0x0003` | Generic Service Profile |


**Payload**

The `payload` field contains the profile layer data. The link layer considers an
empty frame as being valid, and there is no maximum length.


**Checksum**

The checksum is an 8-bit 
[CRC](https://en.wikipedia.org/wiki/Cyclic_redundancy_check) with a polynomial 
of `x^8 + x^5 + x^3 + x^2 + x + 1`. This is **not** the typical CRC-8 
polynomial.

An example implementation of this CRC can be found in the
[ArduinoPebbleSerial library](https://github.com/pebble/ArduinoPebbleSerial/blob/master/utility/crc.c).


**Frame Length**

The length of a frame is defined as the number of bytes in the `flags`,
`profile`, `checksum`, and `payload` fields of the link layer frame. This does
not include the delimiting flags or the bytes inserted for transparency as part
of [encoding](#encoding). The smallest valid frame is eight bytes in size: one
byte for the version, four for the flags, two for the profile type, one for the
checksum, and zero for the empty payload. The protocol is designed to work
without the need for fixed buffers.


#### Encoding

A delimiting flag (i.e.: a byte with value of `0x7e`) is used to delimit frames
(indicating the beginning or end of a frame). The byte stream is examined on a
byte-by-byte basis for this flag value. Each frame begins and ends with the
delimiting flag, although only one delimiting flag is required between two
frames. Two consecutive delimiting flags constitute an empty frame, which is
silently discarded by the link layer and is not considered an error.


**Transparency**

A byte-stuffing procedure is used to escape `0x7e` bytes in the frame payload.
After checksum computation, the link layer of the transmitter within the
smartstrap encodes the entire frame between the two delimiting flags. Any
occurrence of `0x7e` or `0x7d` in the frame is escaped with a proceeding `0x7d`
byte and logically-XORed with `0x20`. For example:

* The byte `0x7d` when escaped is encoded as `0x7d 0x5d`.

* The byte `0x7e` when escaped is encoded as `0x7d 0x5e`.

On reception, prior to checksum computation, decoding is performed on the byte
stream before passing the data to the profile layer.


#### Example Frames

The images below show some example frames of the smartstrap protocol under two
example conditions, including the calculated checksum. Click them to see more
detail.

**Raw Profile Read Request**

<a href="/assets/images/guides/hardware/raw-read.png"><img src="/assets/images/guides/hardware/raw-read.png"></img></a>

**Raw Profile Response**

<a href="/assets/images/guides/hardware/raw-response.png"><img src="/assets/images/guides/hardware/raw-response.png"></img></a>


#### Invalid Frames

Frames which are too short, have invalid transparency bytes, or encounter a UART
error (such as an invalid stop bit) are silently discarded.


#### Timeout

If the watch does not receive a response to a message sent with the `IsRead`
flag set (a value of `1`) within a certain period of time, a timeout will occur.
The amount of time before a timeout occurs is always measured by the watch from
the time it starts to send the message to the time it completely reads the
response.

The amount of time it takes to send a frame (based on the baud rate, maximum
size of the data after encoding, and efficiency of the physical layer UART
implementation) should be taken into account when determining timeout values.
The value itself can be set with ``smartstrap_set_timeout()``, up to a maximum
value of 1000ms.

> Note: In order to avoid bus contention and potentially corrupting other
> frames, the smartstrap should not respond after the timeout has elapsed. Any frame
> received after a timeout has occurred will be dropped by the watch.


### Notification Mechanism

There are many use-cases where the smartstrap will need to notify the watch of
some event. For example, smartstraps may contain input devices which will be
used to control the watch. These smartstraps require a low-latency mechanism for
notifying the watch upon receiving user-input. The primary goal of this
mechanism is to keep the code on the smartstrap as simple as possible.

In order to notify the watch, the smartstrap can send a break character
(detailed under [*Physical Layer*](#physical-layer)) to the watch. Notifications
are handled on a per-profile granularity, so the frame immediately following
a break character, called the context frame, is required in order to communicate
which profile is responsible for handling the notification. The context
frame must have the `IsNotification` flag (detailed under [*Flags*](#flags)) set
and have an empty payload. How the watch responds to notifications is dependent
on the profile.


### Profile Layer

The profile layer defines the format of the payload. Exactly which profile a
frame belongs to is determined by the `profile` field in the link layer header.
Each profile type defines three things: a set of requirements, the format of
all messages of that type, and notification handling.


#### Link Control Profile

The link control profile is used to establish and manage the connection with the
smartstrap. It must be fully implemented by all smartstraps in order to be
compatible with the smartstrap protocol as a whole. Any invalid responses or
timeouts encountered as part of link control profile communication will cause
the smartstrap to be marked as disconnected and powered off unless otherwise
specified. The auto-detection mechanism will cause the connection establishment
procedure to restart after some time has passed.

**Requirements**

| Name | Value |
|------|-------|
| Notifications Allowed? | No |
| Message Timeout | 100ms. |
| Maximum Payload Length | 6 bytes. |


**Payload Format**

| Field | Length (bytes) |
|-------|----------------|
| Version | 1 |
| Type | 1 |
| Data | Variable length (may be empty) |


**Version**

The Version field contains the current version of link control profile.

| Version | Notes |
|---------|-------|
| `1`  | Initial release version. |


**Type**

| Type | Value | Data |
|------|-------|-------------|
| Status | `0x01` | Watch: *Empty*. Smartstrap: Status (see below). |
| Profiles | `0x02` | Watch: *Empty*. Smartstrap: Supported profiles (see below). |
| Baud rate | `0x03` | Watch: *Empty*. Smartstrap: Baud rate (see below). |


**Status**

This message type is used to poll the status of the smartstrap and allow it to
request a change to the parameters of the connection. The smartstrap should send
one of the following status values in its response.

| Value | Meaning | Description |
|-------|---------|-------------|
| `0x00` | OK | This is a simple acknowledgement that the smartstrap is still alive and is not requesting any changes to the connection parameters. |
| `0x01` | Baud rate | The smartstrap would like to change the baud rate for the connection. The watch should follow-up with a baud rate message to request the new baud rate. |
| `0x02` | Disconnect | The smartstrap would like the watch to mark it as disconnected. |

A status message is sent by the watch at a regular interval. If a timeout
occurs, the watch will retry after an interval of time. If an invalid response
is received or the retry also hits a timeout, the smartstrap will be marked as
disconnected.


**Profiles**

This message is sent to determine which profiles the smartstrap supports. The
smartstrap should respond with a series of two byte words representing all the
[profiles](#profile) which it supports. There are the following requirements for
the response.

* All smartstraps must support the link control profile and should not include
  it in the response.

* All smartstraps must support at least one profile other than the link control
  profile, such as the raw data profile.

* If more than one profile is supported, they should be reported in consecutive
  bytes in any order.

> Note: Any profiles which are not supported by the watch are silently ignored.


**Baud Rate**

This message type is used to allow the smartstrap to request a change in the
baud rate. The smartstrap should respond with a pre-defined value corresponding
to the preferred baud rate as listed below. Any unlisted value is invalid. In
order to conserve power on the watch, the baud rate should be set as high as
possible to keep time spent alive and communicating to a minimum.

| Value | Baud Rate (bits per second) |
|-------|-----------------------------|
| `0x00` | 9600 |
| `0x01` | 14400 |
| `0x02` | 19200 |
| `0x03` | 28800 |
| `0x04` | 38400 |
| `0x05` | 57600 |
| `0x06` | 62500 |
| `0x07` | 115200 |
| `0x08` | 125000 |
| `0x09` | 230400 |
| `0x0A` | 250000 |
| `0x0B` | 460800 |

Upon receiving the response from the smartstrap, the watch will change its baud
rate and then send another status message. If the smartstrap does not respond to
the status message at the new baud rate, it is treated as being disconnected.
The watch will revert back to the default baud rate of 9600, and the connection
establishment will start over. The default baud rate (9600) must always be the
lowest baud rate supported by the smartstrap.


**Notification Handling**

Notifications are not supported for this profile.


#### Raw Data Service

The raw data profile provides a mechanism for exchanging raw data with the
smartstrap without any additional overhead. It should be used for any messages
which do not fit into one of the other profiles.


**Requirements**

| Name | Value |
|------|-------|
| Notifications Allowed? | Yes |
| Message Timeout | 100ms from sending to complete reception of the response. |
| Maximum Payload Length | Not defined. |


**Payload Format**

There is no defined message format for the raw data profile. The payload may
contain any number of bytes (including being empty).

| Field | Value |
|-------|-------|
| `data` | Variable length (may be empty). |


**Notification Handling**

The handling of notifications is allowed, but not specifically defined for the
raw data profile.


#### Generic Service Profile

The generic service profile is heavily inspired by (but not identical to) the
[GATT bluetooth profile](https://developer.bluetooth.org/gatt/Pages/default.aspx).
It allows the watch to write to and read from pre-defined attributes on the
smartstrap. Similar attributes are grouped together into services. These
attributes can be either read or written to, where a read requires the
smartstrap to respond with the data from the requested attribute, and a write
requiring the smartstrap to set the value of the attribute to the value provided
by the watch. All writes require the smartstrap to send a response to
acknowledge that it received the request. The data type and size varies by
attribute.


**Requirements**

| Name | Value |
|------|-------|
| Notifications Allowed? | Yes |
| Message Timeout | Not defined. A maximum of 1000ms is supported. |
| Maximum Payload Length | Not defined. |


**Payload Format**

| Field | Length (bytes) |
|-------|----------------|
| Version | 1 |
| Service ID | 2 |
| Attribute ID | 2 |
| Type | 1 |
| Error Code | 1 |
| Length | 2 |
| Data | Variable length (may be empty) |


**Version**

The Version field contains the current version of generic service profile.

| Version | Notes |
|---------|-------|
| `1`  | Initial release version. |


**Service ID**

The two byte identifier of the service as defined in the Supported Services and
Attributes section below. The available Service IDs are blocked off into five
ranges:

| Service ID Range (Inclusive) | Service Type | Description |
|------------------------------|--------------|-------------|
| `0x0000` - `0x00FF` | Reserved | These services are treated as invalid by the watch and should never be used by a smartstrap. The `0x0000` service is currently aliased to the raw data profile by the SDK. |
| `0x0100` - `0x0FFF` | Restricted | These services are handled internally in the firmware of the watch and are not available to apps. Smartstraps may (and in the case of the management service, must) support services in this range. |
| `0x1000` - `0x1FFF` | Experimentation | These services are for pre-release product experimentation and development and should NOT be used in a commercial product. When a smartstrap is going to be sold commercially, the manufacturer should contact Pebble to request a Service ID in the "Commerical" range. |
| `0x2000` - `0x7FFF` | Spec-Defined | These services are defined below under [*Supported Services and Attributes*](#supported-services-and-attributes), and any smartstrap which implements them must strictly follow the spec to ensure compatibility. |
| `0x8000` - `0xFFFF` | Commercial | These services are allocated by Pebble to smartstrap manufacturers who will define their own attributes. |


**Attribute ID**

The two byte identifier of the attribute as defined in the Supported Services
and Attributes section below.


**Type**

One byte representing the type of message being transmitted. When the smartstrap
replies, it should preserve this field from the request.

| Value | Type | Meaning |
|-------|------|---------|
| `0` | Read | This is a read request with the watch not sending any data, but expecting to get data back from the smartstrap. |
| `1` | Write | This is a write request with the watch sending data to the smartstrap, but not expected to get any data back. |
| `2` | WriteRead | This is a write+read request which consists of the watch writing data to the smartstrap **and** expecting to get some data back in response. |



**Error Code**

The error code is set by the smartstrap to indicate the result of the previous
request and must be one of the following values.

| Value | Name | Meaning |
|-------|------|---------|
| `0` | OK | The read or write request has been fulfilled successfully. The watch should always use this value when making a request. |
| `1` | Not Supported | The requested attribute is not supported by the smartstrap. |


**Length**

The length of the data in bytes.


#### Supported Services and Attributes

**Management Service (Service ID: `0x0101`)**

| Attribute ID | Attribute Name | Type | Data Type | Data |
|--------------|----------------|------|-----------|------|
| `0x0001` | Service Discovery | Read | uint16[1..10] | A list of Service ID values for all of the services supported by the smartstrap. A maximum of 10 (inclusive) services may be reported. In order to support the generic service profile, the management service must be supported and should not be reported in the response. |
| `0x0002` | Notification Info | Read | uint16_t[2] | If a read is performed by the watch after the smartstrap issues a notification, the response data should be the IDs of the service and attribute which generated the notification. |


**Pebble Control Service (Service ID: `0x0102`)**

> Note: This service is not yet implemented.

| Attribute ID | Attribute Name | Type | Data Type | Data |
|--------------|----------------|------|-----------|------|
| `0x0001` | Launch App | Read | uint8[16] | The UUID of the app to launch. |
| `0x0002` | Button Event | Read | uint8[2] | This message allows the smartstrap trigger button events on the watch. The smartstrap should send two bytes: the button being acted on and the click type. The possible values are defined below:</br></br>Buttons Values:</br>`0x00`: No Button</br>`0x01`: Back button</br>`0x02`: Up button</br>`0x03`: Select button</br>`0x04`: Down button</br></br>Click Types:</br>`0x00`: No Event</br>`0x01`: Single click</br>`0x02`: Double click</br>`0x03`: Long click</br></br>The smartstrap can specify a button value of `0x00` and a click type of `0x00` to indicate no pending button events. Any other use of the `0x00` values is invalid. |


**Location and Navigation Service (Service ID: `0x2001`)**

| Attribute ID | Attribute Name | Type | Data Type | Data |
|--------------|----------------|------|-----------|------|
| `0x0001` | Location | Read | sint32[2] | The current longitude and latitude in degrees with a precision of 1/10^7. The latitude comes before the longitude in the data. For example, Pebble HQ is at (37.4400662, -122.1583808), which would be specified as {374400662, -1221583808}. |
| `0x0002` | Location Accuracy | Read | uint16 | The accuracy of the location in meters. |
| `0x0003` | Speed | Read | uint16 | The current speed in meters per second with a precision of 1/100. For example, 1.5 m/s would be specified as 150. |
| `0x0101` | GPS Satellites | Read | uint8 | The number of GPS satellites (typically reported via NMEA. |
| `0x0102` | GPS Fix Quality | Read | uint8 | The quality of the GPS fix (reported via NMEA). The possible values are listed in the [NMEA specification](http://www.gpsinformation.org/dale/nmea.htm#GGA). |


**Heart Rate Service (Service ID: `0x2002`)**

| Attribute ID | Attribute Name | Type | Data Type | Data |
|--------------|----------------|------|-----------|------|
| `0x0001` | Measurement Read | uint8 | The current heart rate in beats per minute. |


**Battery Service (Service ID: `0x2003`)**

| Attribute ID | Attribute Name | Type | Data Type | Data |
|--------------|----------------|------|-----------|------|
| `0x0001` | Charge Level | Read | uint8 | The percentage of charge left in the smartstrap battery (between 0 and 100). |
| `0x0002` | Capacity | Read | uint16 | The total capacity of the smartstrap battery in mAh when fully charged. |


**Notification Handling**

When a notification is received for this profile, a "Notification Info" message
should be sent as described above.
