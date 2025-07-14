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

title: Pebble Emulator 1/2 - QEMU for Pebble
author: Ron Marianetti
tags:
- Down the Rabbit Hole
date: 2015-01-30
---

This is another in a series of technical articles provided by the members of the
Pebble software engineering team. This article describes some recent work done
at Pebble to develop a Pebble emulator based on the QEMU project (QEMU, short
for Quick EMUlator, is a generic, open source machine emulator and virtualizer).




> This post is part 1 of 2, and covers the development of the Pebble QEMU
> emulator itself. Read 
> [*Pebble Emulator 2/2 - JavaScript and CloudPebble*][1] 
> for more information on PebbleKit JS emulation and
> embedding the emulator in CloudPebble.

An early implementation of this emulator was used internally at Pebble over a
year ago and was mentioned in a previous article published in April, 2014, 
[*How Pebble Converted 135,070 Customized Watchfaces for Pebble OS v2.0.*][4] 
However, it had languished due to lack of attention, and somewhere along the
line changes made to the firmware had broke it altogether.

An emulator has many benefits, not only for outside developers but also for the
internal team:

* New software can be loaded, executed, and tested much faster on the emulator
  than on actual hardware.
* It greatly facilitates automated testing, due to the faster speed of
  execution, convenience, and ease of scripting.
* For internal use, the emulator can be built to run firmware images that
  wouldn’t fit into the limited memory of the real hardware, enabling engineers
  to develop and test new features with extra debugging features included.
* Some tasks, like testing localization changes, can be easily performed in
  parallel by launching a different emulator instance for each language.

[The QEMU open source project][2] was written by Fabrice Bellard. QEMU is a very
flexible and powerful code base capable of emulating a wide variety CPUs, one of
which is the ARM Cortex M3 that is inside the STM32F2xx microcontroller used in
the Pebble. Building upon the core QEMU project as a base, Andre Beckus created
a [fork][3] that adds in support for the hardware peripherals of the STM32F1xx
series of microcontrollers. Pebble further built upon Andre Beckus’ fork for its
emulator and added in support for the STM32F2xx series of microcontrollers as
well as the specific hardware components in the Pebble that are outside the
microcontroller, like the display and buttons. The result is a full-featured
Pebble emulator capable of executing Pebble firmware images and native 3rd party
applications.

## Interacting With the Emulator

When you launch the Pebble emulator on a host machine you are presented with a
window displaying the contents of the Pebble display. You can interact with it
using the arrow keys from the keyboard, which act as the 4 buttons on the Pebble
(“back”, “up”, “down”, and “select”). You can also load in and run, unmodified,
any third-party watchface or watchapp written for the Pebble.

A huge part of the value of the Emulator is in the additional features it
provides for development and testing purposes, like being able to interact with
the Pebble through a terminal and debug it using gdb. These capabilities are not
even possible with a standard shipping Pebble. Before the emulator, the only way
engineers at Pebble could accomplish this was to use custom “big boards”, which
are specially built boards that include the standard Pebble components with the
addition of a USB port and associated circuitry.

The emulator exposes three socket connections to the outside world. The first,
the gdb socket, is built into the base QEMU framework itself and allows one to
connect and debug the emulated CPU using gdb. The second, the console socket, is
specific to Pebble emulation and is a simple terminal window into which you can
see print output and issue commands to the Pebble OS. The third, the qemu
channel, is also specific to Pebble emulation and is used for sending Bluetooth
traffic and various other hardware sensor information such as the battery level,
compass direction, and accelerometer readings.

## The GDB Socket

Built into QEMU is a gdb remote server that listens by default on port 1234 for
connections from gdb. This remote server implements most of the basic debugging
primitives required by gdb including inspecting memory, setting breakpoints,
single-stepping, etc.

A critical aspect to debugging firmware running on the Pebble is the ability to
see what each of the threads in the operating system is doing at any time. For
this, gdb provides the “info threads” and related commands like “thread apply
all backtrace”, etc. In order to gather the information about the threads
though, the gdb remote server needs to understand where the thread information
is stored in memory by the remote target, which of course is operating system
specific.

