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

title: Pebble SDK Tutorial (Part 1)
author: Chris Lewis
excerpt: |
  This is the first in a series of articles that will hopefully help newcomers
  and seasoned programmers alike begin to flex their creative muscles and make
  their own Pebble watchapps. If you prefer a more visual approach, Thomas has
  made videos you can watch to help you get started.
---

##Your First Watchapp

###Introduction

This is the first in a series of articles that will hopefully help newcomers and
seasoned programmers alike begin to flex their creative muscles and make their
own Pebble watchapps. If you prefer a more visual approach, Thomas has made
videos you can watch
[here](https://www.youtube.com/channel/UCFnawAsyEiux7oPWvGPJCJQ) to help you get
started.

Firstly, make sure you are familiar with the following basic C language
concepts. Pebble has [Developer Guides](/guides/) that may help:

- Variables and variable scope (local or global?)
- Functions (definitions and calls)
- Structures
- Pointers
- Program flow (if, else etc.)
- Preprocessor statements (`#define`, `#include` etc.)

Up to speed? Good! Let's create our first watchapp.



###Development Environment
The easiest way to get started is to use [CloudPebble]({{site.links.cloudpebble}})
, a free online IDE for Pebble. This approach requires no installations to start
making watchapps. Advanced users can install the SDK on Linux, OS X or Windows
(via VM such as [VirtualBox](https://www.virtualbox.org/)) for a more hands-on
approach. Instructions for installing the native SDK can be found on the
[Pebble Developer site](/sdk/install/linux/)
. For this tutorial, we will be using CloudPebble.

###First Steps
To get started, log into [CloudPebble]({{site.links.cloudpebble}}) and choose
'Create Project'.

1. Enter a suitable name for the project such as 'My First App'.
2. Set the project type to 'Pebble C SDK'.
3. Set the template as 'Empty project'.
4. Confirm with 'Create'.

To start entering code, choose 'New C file' on the left hand pane. C language
source files typically have the extension '.c'. A suggested standard name is
`main.c`, although this can be anything you like.

###Setting Up the Basics
The power behind the C language comes from its ability to be adapted for many
different devices and platforms, such as the Pebble watch, through the use of
SDKs such as this one. Therefore, to be able to use all the features the Pebble
SDK has to offer us, we must include it at the start of the file by using the
`#include` preprocessor statement (meaning it is processed before the rest of
the code):

```c
#include <pebble.h>
```

All C applications begin with a call to a function called `main()` by the host
operating system, also known as the ‘entry point’ of the program. This must
contain ``app_event_loop()``, and by convention also contains two other
functions to manage the start and end of the watchapp's life:

- `init()` - Used to create (or initialize) our app.
- ``app_event_loop()`` - Handles all events that happen from the start of the
  app to the end of its life.
- `deinit()` - Used to clean up after ourselves and make sure any memory we use
  is free for apps that are run after us.

Following these rules, our first function, `main()` looks like this:

```c
int main(void)
{
  init();
  app_event_loop();
  deinit();
}
```

All functions we call must be defined before they are used so that they are
known to the compiler when the first call is encountered. To this end we will
define our `init()` and `deinit()` functions before they are called in `main()`
by placing them after the `#include` preprocessor statement and before the
definition of `main()` itself. The resulting code file now looks like this:

```c
#include <pebble.h>

void init()
{
  //Create app elements here
}

void deinit()
{
  //Destroy app elements here
}

int main(void)
{
  init();
  app_event_loop();
  deinit();
}
```

###Using the SDK
With the boilerplate app structure done, let's begin using the Pebble C SDK to
create our first watchapp. The first element we will use is the ``Window``. We
will declare our first instance of a ``Window`` outside the scope of any
function in what is known as a 'global variable', before it is first used. The
reason for this is for us to be able to use this reference from any location
within the program. By convention, a global variable's name is prefixed with
`g_` to make it easily identifiable as such. An ideal place for these
declarations is below the preprocessor statements in the source file.

Declare a pointer to a ``Window`` structure to be created later like so:

```c
Window *g_window;
```

At the moment, this pointer does not point anywhere and is unusable. The next
step is to use the ``window_create()`` function to construct a ``Window``
element for the pointer to point to. Once this is done, we also register two
references to the `window_load()` and `window_unload()` functions (known as
handlers) which will manage the creation and destruction of the elements within
that window. This is shown below:

```c
void init()
{
  //Create the app elements here!
  g_window = window_create();
  window_set_window_handlers(g_window, (WindowHandlers) {
    .load = window_load,
    .unload = window_unload,
  });
}
```

The next logical step is to define what we mean by `window_load()` and
`window_unload()`. In a similar fashion to `init()` and `deinit()`, these must
be defined before they are first used; above `init()`, but below the definition
of `g_window` at the top of the file. Think of them as the `init()` and
`deinit()` equivalent functions for the ``Window``:

```c
void window_load(Window *window)
{
  //We will add the creation of the Window's elements here soon!
}

void window_unload(Window *window)
{
  //We will safely destroy the Window's elements here!
}
```

This modular approach to app creation allows a developer to create apps with all
relevant sub-elements managed within the life of that particular ``Window``.
This process is shown visually in the diagram below:

![Lifecycle](/images/blog/tut_1_lifecycle.png "Lifecycle")

As a responsible app developer, it is a good practice to free up any memory we
use to the system when our app is closed. Pebble SDK elements use functions
suffixed with `_destroy` for this purpose, which can be done for our ``Window``
element in `deinit()`:

```c
void deinit()
{
  //We will safely destroy the Window's elements here!
  window_destroy(g_window);
}
```

The final step in this process is to make the app actually appear when it is
chosen from the Pebble menu. To do this we push our window to the top of the
window stack using ``window_stack_push()``, placing it in the foreground in
front of the user. This is done after the ``Window`` is created, and so we will
place this call at the end of `init()`:

```c
window_stack_push(g_window, true);
```

The second argument denotes whether we want the push to be animated. This looks
cool, so we use `true`! The app will now launch, but will be completely blank.
Let's rectify that.

###Displaying Content
So far we have created and pushed an empty ``Window`` element. So far so good.
Now let's add our first sub-element to make it show some text. Introducing the
``TextLayer``! This is an element used to show any standard string of characters
in a pre-defined area, called a 'frame'. As with any element in the SDK, we
begin with a global pointer to a structure-to-be of that type:

```c
TextLayer *g_text_layer;
```

The rest of the process of using the ``TextLayer`` is very similar to that of
the ``Window``. This is by design, and means it is easy to tell which functions
to use as they are named in a 'plain English' style. Creating the ``TextLayer``
will be done within the `window_load()` function, as it will be shown within the
parent ``Window`` (here called `g_window`).

The functions we call to perform this setup are almost self-explanatory, but I
will go through them after the following segment. Can you spot the pattern in
the SDK function names?

```c
g_text_layer = text_layer_create(GRect(0, 0, 144, 168));
text_layer_set_background_color(g_text_layer, GColorClear);
text_layer_set_text_color(g_text_layer, GColorBlack);

layer_add_child(window_get_root_layer(window), text_layer_get_layer(g_text_layer));
```

Now the explanation:

1. ``text_layer_create()`` - This creates the ``TextLayer`` and sets its frame
   to that in the ``GRect`` supplied as its only argument to x = 0, y = 0, width
   = 144 pixels and height = 168 pixels (this is the size of the entire screen).
   Just like ``window_create()``, this function returns a pointer to the newly
   created ``TextLayer``
2. ``text_layer_set_background_color()`` - This also does what it says: sets the
   ``TextLayer``'s background color to ``GColorClear``, which is transparent.
3. ``text_layer_set_text_color()`` - Similar to the last function, but sets the
   text color to ``GColorBlack``.
4. ``layer_add_child()`` - This is used to add the ``TextLayer``'s "root"
   ``Layer`` (which is the part drawn to the screen) as a 'child' of the
   ``Window``'s root layer. Simply put, all child ``Layer``s are drawn in front
   of their 'parents' and allows us to control layering of ``Layer``s and in
   which order they are drawn.

As should always be the case, we must add the required destruction function
calls to free up the memory we used in creating the ``TextLayer``. This is done
in the parent ``Window``'s `window_unload()` function, which now looks like
this:

```c
void window_unload(Window *window)
{
  //We will safely destroy the Window's elements here!
  text_layer_destroy(g_text_layer);
}
```

Now for what we have been working towards all this time - making the app show
any text we want! After creating the ``TextLayer``, add a call to
``text_layer_set_text()`` to set the text it should display, such as the example
below:

```c
text_layer_set_text(g_text_layer, "Anything you want, as long as it is in quotes!");
```

Now you should be ready to see the fruits of your labor on your wrist! To do
this we must compile our C source code into a `.pbw` package file that the
Pebble app will install for us.

###Compilation and Installation

To do this, make sure you save your C file. Then go to the 'Compilation' screen
in the left pane and click 'Run build'. After the compiler returns 'Succeeded',
you can use either of the following options to install the app on your Pebble:

- Ensure you have enabled the
  [Pebble Developer Connection](/guides/tools-and-resources/developer-connection/)
  and enter the IP address shown into the 'Phone IP' box. Click 'Install and
  Run' to install your app.
- Use the 'Get PBW' button in your phone's browser to install via the Pebble app.

If your code does not compile, compare it to the
[sample code](https://gist.github.com/C-D-Lewis/a911f0b053260f209390) to see
where you might have made an error. Once this is successful, you should see
something similar to the screenshot below:

![Screenshot](/images/blog/tut_1_preview.png "Screenshot")

###Conclusions
There you have it, a *very* simple watchapp to show some text of your choosing.
This was done by:

1. Setting up boilerplate app structure.
2. Creating a ``Window`` with a child layer, in this case the ``TextLayer``.
3. Creating a ``TextLayer`` to show text on the screen.

By adding more types of layers such as ``BitmapLayer`` and `InverterLayer` we
create much more sophisticated apps. By extension with ``AppMessage``s and
``Clicks`` we can begin to respond to user data and input. All this and more to
come in future instalments!

###Source Code
The full source code file we have built up over the course of this article can
be found [here](https://gist.github.com/C-D-Lewis/a911f0b053260f209390) and
directly imported into CloudPebble
[as a new project](https://cloudpebble.net/ide/gist/a911f0b053260f209390). If
your code doesn't compile, have a look at this and see where you may have gone
wrong.

Best of luck, and let me know what you come up with! Send any feedback or
questions to [@PebbleDev](http://twitter.com/PebbleDev) or
[@Chris_DL](http://twitter.com/Chris_DL).
