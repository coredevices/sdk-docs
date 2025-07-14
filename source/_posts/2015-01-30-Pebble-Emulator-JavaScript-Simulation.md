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

title: Pebble Emulator 2/2 - JavaScript and CloudPebble
author: katharine
tags:
- Down the Rabbit Hole
date: 2015-01-30
---

This is another in a series of technical articles provided by the members of the
Pebble software engineering team. This article describes some recent work done
at Pebble to develop a Pebble emulator based on the QEMU project (QEMU, short
for Quick EMUlator, is a generic, open source machine emulator and virtualizer).




> This post is part 2 of 2, and details the work undertaken to provide emulation
> of the PebbleKit JS and CloudPebble aspects of emulating a Pebble in its
> entirety. Read
> [*Pebble Emulator 1/2 - QEMU For Pebble*][9] for information on 
> the creation of the Pebble Emulator.

For developers of third-party apps it is insufficient to emulate just the Pebble
itself, as most non-trivial apps also run JavaScript on the phone to provide the
watchapp with additional information. Furthermore, some apps are written
entirely in JavaScript using Pebble.js; it is important to support those as
well.

We therefore decided to implement support for running JavaScript in tandem with
the emulated Pebble. The JavaScript simulator is called [*pypkjs*][11].

## JavaScript Runtimes

Since our JavaScript environment primarily consists of standard HTML5 APIs, we
initially tried building on top of [PhantomJS][1]. However, we quickly ran into
issues with the very old version of WebKit it uses and a lack of flexibility in
implementing the functionality we needed, so we abandoned this plan.

Our second attempt was to use [node.js][2], but this proved impractical because
it was difficult to inject additional APIs into modules before loading them, by
which time they may have already tried to use them. Furthermore, some libraries
detected that they were running in node and behaved differently than they would
in the mobile apps; this discrepancy proved tricky to eliminate.

We ultimately chose to build directly on top of 
[Google’s V8 JavaScript Engine][3], making use of the [PyV8][4] Python bindings 
to reduce the effort involved in writing our APIs. This gave us the flexibility
to provide exactly the set of APIs we wanted, without worrying about the
namespace already being polluted. PyV8 made it easy to define these without
worrying about the arcana of the C++ V8 interface.

## Threading and Event Handling

JavaScript is intrinsically single-threaded, and makes heavy use of events. In
order to provide event handling, we used [gevent][5] to provide support the key
support for our event loop using greenlets. The “main thread” of the interpreter
is then a single greenlet, which first evaluates the JavaScript file and then
enters a blocking event loop. The PebbleKit JS program is terminated when this
event loop ends. Any calls to asynchronous APIs will then spawn a new greenlet,
which will ultimately add a callback to the event queue to take effect on the
main thread.

PebbleKit JS provides for single and repeating timers, which can take either a
function to call or a string to be evaluated when the timer expires. We
implemented these timers by spawning a new greenlet that sleeps for the given
period of time, then places either the function call or a call to eval on the
event queue.

## HTML5 APIs

Since we are using V8 without any additions (e.g. from Chromium), none of the
standard HTML5 APIs are present. This works in our favour: we only support a
restricted subset for PebbleKit JS. Our Android and iOS apps differ in their
support, so we chose to make the emulator support only the common subset of
officially supported APIs: XMLHttpRequest, localStorage, geolocation, timers,
logging and performance measurement. We implemented each of these in Python,
exposing them to the app via PyV8. We additionally support standard JavaScript
language features; these are provided for us by V8.

## LocalStorage

LocalStorage provides persistent storage to PebbleKit JS apps. It is a tricky
API to implement, as it has properties that are unlike most objects in
JavaScript. In particular, it can be accessed using either a series of method
calls (`getItem`, `setItem`, `removeItem`, etc.), as well as via direct property
access. In either case, the values set should be immediately converted to
strings and persisted. Furthermore, iterating over the object should iterate
over exactly those keys set on it, without any additional properties. Correctly
capturing all of these properties took three attempts.

Our first approach was to directly provide a Python object to PyV8, which
implemented the python magic methods `__setattr__`, `__delattr__` and
`__getattr__` to catch attribute access and handle them appropriately. However,
this resulted in ugly code and made it impossible to correctly implement the
LocalStorage iteration behaviour as PyV8 does not translate non-standard python
iterators.

The second approach was to create a native JavaScript object using
Object.create, set the functions on it such that they would not appear in
iteration, and use an ECMAScript 6 (“ES6”) Observer to watch for changes to the
object that should be handled. This approach failed on two fronts. The primary
issue was that we could not catch use of the delete operator on keys set using
property accessors, which would result in values not being removed. Secondly,
Observers are asynchronous. This made it impossible to implement the immediate
cast-to-string that LocalStorage performs.