The built-in gdb remote server implemented by QEMU does not have this knowledge
because it is specific to the Pebble. Internally, Pebble uses FreeRTOS for
managing threads, mutexes, semaphores, etc. Since the location of this
information in memory could easily change in different versions of the Pebble
firmware, it did not seem appropriate to incorporate it into QEMU. Instead, we
took the approach of creating a proxy process that sits between gdb and the gdb
remote server implemented by QEMU. This proxy forwards most generic requests
from gdb unmodified to QEMU and returns the responses from QEMU back to gdb. If
however it sees a request from gdb that is thread related, it does the handling
in the proxy itself. Interpreting the thread command generally involves issuing
a series of primitive memory read requests to QEMU to gather the information
stored by FreeRTOS. This design ensures that the QEMU code base is isolated from
the operating system dependencies of the Pebble firmware that could change from
version to version.

## The Console Socket

Console input and output has always been built into the Pebble OS but was
traditionally only accessible when using one of the engineering “big boards”.
There are function calls in Pebble OS for sending output to the console and a
simple interpreter and executor that parses input commands. This console output
and the available commands are invaluable tools when developing and debugging
the Pebble firmware.

Routing this console output to a TCP socket leverages a very powerful and
flexible feature of QEMU, which is the ability to create up to four virtual
serial devices. Each serial device can be associated with a file, pipe,
communication port, TCP socket (identified by port number), etc. This capability
is exposed through the  `-serial` command line option of QEMU. When we launch
QEMU to emulate a Pebble, we create one of these serial devices for console use
and assign it to a socket. On the emulated Pebble side, the firmware is simply
accessing a UART peripheral built into the STM32F2xx and has no knowledge of the
external socket connection. In QEMU, the code that emulates that UART device is
given a reference to that virtual serial device so that it can ferry data
between the two.

## The QEMU Channel Socket

The third socket is the Pebble QEMU channel (PQ channel). This channel is used
for a number of purposes that are specific to the Pebble running in the
emulator. For example, we send data through this channel to give the Pebble
custom sensor readings like accelerometer, compass, battery level, etc. We also
use this channel to send and receive Bluetooth traffic.

We have decided to take the approach of creating custom builds of the firmware
for use in the emulator, which frees us from having to make the emulator run the
exact same firmware image that runs on an actual hardware. Of course it is
advantageous to minimize the differences as much as possible. When it comes to
each of the hardware features that needs to be emulated, a judgment call thus
has to be made on where to draw the line – try to emulate the hardware exactly
or replace some of the low level code in the firmware.  Some of the areas in the
firmware that we have decided to modify for the emulator are the areas that
handle Bluetooth traffic, accelerometer readings, and compass readings, for
example.

There is some custom code built into the firmware when it is built for QEMU to
support the PQ channel. It consists of two components: a fairly generic
STM32F2xx UART device driver (called “qemu_serial”) coupled with some logic to
parse out “Pebble QEMU Protocol” (PQP) packets that are sent over this channel
and pass them onto the appropriate handler. Every PQP packet is framed with a
PQP header containing a packet length and protocol identifier field, which is
used to identify the type of data in the packet and the handler for it.

## Bluetooth Traffic

In the Pebble OS, there is a communication protocol used which is called, not
surprisingly, “Pebble Protocol”.  When running on a real Pebble, this protocol
sits on top of Bluetooth serial and is used for communication between the phone
and the Pebble. For example, this protocol is used to install apps onto the
Pebble, get the list of installed apps, set the time and date on the watch, etc.

The pebble SDK comes with a command line tool called simply “pebble” which also
allows you to leverage this protocol and install watch apps directly from a host
computer. When using the pebble tool, the tool is actually sending Pebble
protocol packets to your phone over a WebSocket and the Pebble app on the phone
then forwards the packets to the Pebble over Bluetooth. On the Pebble side, the
Bluetooth stack collects the packet data from the radio and passes it up to a
layer of code in Pebble OS that interprets the Pebble Protocol formatted packet
and processes it.

Rather than try and emulate the Bluetooth radio in the emulator, we have instead
decided to replace the entire Bluetooth stack with custom code when building a
firmware image for QEMU. As long as this code can pass Pebble protocol packets
up, the rest of the firmware is none the wiser whether the data is coming from
the Bluetooth radio or not. We chose this approach after noticing that most
other emulators (for Android, iOS, etc.) have chosen not to try and emulate
Bluetooth using the radio on the host machine. Apparently, this is very
difficult to get right and fraught with problems.

To support the emulator, we have also modified the pebble tool in the SDK to
have a command line option for talking to the emulator. When this mode is used,
the pebble tool sends the Pebble Protocol packets to a TCP socket connected to
the PQ channel socket of the emulator. Before sending the Pebble Protocol packet
to this socket, it is framed with a PQP header with a protocol ID that
identifies it as a Pebble protocol packet.

