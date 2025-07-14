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

title: Multiple JavaScript Files
author: katharine
tags:
- Freshly Baked
---

In SDK 3.9 we will introduce a new feature to the Pebble SDK: the ability to
cleanly use multiple JavaScript files in the PebbleKit JS app portion of
your project.


<strike>SDK 3.9 is available now in beta! Check out our
[beta instructions](/sdk/download/#testing-beta-sdks) to try it out.</strike>

**EDIT:** SDK 3.9 is now [publicly available](/sdk/) - to update your SDK, run: ```pebble sdk install latest```

# How do I use this?

First, if you are using the native SDK, you must make sure you have
`"enableMultiJS": true` in your appinfo.json file. This defaults to false if
omitted, but will be set to `true` in all projects created using SDK 3.9+ and
Pebble Tool 4.1+. If you are using CloudPebble, ensure that "JS Handling" is
set to "CommonJS-style" in your project's settings page.

Having enabled it, PebbleKit JS now expects to have an "entry point" at
`src/pkjs/index.js`. This is the code we will run when your app starts, and is
equivalent to the native SDK's old `src/js/pebble-js-app.js`. Aside from a
slightly less redundant name, the effective behavior is exactly the same as
before.

However, you can now add additional javascript files! These files will not be
executed automatically. Instead, you can pull them in to your code using the
`require` function, which returns a reference to the imported file.

Since `require` returns something, there needs to be some way to provide
something that it can usefully return. To do this, add properties to
`module.exports` in the file to be required. For instance:

**adder.js**

```js
function addThings(a, b) {
  return a + b;
}

module.exports.addThings = addThings;
```

**index.js**

```js
var adder = require('./adder');
console.log("2 plus 2 is " + adder.addThings(2, 2));
```

Running the app with this JavaScript would look like this:

```nc|text
katharine@scootaloo ~> pebble install --emulator basalt --logs
Installing app...
App install succeeded.
[17:39:40] javascript> 2 plus 2 is 4
```

That's about all there is to it: we handle this all transparently.

# But…!?

### …how do I migrate my existing project?

If you use the native SDK and your existing project has only one JavaScript
file, just move it from `src/js/pebble-js-app.js` to `src/pkjs/index.js` and add
`"enableMultiJS": true` to your appinfo.json file. Easy!

If you use CloudPebble and have multiple JavaScript files, you first change
"JS Handling" to "CommonJS-style" in your project's Settings page. If you don't
have a JavaScript file called "index.js", but you do have some others, it will
prompt you to rename a file. If you previously used multiple JavaScript files
on CloudPebble, you will now need to make code changes. In particular,
you will have to modify your code so that there is a single, clearly-defined
entry point (`index.js`) and the other files use the module export system
described above.

That said, there is no need to do this now: the existing system will continue to
work for the forseeable future.

### …will this work for users who haven't updated their mobile apps?

Yes! This all happens entirely at build time; no updates to the user's phone
software are required. Since it is part of SDK 3.9, they will need to be running
firmware 3.9, as usual.

### …I use Pebble.js. What does this mean for me?

Nothing! Pebble.js already does something very similar to this, and it will
continue to do so. No changes are needed.

### …I built something like this myself. Do I have to use this?

No! If you want to keep using your own custom system, you can set
`enableMultiJS` to false or omit it entirely, and nothing will change. The
system is strictly opt-in, and won't break anything you were doing if you
leave it as-is.

### …I don't want my main JavaScript file to be called "index.js"

We recommend that you use the default name for portability reasons. In
particular, CloudPebble will _require_ that you use this name, and will fail
to build a non-compliant project. However, if you would really like to change
it, you can pass an alternate path as `js_entry_file` to `pbl_bundle` in your
wscript file.

