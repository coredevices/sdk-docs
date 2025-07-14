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

title: Tips and Tricks - Platform-specific C File Set
author: chrislewis
tags: 
   - Beautiful Code
---

In 
[the last Tips and Tricks blog post](/blog/2015/05/13/tips-and-tricks-transparent-images/) 
we looked at drawing transparent images on both the Aplite and Basalt platforms.

This time around, we will look at a `wscript` modification that can allow you to
build a Pebble project when you have two completely separate sets of C source
files; one set for Aplite, and another for Basalt.

Note: This technique can be applied only to local SDK projects, where access to
`wscript` is available. This means that it cannot be used in CloudPebble
projects.



> Update 05/20/15: There was an error in the JS code sample given at the end of
> this post, which has now been corrected.

## The Preprocessor Approach

In the [3.0 Migration Guide](/sdk/migration-guide/#backwards-compatibility) we
recommend using preprocessor directives such as `PBL_PLATFORM_APLITE` and
`PBL_PLATFORM_BASALT` to mark code to be compiled only on that particular
platform. This helps avoid the need to maintain two separate projects for one
app, which is especially convenient when migrating a 2.x app to the Basalt
platform.

```c
#ifdef PBL_PLATFORM_APLITE
  // Aligns under the status bar
  layer_set_frame(s_layer, GRect(0, 0, 144, 68));
#elif PBL_PLATFORM_BASALT
  // Preserve alignment to status bar on Aplite
  layer_set_frame(s_layer, GRect(0, STATUS_BAR_LAYER_HEIGHT, 144, 68));
#endif
```

This is a good solution for small blocks of conditional code, but some
developers may find that complicated conditional code can soon become more
`#ifdef...#elif...#endif` than actual code itself!


## The Modified Wscript Approach

In these situations you may find it preferable to use a different approach.
Instead of modifying your app code to use preprocessor statements whenever a
platform-specific value is needed, you can modify your project's `wscript` file
to limit each compilation pass to a certain folder of source files.

By default, you will probably have a project with this file structure:

```text
my_project
  resources
    images
      banner~bw.png
      banner~color.png
  src
    main.c
    util.h
    util.c
  appinfo.json
  wscript
```

In this scenario, the `wscript` dictates that *any* `.c` files found in `src`
will be compiled for both platforms. 

To use a different set of source files for each platform during compilation,
modify the lines with the `**` wildcard (within the `for` loop) to point to a
folder within `src` where the platform- specific files are then located:

```python
for p in ctx.env.TARGET_PLATFORMS:
    ctx.set_env(ctx.all_envs[p])
    ctx.set_group(ctx.env.PLATFORM_NAME)
    app_elf='{}/pebble-app.elf'.format(ctx.env.BUILD_DIR)
    
    # MODIFY THIS LINE!
    # E.g.: When 'p' == 'aplite', look in 'src/aplite/'
    ctx.pbl_program(source=ctx.path.ant_glob('src/{}/**/*.c'.format(p)), target=app_elf)

    if build_worker:
        worker_elf='{}/pebble-worker.elf'.format(ctx.env.BUILD_DIR)
        binaries.append({'platform': p, 'app_elf': app_elf, 'worker_elf': worker_elf})
        
        # MODIFY THIS LINE!
        # Also modify this line to look for platform-specific C files in `worker_src`
        ctx.pbl_worker(source=ctx.path.ant_glob('worker_src/{}/**/*.c'.format(p)), target=worker_elf)

    else:
        binaries.append({'platform': p, 'app_elf': app_elf})
```

With this newly modified `wscript`, we must re-organise our `src` folder to
match the new search pattern. This allows us to maintain two separate sets of
source files, each free of any excessive `#ifdef` pollution.

```text
my_project
  resources
    images
      banner~bw.png
      banner~color.png
  src
    aplite
      main.c      
      util.h
      util.c
    basalt
      main.c      
      util.h
      util.c
  appinfo.json
  wscript
```


## Sharing Files Between Platforms

Using the modified wscript approach as shown above still requires any files that
are used on both platforms to be included twice: in the respective folder. You
may wish to reduce this clutter by moving any platform-agnostic files that both
platforms use to a `common` folder inside `src`.

You project might now look like this:

```text
my_project
  resources
    images
      banner~bw.png
      banner~color.png
  src
    aplite
      main.c
    basalt
      main.c
    common
      util.h
      util.c
  appinfo.json
  wscript
```

To tell the SDK to look in this extra folder during compilation of each
platform, further modify the two lines calling `ctx.pbl_program()` to include
the `common` folder in the array of paths passed to 
[`ant_glob()`](https://waf.io/book/#_general_usage). This is shown in the code
snipped below, with unchanged lines ommitted for brevity:

```python
# Additionally modified to include the 'common' folder
ctx.pbl_program(source=ctx.path.ant_glob(['src/{}/**/*.c'.format(p), 'src/common/**/*.c']), target=app_elf)

/* Other code */

if build_worker:

    # Also modify this line to look for common files in '/worker_src/common/'
    ctx.pbl_worker(source=ctx.path.ant_glob(['worker_src/{}/**/*.c'.format(p), 'worker_src/common/**/*.c']), target=worker_elf)

else:
    
    /* Other code */

```


## Important Notes

While this new `wscript` allows us to keep our source files for each platform
separated entirely, there are a couple of important limitations to take into
account when using this method (without any further modification):

* There can still be only *one* JavaScript file, in `src/js/pebble-js-app.js`.
  You can simulate two JS files using a platform check:

```js
Pebble.addEventListener('ready', function() {
  if(Pebble.getActiveWatchInfo && Pebble.getActiveWatchInfo().platform === 'basalt') {
    // This is the Basalt platform
    console.log('PebbleKit JS ready on Basalt!');
  } else {
    // This is the Aplite platform
    console.log('PebbleKit JS ready on Aplite!');
  }
});  
```

* Each binary can be bundled with only the app resources required for that
  specific platform. To learn how to package app resources with only a certain
  platform, read the
  [*Platform-specific Resources*](/guides/app-resources/platform-specific/) 
  guide.


## Conclusion

With this modification to a Pebble project's `wscript`, developers now have two
options when it comes to diverging their app code for Aplite- and Basalt-
specific features **without** the need to maintain two completely separate
projects.

You can see a simple example project that ses all these techniques over at 
[`pebble-examples/multi-platform-wscript`]({{site.links.examples_org}}/multi-platform-wscript).