## Accelerometer Data

Data for the accelerometer on the Pebble is also sent through the PQ channel. A
unique PQP protocol ID is used to identify it as accelerometer data. The pebble
tool in the SDK includes a command for sending either a fixed reading or a
series of accelerometer readings from a file to the emulator.

An accelerometer PQP packet includes a series of one or more accelerometer
reading. Each reading consists of three 16-bit integers specifying the amount of
force in each of the X, Y and Z-axes.

On actual hardware, the accelerometer is accessed over the i2c bus in the
STM32F2XX. A series of i2c transactions are issued to set the accelerometer mode
and settings and when enough samples are ready in its FIFO, it interrupts the
CPU so that the CPU can issue more i2c transactions to read the samples out.

The current state of the emulator does not yet have the STM32F2XX i2c peripheral
fully implemented and does not have any i2c devices, like the accelerometer,
emulated either. This is one area that could definitely be revisited in future
versions. For now, we have taken the approach of stubbing out device drivers
that use i2c when building the firmware for QEMU and plugging in custom device
drivers.

Control gets transferred to the custom accelerometer device driver for QEMU
whenever a PQP packet arrives with accelerometer data in it. From there, the
driver extracts the samples from the packet and saves them to its internal
memory. Periodically, the driver sends an event to the system informing it that
accelerometer data is available. When the system gets around to processing that
event, it calls back into the driver to read the samples.

When an application subscribes to the accelerometer, it expects to be woken up
periodically with the next set of accelerometer samples. For example, with the
default sampling rate of 25Hz and a sample size of 25, it should be woken up
once per second and sent 25 samples each time. The QEMU accelerometer driver
still maintains this regular wakeup and feed of samples, but if no new data has
been received from the PQ channel, it simply repeats the last sample  -
simulating that the accelerometer reading has not changed.

## Compass Data

Data for the compass on the Pebble is also sent through the PQ channel with a
unique PQP protocol ID. The pebble tool in the SDK includes a command for
sending compass orientation (in degrees) and calibration status.

On the Pebble side, we have a custom handler for PQP compass packets that simply
extracts the heading and calibration status from the packet and sends an event
to the system with this information – which is exactly how the real compass
driver hooks into the system.

## Battery Level

Data for the battery level on the Pebble is also sent through the PQ channel
with a unique PQP protocol ID. The pebble tool in the SDK includes a command for
setting the battery percent and the plugged-in status.

On the Pebble side, we have a custom handler for PQP battery packets inside a
dedicated QEMU battery driver.  When a PQP battery packet arrives, the driver
looks up the battery voltage corresponding to the requested percent and saves
it. This driver provides calls for fetching the voltage, percent and plugged-in
status.

On real hardware, the battery voltage is read using the analog to digital
converter (ADC) peripheral in the STM32F2xx. For now, the emulator takes the
approach of stubbing out the entire battery driver but in the future, it might
be worth considering emulating the ADC peripheral better and then just feed the
PQP packet data into the emulated ADC peripheral.

## Taps

On the real hardware, the accelerometer has built-in tap detection logic that
runs even when the FIFO based sample-collecting mode is turned off. This tap
detection logic is used to support features like the tap to turn on the
backlight, etc.

Data for the tap detection on the Pebble is also sent through the PQ channel
with a unique PQP protocol ID. The pebble tool in the SDK includes a command for
sending taps and giving the direction (+/-) and axis (X, Y, or Z).

On the Pebble side, we have a custom handler for PQP tap packets that simply
sends an event to the system with the tap direction and axis – which is exactly
what the hardware tap detection driver normally does.

## Button Presses

Button presses can be sent to the emulated Pebble through two different
mechanisms. QEMU itself monitors key presses on the host system and we hook into
a QEMU keyboard callback method and assert the pins on the emulated STM32F2xx
that would be asserted in real hardware depending on what key is pressed.

An alternate button pressing mechanism is exposed through the PQ channel and is
provided primarily for test automation purposes. But here, in contrast to how we
process things like accelerometer data, no special logic needs to be executed in
the firmware to handle these button PQP packets. Instead, they are processed
entirely on the QEMU side and it directly asserts the appropriate pin(s) on the
emulated STM32F2xx.

A module in QEMU called “pebble_control” handles this logic. This module
essentially sits between the PQ channel serial device created by QEMU and the
UART that we use to send PQP packets to the emulated Pebble. It is always
monitoring the traffic on the PQ channel. For some incoming packets, like button
packets, the pebble_control module intercepts and handles them directly rather
than passing them onto the UART of the emulated Pebble. To register a button
state, it just needs to assert the correct pins on the STM32F2xx depending on
which buttons are pressed. The button PQP packet includes the state of each
button (pressed or not) so that the pebble_control module can accurately reflect
that state among all the button pins.