The final approach was to use an ES6 Proxy to intercept all calls to the object.
This enabled us to synchronously catc property accesses to cast and store them.
It also provided the ability to provide custom iteration behaviour. This
approach lead to a clean, workable and fully-compliant implementation.

## Timers

PebbleKit JS provides for single and repeating timers, which can take either a
function to call or a string to be evaluated when the timer expires. We
implemented these timers by spawning a new greenlet that sleeps for the given
period of time, then places either the function call or a call to eval on the
event queue.

## Geolocation

PebbleKit JS provides access to the phone’s geolocation facilities. According to
the documentation, applications must specify that they will use geolocation by
giving the ‘location’ capability in their manifest file. In practice, the mobile
apps have never enforced this restriction, and implementing this check turned
out to break many apps. As such, geolocation is always permitted in the
emulator, too.

Since there is no geolocation capability readily available to the emulator, it
instead uses the MaxMind GeoIP database to look up the user’s approximate
location. In practice, this works reasonably well as long as the emulator is
actually running on the user’s computer. However, when the emulator is *not*
running on the user’s computer (e.g. when using CloudPebble), the result isn’t
very useful.

## XMLHttpRequest

Support for XMLHttpRequest is primarily implemented using the Python 
[*requests* library][6]. Since requests only supports synchronous requests, and
XMLHttpRequest is primarily asynchronous, we spawn a new greenlet to process the
send request and fire the required callbacks. In synchronous mode we join that
greenlet before returning. In synchronous mode we must also place the *creation*
of the events on the event queue, as creating events requires interacting with
V8, which may cause errors while the main greenlet is blocked.

## Pebble APIs

PebbleKit JS provides an additional Pebble object for communicating with the
watch and handling Pebble accounts. Unlike the HTML5 APIs, these calls have no
specification, instead having two conflicting implementations and often vague or
inaccurate documentation that ignores the behaviour of edge cases. Testing real
apps with these, especially those that do not strictly conform to the
documentation, has required repeated revisions to the emulated implementation to
match what the real mobile apps do. For instance, it is not clear what should be
done when an app tries to send the float *NaN* as an integer.

## Watch Communication

The PebbleKit JS runtime creates a connection to a TCP socket exposed by QEMU
and connected to the qemu_serial device. Messages from PebbleKit JS are
exclusively Pebble Protocol messages sent to the bluetooth channel exposed over
the Pebble QEMU Protocol. A greenlet is spawned to read from this channel.

The primary means of communication available to apps over this channel is
AppMessage, a mechanism for communicating dictionaries of key-value pairs to the
watch. These are constructed from the provided JavaScript object. It is possible
for applications to use string keys; these are replaced with integer keys from
the app’s manifest file before sending. If no such key can be found an exception
is thrown. This is the documented behaviour, but diverges from the implemented
behaviour; both mobile apps will silently discard the erroneous key.

When messages are received, a new JavaScript object is created and the messages
parsed into JavaScript objects. Here we perform the reverse mapping, converting
received integers to string keys, if any matching keys are specified in the
app’s manifest. An event is then dispatched to the event loop on the main
greenlet.

A method is also provided for showing a “simple notification”; again, it is not
clear what sort of notification this should be. This implementation sends an SMS
notification, which appears to be consistent with what the iOS app does.

## Configuration Pages

PebbleKit JS provides the option for developers to show a “configuration page”
in response to the user pressing a Settings button in the Pebble mobile app.
These configuration pages open a webview containing a user-specified webpage.
The mobile apps capture navigation to the special URL ‘pebblejs://close’, at
which point they dismiss the webview and pass the URL fragment to the PebbleKit
JS app.

However, our emulator does not have the ability to present a webview and handle
the custom URL scheme, so another approach is required. We therefore pass a new
query parameter, ‘return_to’, to which we pass a URL that should be used in
place of the custom URL scheme. Configuration pages therefore must be modified
slightly: instead of using the fixed URL, they should use the value of the
‘return_to’ parameter, defaulting to the old pebblejs://close URL if it is
absent.

When a URL is opened, the PebbleKit JS simulator starts a temporary webserver
and gives a URL for it in the ‘return_to’ parameter. When that page is loaded,
it terminates the webserver and passes the result to the PebbleKit JS app.

## Exception Handling

There are three potential sources of exceptions: errors in the user’s
JavaScript, error conditions for which we generate exceptions (e.g. invalid
AppMessage keys), and unintentional exceptions thrown inside our JavaScript
code. In all cases, we want to provide the user with useful messages and
JavaScript stack traces.

