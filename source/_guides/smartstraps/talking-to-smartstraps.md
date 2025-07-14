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

title: Talking To Smartstraps
description: |
  Information on how to use the Pebble C API to talk to a connected smartstrap.
guide_group: smartstraps
order: 3
platforms:
  - basalt
  - chalk
  - diorite
  - emery
related_docs:
  - Smartstrap
---

To talk to a connected smartstrap, the ``Smartstrap`` API is used to establish a
connection and exchange arbitrary data. The exchange protocol is specified in
{% guide_link smartstraps/smartstrap-protocol %} and most of
it is abstracted by the SDK. This also includes handling of the
{% guide_link smartstraps/smartstrap-protocol#link-control-profile "Link Control Profile" %}.

Read {% guide_link smartstraps/talking-to-pebble %} to learn how to use an
example library for popular Arduino microcontrollers to implement the smartstrap
side of the protocol.

> Note: Apps running on multiple hardware platforms that may or may not include
> a smartstrap connector should use the `PBL_SMARTSTRAP` compile-time define (as
> well as checking API return values) to gracefully handle when it is not
> available.


## Services and Attributes

### Generic Service Profile

The Pebble smartstrap protocol uses the concept of 'services' and 'attributes'
to organize the exchange of data between the watch and the smartstrap. Services
are identified by a 16-bit number. Some of these service identifiers have a
specific meaning; developers should read 
{% guide_link smartstraps/smartstrap-protocol#supported-services-and-attributes "Supported Services and Attributes" %}
for a complete list of reserved service IDs and ranges of service IDs that can
be used for experimentation.

Attributes are also identified by a 16-bit number. The meaning of attribute
values is specific to the service of that attribute. The smartstrap protocol
defines the list of attributes for some services, but developers are free to
define their own list of attributes in their own services.

This abstraction supports read and write operations on any attribute as well as
sending notifications from the strap when an attribute value changes. This is
called the Generic Service Profile and is the recommended way to exchange data
with smartstraps.


### Raw Data Service

Developers can also choose to use the Raw Data Service to minimize the overhead
associated with transmitting data. To use this profile a Pebble developer will
use the same APIs described in this guide with the service ID and attribute ID
set to ``SMARTSTRAP_RAW_DATA_SERVICE_ID`` and
``SMARTSTRAP_RAW_DATA_ATTRIBUTE_ID`` SDK constants respectively.


## Manipulating Attributes

The ``Smartstrap`` API uses the ``SmartstrapAttribute`` type as a proxy for an
attribute on the smartstrap. It includes the service ID of the attribute, the ID
of the attribute itself, as well as a data buffer that is used to store the
latest read or written value of the attribute.

Before you can read or write an attribute, you need to initialize a
`SmartstrapAttribute` that will be used as a proxy for the attribute on the
smartstrap. The first step developers should take is to decide upon and define
their services and attributes:

```c
// Define constants for your service ID, attribute ID 
// and buffer size of your attribute.
static const SmartstrapServiceId s_service_id = 0x1001;
static const SmartstrapAttributeId s_attribute_id = 0x0001;
static const int s_buffer_length = 64;
```

Then, define the attribute globally:

```c
// Declare an attribute pointer
static SmartstrapAttribute *s_attribute;
```

Lastly create the attribute during app initialization, allocating its buffer:

```c
// Create the attribute, and allocate a buffer for its data
s_attribute = smartstrap_attribute_create(s_service_id, s_attribute_id, 
                                                            s_buffer_length);
```

Later on, APIs such as ``smartstrap_attribute_get_service_id()`` and
``smartstrap_attribute_get_attribute_id()`` can be used to confirm these values
for any ``SmartstrapAttribute`` created previously. This is useful if an app
deals with more than one service or attribute.

Attributes can also be destroyed when an app is exiting or no longer requires
them by using ``smartstrap_attribute_destroy()``:

```c
// Destroy this attribute
smartstrap_attribute_destroy(s_attribute);
```


## Connecting to a Smartstrap

The first thing a smartstrap-enabled app should do is call
``smartstrap_subscribe()`` to register the handler functions (described below)
that will be called when smartstrap-related events occur. Such events can be one
of four types.

The ``SmartstrapServiceAvailabilityHandler`` handler, used when a smartstrap
reports that a service is available, or has become unavailable.

```c
static void strap_availability_handler(SmartstrapServiceId service_id,
                                       bool is_available) {
  // A service's availability has changed
  APP_LOG(APP_LOG_LEVEL_INFO, "Service %d is %s available",
                                (int)service_id, is_available ? "now" : "NOT");
}
```

See below under [*Writing Data*](#writing-data) and 
[*Reading Data*](#reading-data) for explanations of the other callback types.

With all four of these handlers in place, the subscription to the associated
events can be registered.

```c
// Subscribe to the smartstrap events
smartstrap_subscribe((SmartstrapHandlers) {
  .availability_did_change = strap_availability_handler,
  .did_read = strap_read_handler,
  .did_write = strap_write_handler,
  .notified = strap_notify_handler
});
```

As with the other [`Event Services`](``Event Service``), the subscription can be
removed at any time:

```c
// Stop getting callbacks
smartstrap_unsubscribe();
```

The availability of a service can be queried at any time:

```c
if(smartstrap_service_is_available(s_service_id)) {
  // Our service is available!

} else {
  // Our service is not currently available, handle gracefully
  APP_LOG(APP_LOG_LEVEL_ERROR, "Service %d is not available.", (int)s_service_id);
}
```


## Writing Data

The smartstrap communication model (detailed under 
{% guide_link smartstraps/smartstrap-protocol#communication-model "Communication Model" %})
uses the master-slave principle. This one-way relationship means that Pebble can
request data from the smartstrap at any time, but the smartstrap cannot.
However, the smartstrap may notify the watch that data is waiting to be read so
that the watch can read that data at the next opportunity.

To send data to a smartstrap an app must call
``smartstrap_attribute_begin_write()`` which will return a buffer to write into.
When the app is done preparing the data to be sent in the buffer, it calls
``smartstrap_attribute_end_write()`` to actually send the data.

```c
// Pointer to the attribute buffer
size_t buff_size;
uint8_t *buffer;

// Begin the write request, getting the buffer and its length
smartstrap_attribute_begin_write(attribute, &buffer, &buff_size);

// Store the data to be written to this attribute
snprintf((char*)buffer, buff_size, "Hello, smartstrap!");

// End the write request, and send the data, not expecting a response
smartstrap_attribute_end_write(attribute, buff_size, false);
```

> Another message cannot be sent until the strap responds (a `did_write`
> callback for Write requests, or `did_read` for Read/Write+Read requests) or
> the timeout expires. Doing so will cause the API to return
> ``SmartstrapResultBusy``. Read 
> {% guide_link smartstraps/talking-to-smartstraps#timeouts "Timeouts" %} for
> more information on smartstrap timeouts.

The ``SmartstrapWriteHandler`` will be called when the smartstrap has
acknowledged the write operation (if using the Raw Data Service, there
is no acknowledgement and the callback will be called when Pebble is done
sending the frame to the smartstrap). If a read is requested (with the
`request_read` parameter of ``smartstrap_attribute_end_write()``) then the read
callback will also be called when the smartstrap sends the attribute value.

```c
static void strap_write_handler(SmartstrapAttribute *attribute,
                                SmartstrapResult result) {
  // A write operation has been attempted
  if(result != SmartstrapResultOk) {
    // Handle the failure
    APP_LOG(APP_LOG_LEVEL_ERROR, "Smartstrap error occured: %s",
                                          smartstrap_result_to_string(result));
  }
}
```

If a timeout occurs on a non-raw-data write request (with the `request_read`
parameter set to `false`), ``SmartstrapResultTimeOut`` will be passed to the
`did_write` handler on the watch side.


## Reading Data

The simplest way to trigger a read request is to call
``smartstrap_attribute_read()``. Another way to trigger a read is to set the
`request_read` parameter of ``smartstrap_attribute_end_write()`` to `true`. In
both cases, the response will be received asynchronously and the
``SmartstrapReadHandler`` will be called when it is received.

```c
static void strap_read_handler(SmartstrapAttribute *attribute,
                               SmartstrapResult result, const uint8_t *data,
                               size_t length) {
  if(result == SmartstrapResultOk) {
    // Data has been read into the data buffer provided
    APP_LOG(APP_LOG_LEVEL_INFO, "Smartstrap sent: %s", (char*)data);
  } else {
    // Some error has occured
    APP_LOG(APP_LOG_LEVEL_ERROR, "Error in read handler: %d", (int)result);
  }
}

static void read_attribute() {
  SmartstrapResult result = smartstrap_attribute_read(attribute);
  if(result != SmartstrapResultOk) {
    APP_LOG(APP_LOG_LEVEL_ERROR, "Error reading attribute: %s",
                                        smartstrap_result_to_string(result));
  }
}
```

> Note: ``smartstrap_attribute_begin_write()`` may not be called within a
> `did_read` handler (``SmartstrapResultBusy`` will be returned).

Similar to write requests, if a timeout occurs when making a read request the
`did_read` handler will be called with ``SmartstrapResultTimeOut`` passed in the
`result` parameter.


## Receiving Notifications

To save as much power as possible, the notification mechanism can be used by the
smartstrap to alert the watch when there is data that requires processing. When
this happens, the ``SmartstrapNotifyHandler`` handler is called with the
appropriate attribute provided. Developers can use this mechanism to allow the
watch to sleep until it is time to read data from the smartstrap, or simply as a
messsaging mechanism.

```c
static void strap_notify_handler(SmartstrapAttribute *attribute) {
  // The smartstrap has emitted a notification for this attribute
  APP_LOG(APP_LOG_LEVEL_INFO, "Attribute with ID %d sent notification",
                        (int)smartstrap_attribute_get_attribute_id(attribute));

  // Some data is ready, let's read it
  smartstrap_attribute_read(attribute);
}
```


## Callbacks For Each Type of Request

There are a few different scenarios that involve the ``SmartstrapReadHandler``
and ``SmartstrapWriteHandler``, where the callbacks to these
``SmartstrapHandlers`` will change depending on the type of request made by the
watch.

| Request Type | Callback Sequence |
|--------------|-------------------|
| Read only | `did_write` when the request is sent. `did_read` when the response arrives or an error (e.g.: a timeout) occurs. |
| Write+Read request | `did_write` when the request is sent. `did_read` when the response arrives or an error (e.g.: a timeout) occurs. |
| Write (Raw Data Service) | `did_write` when the request is sent. |
| Write (any other service) | `did_write` when the write request is acknowledged by the smartstrap. |

For Write requests only, `did_write` will be called when the attribute is ready
for another request, and for Reads/Write+Read requests `did_read` will be called
when the attribute is ready for another request.


## Timeouts

Read requests and write requests to an attribute expect a response from the
smartstrap and will generate a timeout error if the strap does not respond
before the expiry of the timeout.

The maximum timeout value supported is 1000ms, with the default value
``SMARTSTRAP_TIMEOUT_DEFAULT`` of 250ms. A smaller or larger value can be
specified by the developer:

```c
// Set a timeout of 500ms
smartstrap_set_timeout(500);
```


## Smartstrap Results

When data is sent to the smartstrap, one of several results is possible. These
are returned by various API functions (such as ``smartstrap_attribute_read()``),
and are enumerated as follows:

| Result | Value | Description |
|--------|-------|-------------|
| `SmartstrapResultOk` | `0` | No error occured. |
| `SmartstrapResultInvalidArgs` | `1` | The arguments provided were invalid. |
| `SmartstrapResultNotPresent` | `2` | The Smartstrap port is not present on this watch. |
| `SmartstrapResultBusy` | `3` | The connection is currently busy. For example, this can happen if the watch is waiting for a response from the smartstrap. |
| `SmartstrapResultServiceUnavailable` | `4` | Either a smartstrap is not connected or the connected smartstrap does not support the specified service. |
| `SmartstrapResultAttributeUnsupported` | `5` | The smartstrap reported that it does not support the requested attribute. |
| `SmartstrapResultTimeOut` | `6` | A timeout occured during the request. |

The function shown below returns a human-readable string for each value, useful
for debugging.

```c
static char* smartstrap_result_to_string(SmartstrapResult result) {
  switch(result) {
    case SmartstrapResultOk:
      return "SmartstrapResultOk";
    case SmartstrapResultInvalidArgs:
      return "SmartstrapResultInvalidArgs";
    case SmartstrapResultNotPresent:
      return "SmartstrapResultNotPresent";
    case SmartstrapResultBusy:
      return "SmartstrapResultBusy";
    case SmartstrapResultServiceUnavailable:
      return "SmartstrapResultServiceUnavailable";
    case SmartstrapResultAttributeUnsupported:
      return "SmartstrapResultAttributeUnsupported";
    case SmartstrapResultTimeOut:
      return "SmartstrapResultTimeOut";
    default:
      return "Not a SmartstrapResult value!";
  }
}
```