## Device Emulation

So far, we have mainly just talked about how one interacts with the emulator and
sends sensor data to it from the outside world. What exactly is QEMU doing to
emulate the hardware?

## QEMU Devices

QEMU is structured such that each emulated hardware device (CPU, UART, flash
ROM, timer, ADC, RTC, etc.) is mirrored by a separate QEMU device. Typically,
each QEMU device is compiled into its own module and the vast majority of these
modules have no external entry points other than one that registers the device
with a name and a pointer to an initialization method.

There are far too many intricacies of QEMU to describe here, but suffice it to
say that the interface to each device in QEMU is standardized and generically
defined. You can map an address range to a device and also assign a device one
or more interrupt callbacks. Where a device would normally assert an interrupt
in the real hardware, it simply calls an interrupt callback in QEMU. When the
emulated CPU performs a memory access, QEMU looks up to see if that address maps
to any of the registered devices and dispatches control to a handler method for
that device with the intended address (and data if it is a write).

The basic mode of communication between devices in QEMU is through a method
called `qemu_set_irq()`. Contrary to its name, this method is not only used for
generating interrupts. Rather, it is a general-purpose method that calls a
registered callback. One example of how this is used in the Pebble emulation is
that we provide a callback to the pin on the emulated STM32F2xx that gets
asserted when the vibration is turned on. The callback we provide is a pointer
to a method in the display device. This enables the display device to change how
it renders the Pebble window in QEMU based on the vibration control.  The IRQ
callback mechanism is a powerful abstraction because an emulated device does not
need to know who or what it is connected to, it simply needs to call the
registered callback using `qemu_set_irq()`.

## Pebble Structure

We create multiple devices to emulate a Pebble. First of course there is the
CPU, which is an ARM v7m variant (already implemented in the base code of QEMU).

The STM32F2XX is a microcontroller containing an ARM v7m CPU and a rather
extensive set of peripherals including an interrupt controller, memory
protection unit (MPU), power control, clock control, real time clock, DMA
controller, multiple UARTS and timers, I2C bus, SPI bus, etc. Each of these
peripherals is emulated in a separate QEMU device. Many of these peripherals in
the STM32F2xx behave similarly with those in the STM32F1xx series of
microcontroller implemented in Andre Beckus’ fork of QEMU and so could be
extended and enhanced where necessary from his implementations.

Outside of the STM32F2xx, we have the Pebble specific devices including the
display, storage flash, and buttons and each of these is emulated as a separate
QEMU device as well. For the storage flash used in the Pebble, which sits on the
SPI bus, we could use a standard flash device already implemented in QEMU. The
display and button handling logic however are custom to the Pebble.

## Device Specifics

Getting the Pebble emulation up and running required adding some new QEMU
devices for peripherals in the STM32F2XX that are not in the STM32F1XX and
extending and enhancing some of the existing devices to emulate features that
were not yet fully implemented.

To give a flavor for the changes that were required, here is a sampling: the DMA
device was more fully implemented to support 8 streams of DMA with their
associated IRQs; a bug in the NOR flash device was addressed where it was
allowing one to change 0’s to 1’s (an actual device can only change 1’s to 0’s
when programming); many of the devices were raising an assert for registers that
were not implemented yet and support for these registers needed to be added in;
the PWR device for the STM32F2xx was added in; wake up timer support was not
implemented in the RTC; many devices were not resetting all of their registers
correctly in response to a hardware reset, etc.

## Real Time Clock

One of the more challenging devices to emulate correctly was the real time clock
(RTC) on the STM32F2xx. Our first implementation, for example, suffered from the
problem that the emulated Pebble did not keep accurate time, quite a glaring
issue for a watch!

The first attempt at emulating the RTC device relied on registering a QEMU timer
callback that would fire at a regular interval. The QEMU framework provides this
timer support and will attempt call your register callback after the requested
time elapses. In response to this callback, we would increment the seconds
register in the RTC by one, see if any alarm interrupts should fire, etc.

The problem with this approach is that there is no guarantee that the QEMU timer
callback method will be called at the exact requested time and, depending on the
load on the host machine, we were falling behind sometimes multiple minutes in
an hour.

