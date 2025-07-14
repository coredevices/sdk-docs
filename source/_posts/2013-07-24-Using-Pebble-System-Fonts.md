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

author: thomas
tags:
- Beautiful Code
---

_(2014 09: This article was updated to add links for SDK 2.0 users and add the resource identifier of the fonts as suggested by Timothy Gray in the comments.)_

Just like any modern platform, typography is a very important element of Pebble user interface. As Designers and Developers, you have the choice to use one of Pebble system fonts or to embed your own.

Pebble system fonts were chosen for their readability and excellent quality on Pebble black & white display, it's a good idea to know them well before choosing to embed your own.



## Using Pebble system fonts
To use one of the system font, you need to call `fonts_get_system_font()` and pass it the name of a system font. Those are defined in `pebble_fonts.h` in the `include` directory of your project. 

This function returns a `GFont` object that you can use with `text_layer_set_text()` and `graphics_text_draw()`.

For example, in our Hello World example we used the _Roboto Condensed 21_ font:

```c
void handle_init(AppContextRef ctx) {
  window_init(&window, "Window Name");
  window_stack_push(&window, true /* Animated */);

  text_layer_init(&hello_layer, GRect(0, 65, 144, 30));
  text_layer_set_text_alignment(&hello_layer, GTextAlignmentCenter);
  text_layer_set_text(&hello_layer, "Hello World!");
  text_layer_set_font(&hello_layer, fonts_get_system_font(FONT_KEY_ROBOTO_CONDENSED_21));
  layer_add_child(&window.layer, &hello_layer.layer);
}
```

> **Update for SDK 2 users**:
>
> Refer to the [second part of the watchface tutorial](/getting-started/watchface-tutorial/part2/) for updated sample code.

## An illustrated list of Pebble system fonts

{% alert notice %}
A more up-to-date list of fonts can be found by reading {% guide_link app-resources/system-fonts %} 
in the developer guides.
{% endalert %}

To facilitate your choice, here is a series of screenshot of Pebble system fonts used to display digits and some text.

{% comment %}HTML below is acceptable according to Matthew{% endcomment %}

<table class="pebble-screenshots">
  <tr>
    <td>Gothic 14</td>
    <td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/gothic_14_digits.png"></td>
    <td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/gothic_14_abc.png"></td>
  </tr>
  <tr><td>Gothic 14 Bold</td><td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/gothic_14_bold_digits.png"></td>
    <td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/gothic_14_bold_abc.png"></td></tr>
  <tr><td>Gothic 18</td><td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/gothic_18_digits.png"></td>
    <td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/gothic_18_abc.png"></td></tr>
  <tr><td>Gothic 18 Bold</td><td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/gothic_18_bold_digits.png"></td>
    <td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/gothic_18_bold_abc.png"></td></tr>
  <tr><td>Gothic 24</td><td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/gothic_24_digits.png"></td>
    <td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/gothic_24_abc.png"></td></tr>
  <tr><td>Gothic 24 Bold</td><td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/gothic_24_bold_digits.png"></td>
    <td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/gothic_24_bold_abc.png"></td></tr>
  <tr><td>Gothic 28</td><td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/gothic_28_digits.png"></td>
    <td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/gothic_28_abc.png"></td></tr>
  <tr><td>Gothic 28 Bold</td><td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/gothic_28_bold_digits.png"></td>
    <td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/gothic_28_bold_abc.png"></td></tr>
  <tr><td>Bitham 30 Black</td><td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/bitham_30_black_digits.png"></td>
    <td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/bitham_30_black_abc.png"></td></tr>
  <tr><td>Bitham 42 Bold</td><td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/bitham_42_bold_digits.png"></td>
    <td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/bitham_42_bold_abc.png"></td></tr>
  <tr><td>Bitham 42 Light</td><td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/bitham_42_light_digits.png"></td>
    <td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/bitham_42_light_abc.png"></td></tr>
  <tr><td>Bitham 34 Medium Numbers</td><td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/bitham_34_medium_numbers_digits.png"></td>
    <td></td></tr>
  <tr><td>Bitham 42 Medium Numbers</td><td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/bitham_42_medium_numbers_digits.png"></td>
    <td></td></tr>
  <tr><td>Roboto 21 Condensed</td><td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/roboto_21_condensed_digits.png"></td>
    <td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/roboto_21_condensed_abc.png"></td></tr>
  <tr><td>Roboto 49 Bold Subset</td><td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/roboto_49_bold_subset_digits.png"></td>
    <td></td></tr>
  <tr><td>Droid 28 Bold</td><td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/droid_28_bold_digits.png"></td>
    <td><img src="{{ site.asset_path }}/images/blog/pebble-fonts/droid_28_bold_abc.png"></td></tr>
</table>

## A word of caution

To save space on Pebble's memory, some of the system fonts only contain a subset of the default character set:

 * _Roboto 49 Bold Subset_ only contains digits and a colon;
 * _Bitham 34/42 Medium Numbers_ only contain digits and a colon;
 * _Bitham 18/34 Light Subset_ only contains a few characters and you should not use them (this why they are not included in the screenshots).

## Browse the fonts on your watch

To help you decide which font is best, you will probably want to test those fonts directly on a watch.

We have added a new demo application called [`app_font_browser`]({{site.links.examples_org}}/app-font-browser) to the SDK to help you do that. This application uses a ``MenuLayer`` to navigate through the different options and when you have chosen a font, you can use the _Select_ button to cycle through different messages.

![app_font_browser](/images/blog/app_font_browser.png)

You can very easily customize the list of messages for your needs and as an exercise for the reader, you can adapt the app to show custom fonts as well!

This example is available in the `Examples/watchapps/app_font_browser` of the SDK and on [Github]({{site.links.examples_org}}/app-font-browser).
