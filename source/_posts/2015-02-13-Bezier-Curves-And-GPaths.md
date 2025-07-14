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

title: Bezier Curves and GPaths on Pebble
author: lukasz
tags:
- Beautiful Code
date: 2015-02-13
summary: |
  A look at how to use Bezier curves and GPaths to efficiently draw complex
  paths in your Pebble apps and watchfaces.
banner: /images/blog/bezier-banner.png
---

Drawing complex paths requires a lot of manual work on Pebble. Here I'll show
you how to do this efficiently and quickly using a Pebble-optimized ``GPath``
algorithm and Bezier curves.




## Why Bezier Curves?

Typically, when a developer wants to create curve-based graphics on Pebble he
has to use prepared bitmaps or complex GPaths (or generate paths with 
[svg2gpath](http://gpathsvg.org/)). Both of those approaches have serious 
downsides: bitmaps require resource space to store, memory to process and
rotating bitmaps is a complex operation. Detailed GPaths, while fast in
processing, can take a long time to design without special tools.

Bezier curves are a very interesting solution, which may seem computationally
excessive but solves the obstacles of both the previous methods. Because they're
so simple to use they are common elements in many graphic systems, primarly
vector based graphics.

## Drawing Bezier Curves

The mathematical formula for a Bezier curve can be found on
[Wikipedia](http://en.wikipedia.org/wiki/Composite_B%C3%A9zier_curve). We can 
fairly easily turn it into C code, but we have to make a couple of important
decisions. The formula itself is linear and requires us to decide how many steps
we want to take in order to draw our Bezier curve. It's safe to assume that
calculating 1000 points on our Bezier curve should be enough to display a
continuous line on the small Pebbles screen.

```c
void naive_bezier(GContext *ctx, GPoint points[]) {
  for (double t = 0.0; t<1.0; t += 0.001) {
    double tx = pow_d(1-t, 3) * points[0].x + 3 * t * pow_d(1-t, 2) * points[1].x +
                  3 * pow_d(t, 2) * (1-t) * points[3].x + pow_d (t, 3) * points[2].x;
    double ty = pow_d(1-t, 3) * points[0].y + 3 * t * pow_d(1-t, 2) * points[1].y +
                  3 * pow_d(t, 2) * (1-t) * points[3].y + pow_d(t, 3) * points[2].y;

    graphics_draw_pixel(ctx, GPoint(tx, ty));
  }
}
```
    
**Notes:**

* `pow_d(double a, int b)` is simply a function which returns `b` to the power
  of `a`.

* `points` contains array of 4 points used as parameters for drawing the Bezier
  curve.

While this approach gives us precise results its also very computationally
expensive. Most of the work done by the CPU is redundant as most of those points
overlap each other due to the low screen resolution.

## Optimizing for Pebble

The simplest optimization would be reducing the number of steps and drawing
lines between computed points. While this will significantly reduce calculation
time, it will also make the curve less precise and pleasing to the eye. But what
if we could dynamically calculate the number of segments needed to create
perfectly smooth curve? Here's a method published by Maxim Shermanev which you
can find out more about on his website:
[www.antigrain.com](http://www.antigrain.com/research/adaptive_bezier/index.html).

Below you can see code from his research adapted to work efficiently on the
Pebble architecture:

```c
void recursive_bezier_fixed(int x1, int y1, 
                            int x2, int y2, 
                            int x3, int y3, 
                            int x4, int y4){
  // Calculate all the mid-points of the line segments
  int x12   = (x1 + x2) / 2;
  int y12   = (y1 + y2) / 2;
  int x23   = (x2 + x3) / 2;
  int y23   = (y2 + y3) / 2;
  int x34   = (x3 + x4) / 2;
  int y34   = (y3 + y4) / 2;
  int x123  = (x12 + x23) / 2;
  int y123  = (y12 + y23) / 2;
  int x234  = (x23 + x34) / 2;
  int y234  = (y23 + y34) / 2;
  int x1234 = (x123 + x234) / 2;
  int y1234 = (y123 + y234) / 2;
  
  // Angle Condition
  int32_t a23 = atan2_lookup((y3 - y2) / fixedpoint_base, (x3 - x2) / fixedpoint_base);
  int32_t da1 = abs(a23 - atan2_lookup((y2 - y1) / fixedpoint_base, (x2 - x1) / fixedpoint_base));
  int32_t da2 = abs(atan2_lookup((y4 - y3) / fixedpoint_base, (x4 - x3) / fixedpoint_base) - a23);
  if(da1 >= TRIG_MAX_ANGLE) da1 = TRIG_MAX_ANGLE - da1;
  if(da2 >= TRIG_MAX_ANGLE) da2 = TRIG_MAX_ANGLE - da2;

  if(da1 + da2 < m_angle_tolerance)
  {
    // Finally we can stop the recursion
    add_point(x1234 / fixedpoint_base, y1234 / fixedpoint_base);
    return;
  }

  // Continue subdivision
  recursive_bezier_fixed(x1, y1, x12, y12, x123, y123, x1234, y1234); 
  recursive_bezier_fixed(x1234, y1234, x234, y234, x34, y34, x4, y4); 
}

bool bezier_fixed(GPathBuilder *builder, GPoint p1, GPoint p2, GPoint p3, GPoint p4) {
  // Translate points to fixedpoint realms
  int32_t x1 = p1.x * fixedpoint_base;
  int32_t x2 = p2.x * fixedpoint_base;
  int32_t x3 = p3.x * fixedpoint_base;
  int32_t x4 = p4.x * fixedpoint_base;
  int32_t y1 = p1.y * fixedpoint_base;
  int32_t y2 = p2.y * fixedpoint_base;
  int32_t y3 = p3.y * fixedpoint_base;
  int32_t y4 = p4.y * fixedpoint_base;

  if (recursive_bezier_fixed(builder, x1, y1, x2, y2, x3, y3, x4, y4)) {
    return gpath_builder_line_to_point(builder, p4);
  }
  return false;
}
```
    
**Notes:**

* This code uses fixedpoint integers since the Pebble CPU doesn't support
  floating point operations. You can find more about that in a talk given by
  Matthew Hungerford during 2014 Pebble Developer Retreat (video available
  [here](https://www.youtube.com/watch?v=8tOhdUXcSkw)).

* To determine the angle, the algorithm calculates parameters of the curve at
  given points. This implementation is very effective since Pebble's
  `atan2_lookup` is just looking up that value in a precomputed table.

* `m_angle_tolerance` is the angle of the curve we're looking for, expressed in
  degrees. In our case it's 10 degrees: `int32_t m_angle_tolerance =
  (TRIG_MAX_ANGLE / 360) * 10;`

## Applying Code to GPath

In order to make it easy for developers, we have prepared the GPathBuilder
library which will ease the process of creating GPaths out of a few Bezier
curves and/or lines. The resulting path can already be manipulated with the 
[existing APIs](/docs/c/group___path_drawing.html#ga1ba79344b9a34432a44af09bed8b00fd). You can find it on the
[pebble-hacks Github page](https://github.com/pebble-hacks/gpath-bezier) along 
with a simple demo app.

Usage is extremely simple. Here are the main functions in the API:

 - `GPathBuilder* gpath_builder_create(uint32_t max_points)` will create the
   GPathBuilder object you will need to use in order to create a GPath with
   Bezier curves. `max_points` sets the limit on number of points created in the
   process.
 - `void gpath_builder_destroy(GPathBuilder *builder)` will destroy the
   GPathBuilder object and free the memory it used.
 - `bool gpath_builder_line_to_point(GPathBuilder *builder, GPoint to_point)`
   will create a straight line from last point to the given point.
 - `bool gpath_builder_curve_to_point(GPathBuilder *builder, GPoint to_point,
   GPoint control_point_1, GPoint control_point_2)` will create a Bezier curve
   from the last point to a given point (`to_point`), `control_point_1` and
   `control_point_2` are used as parameters for the Bezier curve for last point
   and given point respectively.
 - `GPath* gpath_builder_create_path(GPathBuilder *builder)` will return a GPath
   object ready to be used in your graphic routine. Remember that the
   GPathBuilder is not being destroyed in the process and you have to do that
   manually.

Below is shown a simple shape involving two curves and the code required to
create the path:

![result >{pebble-screenshot,pebble-screenshot--steel-black}](/images/blog/bezier-result.png)

```c
// Create GPathBuilder object
GPathBuilder *builder = gpath_builder_create(MAX_POINTS);

// Move to the starting point of the GPath
gpath_builder_move_to_point(builder, GPoint(0, -60));
// Create curve
gpath_builder_curve_to_point(builder, GPoint(60, 0), GPoint(35, -60), GPoint(60, -35));
// Create straight line
gpath_builder_line_to_point(builder, GPoint(-60, 0));
// Create another curve
gpath_builder_curve_to_point(builder, GPoint(0, 60), GPoint(-60, 35), GPoint(-35, 60));
// Create another straight line
gpath_builder_line_to_point(builder, GPoint(0, -60));

// Create GPath object out of our GPathBuilder object
s_path = gpath_builder_create_path(builder);
// Destroy GPathBuilder object
gpath_builder_destroy(builder);

// Get window bounds
GRect bounds = layer_get_bounds(window_get_root_layer(window));
// Move newly created GPath to the center of the screen
gpath_move_to(s_path, GPoint((int16_t)(bounds.size.w/2), (int16_t)(bounds.size.h/2)));
```

And there you have it, complex GPaths built with a few lines of code.

## Conclusion

This library should make it easier to create amazing graphics on Pebble and can
be used in animations as it's lightweight and fast. Bear in mind that the
GPathBuilder temporarily uses RAM proportinal to `max_points` until
`gpath_builder_destroy` is called. You can find the example app and library code 
on the [pebble-hacks Github page](https://github.com/pebble-hacks/gpath-bezier).

We are also looking forward to this technology being used in online tools such
as [SVG to Pebble GPath Converter](http://gpathsvg.org/) by awesome Pebble
developer [Rajendra Serber](https://github.com/ardnejar).