To address this shortcoming, we modified the timer callback to instead fetch the
current host time, convert it to target time, and then modify the registers in
the RTC to match that newly computed target time. In case we are advancing the
target time by more than one in any specific timer callback, we also need to
check if any alarm interrupts were set to fire in that interval. We also update
the RTC time based on the host time (and process alarms) whenever a read request
comes in from the target for any of the time or calendar registers.

Although conceptually simple, there were a number of details that needed to be
worked out for this approach. For one, we have to maintain an accurate mapping
from host time to target time. Anytime the target modifies the RTC registers, we
also have to update the mapping from host to target time. The other complication
is that the Pebble does not use the RTC in the “classic” sense. Rather than
incrementing the seconds register once per second, the Pebble OS actually runs
that RTC at 1024 increments per second. It does this so that it can use the RTC
to measure time to millisecond resolution. The emulation of the RTC thus needs
to also honor the prescaler register settings of the RTC to get the correct
ratio of host time to target time.

A further complication arose in the Pebble firmware itself. When the Pebble OS
has nothing to do, it will put the CPU into stop mode to save power. Going into
stop mode turns off the clock and an RTC alarm is set to wake up the CPU after
the desired amount of time has elapsed. On real hardware, if we set the alarm to
fire in *N* milliseconds, we are guaranteed that when we wake up, the RTC will
read that it is now *N* milliseconds later. When running in emulation however,
quite often the emulation will fall slightly behind and by the time the emulated
target processes the alarm interrupt, the RTC registers will show that more than
*N* milliseconds have elapsed (especially since the RTC time on the target is
tied to the host time).  Addressing this required modifying some of the glue
logic we have around FreeRTOS in order to fix up the tick count and wait time
related variables for this possibility.

## UART Performance

We rely heavily on the PQ channel to communicate with the emulated pebble. We
use it to send 3rd party apps to the emulated pebble from the host machine for
example and even for sending firmware updates to the emulated Pebble.

The first implementation of the UART device though was giving us only about
1Kbyte/second throughput from the host machine to the emulated Pebble. It turns
out that the emulated UART device was telling QEMU to send it only 1 character
at a time from the TCP socket. Once it got that character, it would make it
available to the emulated target, and once the target read it out, it would tell
QEMU it had space for one more character from the socket, etc.

To address this, the QEMU UART device implementation was modified to tell QEMU
to send it a batch of bytes from the socket at a time, then those bytes were
dispatched to the target one at a time as it requested them. This simple change
gave us about a 100x improvement in throughput.

## CPU Emulation Issues

Running the Pebble OS in QEMU ended up stressing some aspects of the ARM that
were not exercised as completely before, and exposed a few holes in the CPU
emulation logic that are interesting to note.

The ARM processor has two operating modes (handler mode and thread mode) and two
different stack pointers it can use (MSP and PSP). In handler mode, it always
uses the MSP and in thread mode, it can use either one, depending on the setting
of a bit in one of the control registers. It turns out there was a bug in the
ARM emulation such that the control bit was being used to determine which stack
pointer to use even when in handler mode. The interesting thing about this is
that because of the way the Pebble OS runs, this bug would only show up when we
tried to launch a 3rd party app for the first time.

Another, more subtle bug had to do with interrupt masking. The ARM has a BASEPRI
register, which can be used to mask all interrupts below a certain priority,
where the priority can be between 1 and 255. This feature was not implemented in
QEMU, so even when the Pebble OS was setting BASEPRI to mask off some of the
interrupts, that setting was being ignored and any interrupt could still fire.
This led to some intermittent and fairly hard to reproduce crashes in the
emulated Pebble whose source remained a mystery for quite a while.

We discovered an issue that if the emulated CPU was executing a tight infinite
loop, that we could not connect using gdb. It turns out that although QEMU
creates multiple threads on the host machine, only one is allowed to effectively
run at a time. This makes coding in QEMU easier because you don’t have to worry
about thread concurrency issues, but it also resulted in the gdb thread not
getting a chance to run at all if the thread emulating the CPU had no reason to
exit (to read a register from a peripheral device for example). To address this,
we modified the CPU emulation logic to break out at least once every few hundred
instructions to see if any other thread had work to do.

As briefly mentioned earlier, the ARM has a stop mode that is used for power
savings and the Pebble OS uses this mode extensively. Going into stop mode turns
off the clock on the CPU and most peripherals until an alarm interrupt fires.
There was a flaw in the initial implementation of stop mode in the emulator that
resulted in any and all interrupts being able to wake up the CPU. The emulated
Pebble ran just fine and the user would not notice any problems. However, QEMU
ended up using 100% of a CPU on the host machine at all times. When this bug was
addressed, the typical CPU load of QEMU went down to about 10%. Addressing this
bug was critical for us in order to efficiently host enough QEMU instances on a
server farm for use by CloudPebble.

