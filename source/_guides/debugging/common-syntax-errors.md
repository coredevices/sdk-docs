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

title: Common Syntax Errors
description: |
  Details of common problems encountered when writing C apps for Pebble, and how 
  to resolve them.
guide_group: debugging
order: 2
---

If a developer is relatively new to writing Pebble apps (or new to the C
language in general), there may be times when problems with an app's code will
cause compilation errors. Some types of errors with the code itself can be
detected by the compiler and this helps reduce the number that cause problems
when the code is run on Pebble.

These are problems with how app code is written, as opposed to runtime errors
(discussed in {% guide_link debugging/common-runtime-errors %}), which may
include breaking the rules of the C language or bad practices that the compiler
is able to detect and show as an error. The following are some examples.


### Undeclared Variables

This error means that a variable that has been referenced is not available in
the current scope.

```nc|text
../src/main.c: In function 'toggle_logging':
../src/main.c:33:6: error: 'is_now_logging' undeclared (first use in this function)
   if(is_now_logging == true) {
      ^
```

In the above example, the symbol `is_now_logging` has been used in the
`toggle_logging` function, but it was not first declared there. This could be
because the declaring line has been deleted, or it was expected to be available
globally, but isn't. 

To fix this, consider where else the symbol is required. If it is needed in
other functions, move the declaration to a global scope (outside any function).
If it is needed only for this function, declare it before the offending line
(here line `33`).


### Undeclared Functions

Another variant of the above problem can occur when declaring new functions in a
code file. Due to the nature of C compilation, any function a
developer attempts to call must have been previously encountered by the compiler
in order to be visible. This can be done through 
[forward declaration](http://en.wikipedia.org/wiki/Forward_declaration).

For example, the code segment below will not compile:

```c
static void window_load(Window *window) {
  my_function();
}

void my_function() {
  // Some code here

}
```

The compiler will report this with an 'implicit declaration' error, as the app
has implied the function's existence by calling it, even though the compiler has
not seen it previously:

```nc|text
../src/function-visibility.c: In function 'window_load':
../src/function-visibility.c:6:3: error: implicit declaration of function 'my_function' [-Werror=implicit-function-declaration]
   my_function();
   ^
```

This is because the *declaration* of `my_function()` occurs after it is called
in `window_load()`. There are two options to fix this.

* Move the function declaration above any calls to it, so it has been
  encountered by the compiler:

```c
void my_function() {
  // Some code here

}

static void window_load(Window *window) {
  my_function();
}
```

* Declare the function by prototype before it is called, and provide the
  implementation later:

```c
void my_function();

static void window_load(Window *window) {
  my_function();
}

void my_function() {
  // Some code here

}
```


### Too Few Arguments

When creating functions with argument lists, sometimes the requirements of the
function change and the developer forgets to update the places where it is
called.

```nc|text
../src/main.c: In function 'select_click_handler':
../src/main.c:57:3: error: too few arguments to function 'toggle_logging'
   toggle_logging();
   ^
../src/main.c:32:13: note: declared here
 static void toggle_logging(bool will_log) {
             ^
```

The example above reports that the app tried to call the `toggle_logging()`
function in `select_click_handler()` on line 57, but did not supply enough
arguments. The argument list expected in the function definition is shown in the
second part of the output message, which here exists on line 32 and expects an
extra value of type `bool`.

To fix this, establish which version of the function is required, and update
either the calls or the declaration to match.


### Incorrect Callback Implementations

In the Pebble SDK there are many instances where the developer must implement a
function signature required for callbacks, such as for a ``WindowHandlers``
object. This means that when implementing the handler the developer-defined
callback must match the return type and argument list specified in the API
documentation.

For example, the ``WindowHandler`` callback (used for the `load` and `unload`
events in a ``Window``'s lifecycle) has the following signature:

```c
typedef void(* WindowHandler)(struct Window *window)
```

This specifies a return type of `void` and a single argument: a pointer of type
``Window``. Therefore the implemented callback should look like this:

```c
void window_load(Window *window) {
  
}
```

If the developer does not specify the correct return type and argument list in
their callback implementation, the compiler will let them know with an error
like the following, stating that the type of function passed by the developer
does not match that which is expected:

```nc|text
../src/main.c: In function 'init':
../src/main.c:82:5: error: initialization from incompatible pointer type [-Werror]
     .load = main_window_load,
     ^
../src/main.c:82:5: error: (near initialization for '(anonymous).load') [-Werror]
```

To fix this, double check that the implementation provided has the same return
type and argument list as specified in the API documentation.