PyV8 supports exceptions, and will translate exceptions between Python and
JavaScript: most exceptions from JavaScript will become JSErrors in Python, and
exceptions from Python will generally become Exceptions in JavaScript. JSErrors
have a stack trace attached, which can be used to report to the user. PyV8 also
has some explicit support for IndexErrors (RangeErrors in JavaScript),
ReferenceErrors, SyntaxErrors and TypeErrors. When such an exception passes the
Python/JavaScript boundary, it is converted to its matching type.

This exception conversion support causes a complication: when a support
exception crosses from JavaScript to Python, it is turned into a standard Python
exception rather than a JSError, and so has no stack trace or other JavaScript
information attached. Since many exceptions become one of those (even when
thrown from inside JavaScript), and all exception handling occurs in Python,
many exceptions came through without any useful stack trace.

To resolve this issue, we [forked PyV8][7] and changed its exception handling.
We now define new exceptions for each of the four supported classes that
multiple- inherit from their respective Python exceptions and JSError, and still
have JavaScript stack information attached. We can then catch these exceptions
and display exception information as appropriate.

Due to the asynchronous nature of JavaScript, and the heavily greenlet-based
implementation of pypkjs, we must ensure that every point at which we call into
developer-provided JavaScript does something useful with any exceptions that may
be thrown so that JavaScript traces can be passed back to the developer.
Fortunately, the number of entry points is relatively small: the event system
and the initial evaluation are the key points to handle exceptions.

## Sandboxing

While PyV8 makes it very easy to just pass Python objects into JavaScript
programs and have them treated like standard JavaScript objects, this support is
an approximation. The resulting objects still feature all the standard Python
magic methods and properties, which the JavaScript program can access and call.
Furthermore, Python has no concept of private properties; any object state that
the Python code has access to can also be accessed by the JavaScript program.

While this behaviour is good enough when working with JavaScript programs that
expect to be running in this environment, the programs that will be run here are
not expecting to run in this environment. Furthermore, they are untrusted; with
access to the runtime internals, they could potentially wreak havoc.

In order to present a cleaner interface to the JavaScript programs, we instead
define JavaScript extensions that, inside a closure, feature a ‘native function’
call. These objects then define proxy functions that call the equivalent
functions in the Python implementation. By doing this, we both present genuine
JavaScript objects that act like real objects in all ways, and prevent access to
the implementation details of the runtime.

## Emulation in CloudPebble

The majority of our developers use our web-based development environment,
CloudPebble. The QEMU Pebble emulator and PebbleKit JS simulator described above
are designed for desktop use, and so would not in themselves be useful to the
majority of our developers. Some arrangement therefore had to be made for those
developers.

We decided to run a cluster of backend servers which would run QEMU on behalf of
CloudPebble’s users; CloudPebble would then interact with these servers to
handle input and display.

## Displaying the Screen

Displaying a remote framebuffer is a common problem; the most common solution to
this problem is VNC’s Remote Framebuffer Protocol. QEMU has a VNC server built-
in, making this the obvious choice to handle displaying the screen.

CloudPebble’s VNC client is based on [noVNC][8], an HTML5 JavaScript-based VNC
client. Since JavaScript cannot create raw socket connections, noVNC instead
connects to the QEMU VNC server via VNC-over-websockets. QEMU already had
support for this protocol, but crashed on receiving a connection. We made a
minor change to initialisation to resolve this.

While it would appear to make sense to use indexed colour instead of 24-bit true
colour for our 1-bit display, QEMU does not support this mode. In practice,
performance of the true colour display is entirely acceptable, so we did not
pursue this optimisation.

## Communicating With the Emulator

CloudPebble expects to be able to communicate with the watch to install apps,
retrieve logs, take screenshots, etc. With physical watches, this is done by
connecting to the phone and communicating over the Pebble WebSocket Protocol
(PWP). Due to restrictions on WebSocket connections within local networks,
CloudPebble actually connects to an authenticated WebSocket proxy which the
phone also connects to. In addition, this communication occurs over bluetooth —
but the PebbleKit JS runtime is already connected to the qemu_serial socket,
which can only support one client at a time.

We therefore chose to implement PWP in the PebbleKit JS simulator. This neatly
the issue with multiple connections to the same socket, closely mimics how the
real phone apps behave, and minimises the scope of the changes required to
CloudPebble. CloudPebble’s use of a WebSocket proxy provides further opportunity
to imitate that layer as well, enabling us to take advantage of the existing
authentication mechanisms in CloudPebble.

The PebbleKit JS simulator was thus split out to have two ‘runners’; one that
provides the standard terminal output (sendings logs to stdout and interacting
with the user’s local machine) and one that implements PWP. The WebSocket runner
additionally hooks into the low-level send and receive methods in order to
provide the message echoing functionality specified by PWP. Since the emulator
requires some communication that is not necessary with real phones, there are
were some extensions added that are used only by the emulator. However, for the
most part, existing code works exactly as before once pointed to the new
WebSocket URL.