Another challenge in the CPU emulation was figuring out how to correctly
implement standby mode for the STM32F2xx. In standby mode, all peripherals are
powered off and the Pebble sets up the CPU to only wake up when the WKUP pin on
the STM32F2xx is asserted. This mode is entered when the user chooses “Shut
Down” from the Pebble settings menu or automatically when the battery gets
critically low. In most cases, wake up sources for the CPU (like the RTC
peripheral, UARTs, timers, etc.) generate an interrupt which first goes to the
interrupt controller (NVIC) which is outside the core CPU. The NVIC then figures
out the priority of the interrupt and only wakes the CPU if that priority of
interrupt is not masked off. The WKUP pin functionality is unique in that it is
not a normal interrupt, cannot be masked, and instead of resulting in the
execution of an interrupt service routine, it results in a reset of the CPU.
Figuring out how to hook this up correctly into QEMU required quite a bit of
learning and investigation into the core interrupt handling machinery in QEMU
and understanding difference between that and the WKUP functionality.

## Window Dressing

A few of the many fun things about working on the emulator had to do with
finding creative ways to represent things such as the brightness of the
backlight and the status of the vibration output.

In the Pebble hardware, a timer peripheral is used to generate a PWM (Pulse
Width Modulated) output signal whose duty cycle controls the brightness of the
backlight. This allows the Pebble to gradually ramp up and down the brightness
of the backlight. In QEMU, the STM32F2xx timer device was enhanced to support
registering a QEMU IRQ handler that it would call whenever the PWM output value
was changed. In QEMU, when you call an interrupt handler callback using
`qemu_set_irq()`, you pass in an integer argument, allowing one to pass a scalar
value if need be. A “brightness” interrupt handler callback was added to the
Pebble display device and this callback was registered with the timer
peripheral. Once hooked up, this enabled the display to be informed whenever the
PWM output value changed. The display device implementation was then modified to
adjust the brightness (via the RGB color) of the pixels rendered to the display
based on the scalar value last sent to its brightness callback.

Whenever the Pebble firmware decides to turn on the vibration, it asserts one of
the GPIO (General Purpose IO) pins on the STM32F2xx. To implement this feature,
a “vibration” callback was added to the display device implementation and this
callback was registered with the GPIO device pin that gets asserted by the
firmware in order to vibrate. To implement the vibrate, the display device
repeatedly re-renders the contents of the Pebble screen to the window offset
plus or minus 2 pixels, giving the illusion of a vibrating window.

## Future Work

The Pebble emulator has already proven to be a great productivity enhancer in
its current state, and has a lot of potential for future enhancements and
improvements.

It would be interesting for example to investigate how well we can emulate I2C
and some of the I2C devices used in the Pebble. Doing this could allow us to use
more of the native device drivers in the firmware for things like the
accelerometer rather than having to plug in special QEMU based ones.

Another area for investigation revolves around Bluetooth. Currently, we replace
the entire Bluetooth stack, but another option worth investigating is to run the
native Bluetooth stack as-is and just emulate the Bluetooth chip used on the
Pebble. This chip communicates over a serial bus to the STM32F2xx and accepts
low-level HCI (Host Controller Interface) commands.

There is a lot of potential to improve the UI on the QEMU side. Currently, we
show only a bare window with the contents of the Pebble display. It would be a
great improvement for example to show a status area around this window with
clickable buttons. The status area could display helpful debugging information.

There is a lot of potential for enhanced debugging and profiling tools. Imagine
a way to get a trace of the last *N* instructions that were executed before a
crash, or improved ways to profile execution and see where performance can be
improved or power savings realized.

## More Information

Continue reading [*Pebble Emulator 2/2 - JavaScript and CloudPebble*][1] 
for more information on PebbleKit JS emulation and embedding the emulator in
CloudPebble.


[1]: /blog/2015/01/30/Pebble-Emulator-JavaScript-Simulation/
[2]: http://wiki.qemu.org/Main_Page
[3]: http://beckus.github.io/qemu_stm32/
[4]: http://appdevelopermagazine.com/1313/2014/4/14/How-Pebble-Converted-135,070-Customized-Watchfaces-For-Pebble-OS-v2.0/