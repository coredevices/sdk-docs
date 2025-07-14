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

title: Hardware Specification
description: |
  Details of how to build smartstrap hardware, including 3D printing
  instructions and electrical characteristics.
guide_group: smartstraps
order: 0
---

This page describes how to make smartstrap hardware and how to interface it with
the watch.

The smartstrap connector has four contacts: two for ground, one for power and a
one-wire serial bus. The power pin is bi-directional and can be used to power
the accessory, or for the strap to charge the watch. The amount of power that
can be drawn **must not exceed** 20mA, and will of course impact the battery
life of Pebble Time.

[Download 3D models of Pebble Time and the DIY Smartstrap >{center,bg-lightblue,fg-white}](https://github.com/pebble/pebble-3d/tree/master/Pebble%20Time)

> Note: Due to movement of the user the contacts of the DIY Smartstrap may come
> undone from time to time. This should be taken into account when designing
> around the accessory and its protocol.


## Electronic Characteristics

The table below summarizes the characteristics of the accessory port connection
on the back of Pebble Time.

| Characteristic | Value |
|----------------|-------|
| Pin layout (watch face down, left to right) | Ground, data, power in/out, ground. |
| Type of data connection | Single wire, open drain serial connection with external pull-up required. |
| Data voltage level | 1.8V input logic level with tolerance for up to 5V. |
| Baud rate | Configurable between 9600 and 460800 bps. |
| Output voltage (power pin) | 3.3V (+/- 10%) |
| Maximum output current draw (power pin) | 20mA |
| Minimum charging voltage (power pin) | 5V (+/- 5%) |
| Maximum charging current draw | 500mA |


## Battery Smartstraps and Chargers

If a smartstrap is designed to charge a Pebble smartwatch, simply apply +5V to
the power pin and make sure that it can provide up to 500mA of current. This is
the maximum power draw of Pebble Time when the screen is on, the battery
charging, the radios are on, etc.


## Accessories Drawing Power

If the accessory is drawing power from the watch it will need to include a
pull-up resistor (10kΩ is recommended) so that the watch can detect that a
smartstrap is connected.

By default, the smartstrap port is turned off. The app will need to turn on the
smartstrap port to actually receive power. Refer to ``smartstrap_subscribe()``.


## Example Circuits

### Single-component Data Interface

The simplest interface to the smartstrap connector is just a pull-up resistor
between the power and the data pin of the watch. This pull-up is required so
that the watch can detect that something is connected. By default the data bus
will be at +3.3V and the watch or the smartstrap can force the bus to 0V when
sending data.

> This is the general principle of an open-drain or open-collector bus. Refer to
> an [electronic reference](https://en.wikipedia.org/wiki/Open_collector) for
> more information.

![software-serial](/images/guides/hardware/software-serial.png =500x)

On the smartstrap side, choose to use one or two pins of the chosen 
micro-controller:

* If using only one pin, the smartstrap will most likely have to implement the
  serial communication in software because most micro-controllers expect
  separated TX and RX pins. This is demonstrated in the
  [ArduinoPebbleSerial](https://github.com/pebble/arduinopebbleserial) project
  when running in 'software serial' mode.

* If using two pins, simply connect the data line to both the TX and RX pins.
  The designer should make sure that the TX pin is in high-impedance mode when
  not talking on the bus and that the serial receiver is not active when sending
  (otherwise it will receive everything sent). This is demonstrated in the
  [ArduinoPebbleSerial](https://github.com/pebble/arduinopebbleserial) project
  when running in the 'hardware serial' mode.


### Transistor-based Buffers

When connecting the smartstrap to a micro-controller where the above options are
not possible then a little bit of hardware can be used to separate the TX and RX
signals and emulate a standard serial connection.

![buffer](/images/guides/hardware/buffer.png =500x)


### A More Professional Interface

Finally, for production ready smartstraps it is recommended to use a more robust
setup that will provide voltage level conversion as well as protect the
smartstraps port from over-voltage.

The diagram below shows a suggested circuit for interfacing the smartstrap
connector (right) to a traditional two-wire serial connection (left) using a
[SN74LVC1G07](http://www.ti.com/product/sn74lvc1g07) voltage level converter as
an interface with Zener diodes for
[ESD](http://en.wikipedia.org/wiki/Electrostatic_discharge) protection.

![strap-adapter](/images/more/strap-adapter.png)


## Smartstrap Connectors

Two possible approaches are suggested below, but there are many more potential
ways to create smartstrap connectors. The easiest way involves modifying a
Pebble Time charging cable, which provides a solid magnetized connection at the
cost of wearability. By contrast, 3D printing a connector is a more comfortable
approach, but requires a high-precision 3D printer and additional construction
materials.


### Hack a Charging Cable

The first suggested method to create a smartstrap connector for prototyping
hardware is to adapt a Pebble Time charging cable using common hardware hacking
tools, such as a knife, soldering iron and jumper cables. The end result is a
component that snaps securely to the back of Pebble Time, and connects securely
to common male-to-female prototyping wires, such as those sold with Arduino
kits.

First, cut off the remainder of the cable below the end containing the magnets.
Next, use a saw or drill to split the malleable outer casing.

![](/images/guides/hardware/cable-step1.jpg =450x)

Pull the inner clear plastic part of the cable out of the outer casing, severing
the wires.

![](/images/guides/hardware/cable-step2.jpg =450x)

Use the flat blade of a screwdriver to separate the clear plastic from the front
plate containing the magnets and pogo pins.

![](/images/guides/hardware/cable-step3.jpg =450x)

Using a soldering iron, remove the flex wire attached to the inner pogo pins.
Ensure that there is no common electrical connection between any two contacts.
In its original state, the two inner pins are connected, and **must** be
separated.

Next, connect a row of three headers to the two middle pins, and one of the
magnets.

> Note: Each contact may require tinning in order to make a solid electrical
> connection.

![](/images/guides/hardware/cable-step4.jpg =450x)

The newly created connector can now be securely attached to the back of Pebble
Time.

![](/images/guides/hardware/cable-step5.jpg =450x)

With the connector in place, the accessory port pins may be easily interfaced
with using male-to-female wires.

![](/images/guides/hardware/cable-step6.jpg =450x)


### 3D Printed Connector

An alternate method of creating a compatible connector is to 3D print a
connector component and add the electrical connectivity using some additional
components listed below. To make a 3D printed smartstrap connector the following
components will be required:

![components](/images/more/strap-components.png =400x)

* 1x Silicone strap or similar, trimmed to size (See
  [*Construction*](#construction)).

* 1x Quick-release style pin or similar
  ([Amazon listing](http://www.amazon.com/1-8mm-Release-Spring-Cylindrical-Button/dp/B00Q7XE866)).

* 1x 3D printed adapter
  ([STP file](https://github.com/pebble/pebble-3d/blob/master/Pebble%20Time/Smartstrap-CAD.stp)).

* 4x Spring loaded pogo pins
  ([Mill-Max listing](https://www.mill-max.com/products/pin/0965)).

* 4x Lengths of no.24 AWG copper wire.


#### Construction

For the 3D printed adapter, it is highly recommended that the part is created
using a relatively high resolution 3D printer (100-200 microns), such as a 
[Form 1](http://formlabs.com/products/form-1-plus/) printer. Alternatively there 
are plenty of websites that 3D print parts, such as
[Shapeways](http://www.shapeways.com/). Make sure to use a **non-conductive**
material such as ABS, and print a few copies, just to be safe.

(A lower resolution printer like a Makerbot may not produce the same results.
The 3D part depends on many fine details to work properly).

For the strap, it is recommend to use a silicone strap (such as the one included
with Pebble Time or a white Pebble Classic), and cut it down. Put the strap
along the left and right side of the lug holes, as shown below.

> Ensure the strap is cut after receiving the 3D printed part so that it can be
> used as a reference.

![cutaway](/images/more/strap-measurements.png =300x)


#### Assembly

Slide the quick-release pin into the customized silicone strap.

![strap-insert-pin](/images/more/strap-insert-pin.png =300x)

Slide the strap and pin into the 3D printed adapter.

![strap-into-adapter](/images/more/strap-into-adapter.png =300x)

Insert the copper wire pieces into the back of the 3D printed adapter.

![strap-insert-wires](/images/more/strap-insert-wires.png =300x)

Place the pogo pins into their respective holes, then slide them into place away
from the strap.

![strap-insert-pogo-pins](/images/more/strap-insert-pogo-pins.png =300x)
