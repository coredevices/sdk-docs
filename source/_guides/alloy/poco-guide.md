---
# Copyright 2025 Core Devices LLC
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

title: Poco Graphics
description: |
  Low-level graphics rendering with the Poco framework.
guide_group: alloy
order: 3
---

Poco is a low-level graphics rendering framework that gives you direct control
over pixel drawing. It's ideal for custom graphics, games, and watchfaces
where you need precise control over rendering.

> **Note**: All code in this guide runs on the watch in `src/embeddedjs/main.js`.

## Getting Started

Import Poco and create a renderer instance:

```javascript
import Poco from "commodetto/Poco";

const render = new Poco(screen);
```

The `screen` global provides access to the Pebble display.

## Basic Drawing

All drawing happens between `begin()` and `end()` calls:

```javascript
render.begin();
    // Drawing commands here
render.end();
```

You can also specify a clip region to update only part of the screen:

```javascript
render.begin(x, y, width, height);
    // Only draws within the specified rectangle
render.end();
```

## Colors

Create colors using `makeColor()` with RGB values (0-255):

```javascript
const black = render.makeColor(0, 0, 0);
const white = render.makeColor(255, 255, 255);
const red = render.makeColor(255, 0, 0);
const gray = render.makeColor(128, 128, 128);
const lightBlue = render.makeColor(0x80, 0xc0, 0xff);
```

## Drawing Shapes

### Rectangles

```javascript
// Filled rectangle
render.fillRectangle(color, x, y, width, height);

// Example: fill the entire screen white
render.fillRectangle(white, 0, 0, render.width, render.height);
```

### Rounded Rectangles

```javascript
// Rounded rectangle with radius
// corners is a bitmask: 0b0001=TL, 0b0010=TR, 0b0100=BL, 0b1000=BR
render.drawRoundRect(x, y, width, height, color, radius, corners);

// All corners rounded
render.drawRoundRect(10, 10, 100, 50, black, 8);

// Only top corners rounded
render.drawRoundRect(10, 10, 100, 50, black, 8, 0b0011);

// Frame (outline) of rounded rectangle
render.frameRoundRect(x, y, width, height, color, radius);
```

### Lines

```javascript
// Draw a line with specified thickness
render.drawLine(x1, y1, x2, y2, color, thickness);

// Example: diagonal lines
render.drawLine(0, 0, render.width, render.height, gray, 4);
render.drawLine(0, render.height, render.width, 0, gray, 4);
```

### Circles

```javascript
// Draw a circle or arc
// startAngle and endAngle are in degrees
render.drawCircle(color, centerX, centerY, radius, startAngle, endAngle);

// Full circle
render.drawCircle(black, 90, 90, 30, 0, 360);

// Arc (quarter circle)
render.drawCircle(blue, 90, 90, 30, 0, 90);
```

## Text Rendering

### Using Pebble Built-in Fonts

```javascript
import Poco from "commodetto/Poco";

const render = new Poco(screen);
const font = new render.Font("Bitham-Black", 30);
const black = render.makeColor(0, 0, 0);

render.begin();
    render.drawText("Hello!", font, black, 10, 50);
render.end();
```

Available Pebble fonts:
- `Gothic-Regular` (various sizes)
- `Gothic-Bold`
- `Bitham-Black`
- `Bitham-Bold`
- `Roboto-Condensed`
- `Leco-Regular`
- `Droid-Serif`

The available sizes are limited for each font family. See the
[System Fonts](/guides/app-resources/system-fonts/) reference for the full table
of all fonts, styles, and sizes.

### Centering Text

Use `getTextWidth()` to measure text for centering:

```javascript
const msg = "Hello!";
const width = render.getTextWidth(msg, font);
const x = (render.width - width) / 2;
const y = (render.height - font.height) / 2;

render.drawText(msg, font, black, x, y);
```

### Using Custom Fonts (Moddable SDK Fonts)

For custom fonts bundled with your app, use `parseBMF` and `parseRLE`:

```javascript
import Poco from "commodetto/Poco";
import parseBMF from "commodetto/parseBMF";
import parseRLE from "commodetto/parseRLE";

const render = new Poco(screen);
const black = render.makeColor(0, 0, 0);

// Load custom font from resources
function getFont(name, size) {
    const font = parseBMF(new Resource(`${name}-${size}.fnt`));
    font.bitmap = parseRLE(new Resource(`${name}-${size}-alpha.bm4`));
    return font;
}

const openSans = getFont("OpenSans-Regular", 21);
const noto = getFont("NotoSansJP-Regular", 24);

render.begin();
    render.drawText("Hello!", openSans, black, 10, 10);
    render.drawText("新宿出口", noto, black, 10, 40);  // Japanese text
render.end();
```

Custom fonts allow Unicode support and unique typography not available in
built-in Pebble fonts.

## Drawing Images

### Bitmaps

Load bitmaps from resources using `PebbleBitmap`:

```javascript
import Poco from "commodetto/Poco";

const render = new Poco(screen);

// Load bitmap by resource ID
const bitmap = new Poco.PebbleBitmap(2);

render.begin();
    // Center the bitmap
    const x = (render.width - bitmap.width) / 2;
    const y = (render.height - bitmap.height) / 2;
    render.drawBitmap(bitmap, x, y);
render.end();
```

Bitmaps have `width` and `height` properties for positioning.

### PDC (Pebble Draw Command) Images

PDC images are vector graphics converted from SVG:

```javascript
import Poco from "commodetto/Poco";

const render = new Poco(screen);

// Load PDC image by resource ID
const pdc = new Poco.PebbleDrawCommandImage(2);

render.begin();
    // Center the PDC image
    const x = (render.width - pdc.width) / 2;
    const y = (render.height - pdc.height) / 2;
    render.drawDCI(pdc, x, y);
render.end();
```

### PDC Sequences (Animations)

PDC sequences are animated vector graphics. Use the `time` property to advance
through frames:

```javascript
import Poco from "commodetto/Poco";

const render = new Poco(screen);
const gray = render.makeColor(128, 128, 128);

const dcs = new Poco.PebbleDrawCommandSequence(2);
console.log("Sequence dimensions: " + dcs.width + " x " + dcs.height);
console.log("Sequence duration: " + dcs.duration + " ms");

function draw() {
    render.begin();
        render.fillRectangle(gray, 0, 0, render.width, render.height);
        render.drawDCI(dcs,
            (render.width - dcs.width) / 2,
            (render.height - dcs.height) / 2);
    render.end();

    // Advance to next frame
    const frameDuration = dcs.frameDuration;
    dcs.time += frameDuration;
    setTimeout(draw, frameDuration);
}
draw();
```

PDC sequences have these properties:

- `width`, `height` - Dimensions of the sequence
- `duration` - Total animation duration in milliseconds
- `frameDuration` - Duration of current frame
- `time` - Current playback position (set this to advance)

## Animation

Use `setInterval()` for frame-based animations. The interval is a request - if
Pebble OS can't render fast enough, the actual frame rate will be lower.
Smoothest results come from requesting a frame rate that can be consistently
achieved:

```javascript
import Poco from "commodetto/Poco";

const render = new Poco(screen);
const white = render.makeColor(255, 255, 255);
const black = render.makeColor(0, 0, 0);

let x = 0;

setInterval(() => {
    render.begin();
        // Clear screen
        render.fillRectangle(white, 0, 0, render.width, render.height);
        // Draw moving circle
        render.drawCircle(black, x, 90, 20, 0, 360);
    render.end();

    x = (x + 2) % render.width;
}, 50);  // ~20 fps
```

### Rotating PDC Images

PDC images can be transformed. Use `clone()` and `rotate()` for rotation:

```javascript
import Poco from "commodetto/Poco";

const render = new Poco(screen);
const gray = render.makeColor(128, 128, 128);

const dci = new Poco.PebbleDrawCommandImage(2);
console.log("PDC dimensions: " + dci.width + " x " + dci.height);

let angle = 0;
setInterval(() => {
    render.begin();
        render.fillRectangle(gray, 0, 0, render.width, render.height);
        // Clone, rotate around center, then draw
        render.drawDCI(
            dci.clone().rotate(angle, dci.width / 2, dci.height / 2),
            (render.width - dci.width) / 2,
            (render.height - dci.height) / 2
        );
        angle += Math.PI / 30;
    render.end();
}, 50);  // ~20fps
```

The `rotate()` method takes angle in radians and pivot point coordinates.

### Scaling PDC Images