## Configuration Pages

The mechanism previously designed for configuration pages is only usable when
running locally. To trigger a configuration page, CloudPebble sends a request
using an extension to the PWP. If the PebbleKit JS app implements a
configuration page, it receives a response giving it the developer’s intended
URL. CloudPebble then inserts a return_to parameter and opens a new window with
the developer’s page. Once the page navigates to the return URL, the page is
closed and the configuration data sent back over the WebSocket.

Due to restrictions on how windows may communicate, CloudPebble must poll the
new window to discover if it has navigated to the return URL. Once the
navigation is detected, CloudPebble sends it a message and receives the
configuration data in reply, after which the window closes.

A further complication is pop-up blockers. These usually only permit window
opens in response to direct user action. Since we had to request a URL from the
PebbleKit JS app before we could open the window, an active popup blocker will
tend to block the window. We worked around this by detecting the failure of the
window to open and providing a button to click, which will usually bypass the
popup blocker.

## Input

Originally, button input from CloudPebble was performed by sending keypresses
over VNC directly to QEMU. However, this turned out to cause issues with key-
repeat and long button presses. Resolving these issues proved to be difficult,
so we instead avoided sending VNC keypresses at all. Instead, another extension
was added to the PWP that permitted sending arbitrary PQP messages to the
emulator. We then sent packets indicating the state of each button to the
emulator via PWP. However, mouse clicks tend to be quicker than Pebble watch
button presses, and the time that the buttons appeared to be ‘pressed’ was too
short for the firmware to react. To avoid this problem, we rate limited
CloudPebble to send state changes no more rapidly than once every 100ms; more
rapid changes are queued to be sent later.

The channel for sending PQP messages over PWP is also used to set the battery
state and toggle bluetooth; in the future, we will also use it to set the
accelerometer and compass readings.

## Compass and Accelerometer Sensors

Most computers do not have a compass or an accelerometer — and even if they did,
it would be impractical to pick up the computer and shake it, tilt it, or rotate
it to test apps. To deal with this, we took advantage of a piece of hardware
owned by all Pebble owners, and likely most Pebble developers: their phones.

When developers want to use their phones to provide sensor data, a six-digit
code is generated and stored with the information required to connect to the
emulator. The user is prompted to open a short URL (cpbl.io) on their phone and
enter the code on that webpage. The code is looked up and, if found, a
connection to the emulator is established from the webpage on their phone. The
webpage then collects accelerometer and compass data using the 
[HTML5 DeviceOrientation APIs][10] and streams it to the emulator.

The generated codes expire a few minutes after being generated.

## Emulator Management

CloudPebble must manage multiple emulators on potentially multiple hosts.
Management is split between CloudPebble itself and a [controller program][12]
responsible for managing the lifecycle of individual emulator instances.

CloudPebble is aware of a pool of emulator hosts. When a user requests an
emulator, it picks one at random and requests that its manager spin up an
emulator. If this is possible, it returns connection details for the emulator to
the client; if not (e.g. because that host has reached capacity), it picks
another host and tries again. If no hosts are available a failure message is
reported to the client and logged in our analytics system.

The manager program selects some unused ports and spawns instances of QEMU and
pypkjs configured to work together, and reports back a UUID and public port
numbers for the VNC and Pebble WebSocket Protocol servers. The manager then
expects to be pinged for that emulator periodically; if too long passes without
being pinged or either QEMU or pypkjs fail, the QEMU and pypkjs instances will
be terminated.

A complication arose when attempting to run this system over the Internet. Some
users, especially behind corporate firewalls, cannot make connections to the
non-standard ports that the manager was selecting. To avoid this issue, the
manager (which runs on the standard HTTPS port 443) can proxy connections to the
VNC and PWP websockets.

Finally, in order to restrict abuse and provide continuity across client
reloads, CloudPebble tracks emulators assigned to users in a Redis database. If
a user who already has an emulator requests one and CloudPebble can ping their
emulator, they are given the same instance again. A new instance can be
requested by explicitly killing the emulator in the CloudPebble UI, or closing
the client and waiting for the manager to time out and kill the emulator.


[1]: http://phantomjs.org
[2]: http://nodejs.org
[3]: https://code.google.com/p/v8/
[4]: https://code.google.com/p/pyv8/
[5]: http://www.gevent.org
[6]: http://docs.python-requests.org/en/latest/
[7]: https://github.com/pebble/pyv8
[8]: https://github.com/kanaka/noVNC
[9]: /blog/2015/01/30/Development-Of-The-Pebble-Emulator/
[10]: http://w3c.github.io/deviceorientation/spec-source-orientation.html
[11]: https://github.com/pebble/pypkjs
[12]: https://github.com/pebble/cloudpebble-qemu-controller