PDC images can also be scaled dynamically:

```javascript
import Poco from "commodetto/Poco";

const render = new Poco(screen);
const gray = render.makeColor(128, 128, 128);

const dci = new Poco.PebbleDrawCommandImage(2);
console.log("PDC size: " + dci.width + " x " + dci.height);

const start = Date.now();

setInterval(() => {
    // Animate scale with elastic easing
    const progress = ((Date.now() - start) % 1500) / 1500;
    const scale = Math.elasticEaseOut(progress);

    // Center the scaled image
    const cx = (render.width - dci.width * scale) / 2;
    const cy = (render.height - dci.height * scale) / 2;

    render.begin();
        render.fillRectangle(gray, 0, 0, render.width, render.height);
        render.drawDCI(dci.clone().scale(scale), cx, cy);
    render.end();
}, 50);
```

The `scale()` method takes a scale factor (1.0 = original size).

### PDC Transformation Methods

| Method | Description |
|--------|-------------|
| `clone()` | Create a copy for transformation |
| `rotate(angle, pivotX, pivotY)` | Rotate by angle (radians) around pivot |
| `scale(factor)` | Scale uniformly by factor |

Always call `clone()` before transforming to preserve the original.

## Complete Example: Animated Display

```javascript
import Poco from "commodetto/Poco";

console.log("Starting animation demo");

const render = new Poco(screen);

const black = render.makeColor(0, 0, 0);
const white = render.makeColor(255, 255, 255);
const gray = render.makeColor(128, 128, 128);

let angle = 0;

setInterval(() => {
    render.begin(0, 0, render.width, render.height);
        // Background
        render.fillRectangle(white, 0, 0, render.width, render.height);

        // Diagonal lines
        render.drawLine(0, 0, render.width, render.height, gray, 4);
        render.drawLine(0, render.height, render.width, 0, gray, 4);

        // Rounded rectangle frame
        const margin = 30;
        render.drawRoundRect(
            margin, margin,
            render.width - (margin * 2),
            render.height - (margin * 2),
            black, 8
        );

        // Rotating arc
        const cx = render.width / 2;
        const cy = render.height / 2;
        render.drawCircle(gray, cx, cy, 15, angle, angle + 270);
    render.end();

    angle = (angle + 10) % 360;
}, 50);
```

## Screen Properties

The `render` object provides useful screen information:

| Property | Description |
|----------|-------------|
| `render.width` | Screen width in pixels |
| `render.height` | Screen height in pixels |

## Performance Tips

1. **Minimize draw area**: Use `begin(x, y, w, h)` to only redraw changed
   regions
2. **Batch drawing**: Do all drawing between a single `begin()`/`end()` pair
3. **Reuse colors**: Create colors once and store them in variables
4. **Preload fonts**: Create font objects once at startup
5. **Use PDC for complex graphics**: Vector graphics scale better and use
   less memory than bitmaps

## Poco vs Piu

| Feature | Poco | Piu |
|---------|------|-----|
| Approach | Procedural | Declarative |
| Control | Low-level, pixel-perfect | High-level, automatic layout |
| Best for | Games, watchfaces, custom graphics | Apps with standard UI patterns |
| Learning curve | Simpler concepts | More abstraction to learn |
| Performance | More control over optimization | Framework handles optimization |

Use Poco when you need precise control over every pixel. Use Piu when you
want automatic layout and a component-based architecture.

## Examples

The [Pebble Examples](https://github.com/Moddable-OpenSource/pebble-examples)
repository includes several Poco examples:

- [`hellopoco-gbitmap`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-gbitmap) - rendering Pebble GBitmap bitmaps
- [`hellopoco-text`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-text) - text rendering with Moddable SDK fonts
- [`hellopoco-pebbletext`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-pebbletext) - text rendering with Pebble's built-in fonts
- [`hellopoco-pebblegraphics`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-pebblegraphics) - lines, rounded rectangles, and circles
- [`hellopoco-pdc`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-pdc) - rendering PDC (Draw Command) SVG images
- [`hellopoco-pdc-rotate`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-pdc-rotate) - rotating a PDC image
- [`hellopoco-pdc-scale`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-pdc-scale) - scaling a PDC image with easing
- [`hellopoco-pdc-sequence`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-pdc-sequence) - animated PDC image sequences
