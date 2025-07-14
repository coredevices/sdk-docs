/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
* @namespace CanvasRenderingContext2D
* @desc The CanvasRenderingContext2D interface is used for drawing
*  rectangles, text, images and other objects onto the canvas element. It
*  provides the 2D rendering context for the drawing on the device's display.
*
* The canvas uses a standard x and y 
*  {@link https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial/Drawing_shapes coordinate system}. 
*
* The `CanvasRenderingContext2D` object is obtained as a parameter in the
*  {@link /docs/rockyjs/rocky#on rocky.on('draw', ...)} event.
*
* `rocky.on('draw', function(drawEvent) {<br>&nbsp;&nbsp;var ctx = drawEvent.context;<br>});`
*
* The state of pixels is maintained between each draw, so developers are 
*  responsible for clearing an area, before drawing again. 
*
* Please note that this API is still in development and there may be some 
*  limitations, which are documented below. We will also be adding support 
*  for more common APIs in future releases.
*/
var CanvasRenderingContext2D = {
  /**
   * @typedef {Object} TextMetrics
   * @desc The TextMetrics interface represents the dimensions of a text
   *     in the canvas (display), as created by {@link #measureText measureText}.
   *
   * @property {Number} width - Calculated width of text in pixels.
   * @property {Number} height - Calculated height of text in pixels.
   */

  /**
   * @typedef {Object} Canvas
   * @desc Provides information about the device's canvas (display). This is not
   *  actually a DOM element, it is provided for standards compliance only. 
   *
   * `rocky.on('draw', function(drawEvent) {<br>&nbsp;&nbsp;var ctx = drawEvent.context;<br>&nbsp;&nbsp;var h = ctx.canvas.unobstructedHeight;<br>});`
   *
   * @property {Number} clientWidth - The full width of the canvas.
   * @property {Number} clientHeight - The full height of the canvas.
   * @property {Number} unobstructedWidth - The width of the canvas that is not
   *     obstructed by system overlays (Timeline Quick View).
   * @property {Number} unobstructedHeight - The height of the canvas that is
   *     not obstructed by system overlays (Timeline Quick View).
   */

  /**
  * @desc Specifies the color to use inside shapes. The default is
  *  `#000` (black).
  *
  *   #### Options
  *
  *   Possible values:
  *
  *   * Most (but not all) CSS color names. e.g. `blanchedalmond`
  *   * Pebble color names. e.g. `shockingpink`
  *   * Hex color codes, short and long. e.g. `#FFFFFF` or `#FFF`
  *
  * Please note that we currently only support solid colors. You may specifiy
  *  `transparent` or `clear` for transparency, but we do do not support 
  *  partial transparency or the `#RRGGBBAA` notation yet.
  *
  * `ctx.fillStyle = 'white';`
  *
  */
  fillStyle,

  /**
  * @desc Specifies the color to use for lines around shapes. The
  *  default is `#000` (black).
  *
  *   #### Options
  *
  *   Possible values:
  *
  *   * Most (but not all) CSS color names. e.g. `blanchedalmond`
  *   * Pebble color names. e.g. `shockingpink`
  *   * Hex color codes, short and long. e.g. `#FFFFFF` or `#FFF`
  *
  * Please note that we currently only support solid colors. You may specifiy
  *  `transparent` or `clear` for transparency, but we do do not support 
  *  partial transparency or the `#RRGGBBAA` notation yet.
  *
  * `ctx.strokeStyle = 'red';`
  *
  */
  strokeStyle,

  /**
  * @desc A {@link #Canvas Canvas} object containing information about
  *   the system's canvas (display).
  */
  canvas,

  /**
  * @desc The width of lines drawn (to the nearest integer) with the
  *  context (`1.0` by default).
  *
  * `ctx.lineWidth = 8;`
  *
  */
  lineWidth,

  /**
  * @desc Specifies the current text style being used when drawing text.
  *   Although this string uses the same syntax as a CSS font specifier, you 
  *  cannot specifiy arbitrary values and you must only use one of the values below.
  *
  *  The default font is `14px bold Gothic`.
  *
  * `ctx.font = '28px bold Droid-serif';`
  *
  *   #### Options
  *
  *   Possible values:
  *
  *   * `18px bold Gothic`
  *   * `14px Gothic`
  *   * `14px bold Gothic`
  *   * `18px Gothic`
  *   * `24px Gothic`
  *   * `24px bold Gothic`
  *   * `28px Gothic`
  *   * `28px bold Gothic`
  *   * `30px bolder Bitham`
  *   * `42px bold Bitham`
  *   * `42px light Bitham`
  *   * `42px Bitham-numeric`
  *   * `34px Bitham-numeric`
  *   * `21px Roboto`
  *   * `49px Roboto-subset`
  *   * `28px bold Droid-serif`
  *   * `20px bold Leco-numbers`
  *   * `26px bold Leco-numbers-am-pm`
  *   * `32px bold numbers Leco-numbers`
  *   * `36px bold numbers Leco-numbers`
  *   * `38px bold numbers Leco-numbers`
  *   * `42px bold numbers Leco-numbers`
  *   * `28px light numbers Leco-numbers`
  */
  font,

  /**
  * @desc Specifies the current text alignment being used when drawing
  *   text. Beware that the alignment is based on the x-axis coordinate value of 
  *   the {@link #fillText CanvasRenderingContext2D.fillText} method.
  *
  * `ctx.textAlign = 'center';`
  *
  *   #### Options
  *
  *   Possible values:
  *
  *   * `left` - The text is left-aligned
  *   * `right` - The text is right-aligned
  *   * `center` - The text is center-aligned
  *   * `start` (default) - The text is aligned left, unless using a 
  *       right-to-left language. Currently only left-to-right is supported.
  *   * `end` - The text is aligned right, unless using a right-to-left 
  *      language. Currently only left-to-right is supported.
  */
  textAlign
};

/**
* @desc Sets all pixels in the rectangle at (`x`,`y`) with size
*  (`width`, `height`) to black, erasing any previously drawn content.
*
* `ctx.clearRect(0, 0, 144, 168);`
*
* @param {Number} x - The x-axis coordinate of the rectangle's starting point
* @param {Number} y - The y-axis coordinate of the rectangle's starting point
* @param {Number} width - The rectangle's width
* @param {Number} height - The rectangle's height
*/
CanvasRenderingContext2D.clearRect = function(x, y, width, height) { };

/**
* @desc Draws a filled rectangle at (`x`,`y`) with size (`width`, `height`), 
*  using the current fill style.
*
* `ctx.fillRect(0, 30, 144, 30);`
*
* @param {Number} x - The x-axis coordinate of the rectangle's starting point
* @param {Number} y - The y-axis coordinate of the rectangle's starting point
* @param {Number} width - The rectangle's width
* @param {Number} height - The rectangle's height
*/
CanvasRenderingContext2D.fillRect = function(x, y, width, height) { };

/**
* @desc Paints a rectangle at (`x`,`y`) with size (`width`, `height`),
*  using the current stroke style.
*
* `ctx.strokeRect(0, 30, 144, 30);`
*
* @param {Number} x - The x-axis coordinate of the rectangle's starting point
* @param {Number} y - The y-axis coordinate of the rectangle's starting point
* @param {Number} width - The rectangle's width
* @param {Number} height - The rectangle's height
*/
CanvasRenderingContext2D.strokeRect = function(x, y, width, height) { };

/**
* @desc Draws (fills) `text` at the given (`x`,`y`) position.
*
* `ctx.fillText('Hello World', 0, 30, 144);`
*
* @param {String} text - The text to draw
* @param {Number} x - The x-axis coordinate of the text's starting point
* @param {Number} y - The y-axis coordinate of the text's starting point
* @param {Number} maxWidth - (Optional) Maximum width to draw. If specified, 
*    and the string is wider than the width, the font is adjusted to use a 
*    smaller font.
*/
CanvasRenderingContext2D.fillText = function(text, x, y, maxWidth) { };

/**
* @desc Returns a {@link #TextMetrics TextMetrics} object containing
*     information about `text`.
*
* `var dimensions = ctx.measureText('Hello World');`
*
* @returns {TextMetrics} - A ``TextMetrics`` object with information about
*  the measured text
*
* @param {String} text - The text to measure
*/
CanvasRenderingContext2D.measureText = function(text) { };

/**
* @desc Starts a new path by emptying the list of sub-paths. Call this
*  method when you want to create a new path.
*
* `ctx.beginPath();`
*/
CanvasRenderingContext2D.beginPath = function() { };

/**
* @desc Causes the point of the pen to move back to the start of the
*     current sub-path. It tries to add a straight line (but does not
*     actually draw it) from the current point to the start. If the shape has
*     already been closed or has only one point, this function does nothing.
*
* `ctx.closePath();`
*/
CanvasRenderingContext2D.closePath = function() { };

/**
* @desc Moves the starting point of a new sub-path to the (`x`,`y`)
*  coordinates.
*
* `ctx.moveTo(10, 20);`
*
* @param {Number} x - The destination point on the x-axis
* @param {Number} y - The destination point on the y-axis
*/
CanvasRenderingContext2D.moveTo = function(x, y) { };

/**
* @desc Connects the last point of the sub-path to the (`x`,`y`)
*  coordinates with a straight line.
*
* `ctx.lineTo(10, 20);`
*
* @param {Number} x - The destination point on the x-axis
* @param {Number} y - The destination point on the y-axis
*/
CanvasRenderingContext2D.lineTo = function(x, y) { };

/**
* @desc Adds an arc to the path which is centered at (`x`,`y`)
*     position with radius `r` starting at `startAngle` and ending at
*     `endAngle` going in the direction determined by the `anticlockwise` 
*     parameter (defaulting to clockwise).
*
* If `startAngle` > `endAngle` nothing will be drawn, and if the difference 
*   between `startAngle` and `endAngle` exceeds 2π, a full circle will be drawn.
*
* `// Draw a full circle outline<br>ctx.strokeStyle = 'white';<br>ctx.beginPath();<br>ctx.arc(72, 84, 40, 0, 2 * Math.PI, false);<br>ctx.stroke();`
*
* Please note this function does not work with `.fill`, you must use 
*  {@link #rockyFillRadial CanvasRenderingContext2D.rockyFillRadial} instead.
*
* @param {Number} x - The x-axis coordinate of the arc's center
* @param {Number} y - The y-axis coordinate of the arc's center
* @param {Number} r - The radius of the arc
* @param {Number} startAngle - The angle at which the arc starts, measured
*     clockwise from the positive x axis and expressed in radians.
* @param {Number} endAngle - The angle at which the arc ends, measured
*     clockwise from the positive x axis and expressed in radians.
* @param {Bool} [anticlockwise] - (Optional) `Boolean` which, if `true`,
*     causes the arc to be drawn counter-clockwise between the two angles
*     (`false` by default)
*/
CanvasRenderingContext2D.arc = function(x, y, r, startAngle, endAngle, anticlockwise) { };

/**
* @desc Creates a path for a rectangle at position (`x`,`y`) with a
*     size that is determined by `width` and `height`. Those four points are
*     connected by straight lines and the sub-path is marked as closed, so
*     that you can fill or stroke this rectangle.
* 
* `ctx.rect(0, 30, 144, 50);`
*
* @param {Number} x - The x-axis coordinate of the rectangle's starting point
* @param {Number} y - The y-axis coordinate of the rectangle's starting point
* @param {Number} width - The rectangle's width
* @param {Number} height - The rectangle's height
*/
CanvasRenderingContext2D.rect = function(x, y, width, height) { };

/**
* @desc Fills the current path with the current {@link #fillStyle fillStyle}.
*
* `ctx.fill();`
*/
CanvasRenderingContext2D.fill = function() { };

/**
* @desc Strokes the current path with the current {@link #strokeStyle strokeStyle}.
*
* `ctx.stroke();`
*/
CanvasRenderingContext2D.stroke = function() { };

/**
* @desc Saves the entire state of the canvas by pushing the current
*   state onto a stack.
*
* `ctx.save();`
*/
CanvasRenderingContext2D.save = function() { };

/**
* @desc Restores the most recently saved canvas state by popping the
*   top entry in the drawing state stack. If there is no saved state, this
*   method does nothing.
*
* `ctx.restore();`
*/
CanvasRenderingContext2D.restore = function() { };

/**
* @desc Fills a circle clockwise between startAngle and endAngle where
*    0 is the start of the circle beginning at the 3 o'clock position on a
*    watchface.
*
*   If `startAngle` > `endAngle` nothing will be drawn, and if the difference
*    between `startAngle` and `endAngle` exceeds 2π, a full circle will be drawn.
*
* `// Draw a filled circle<br>ctx.fillStyle = 'white';<br>ctx.rockyFillRadial(72, 84, 0, 30, 0, 2 * Math.PI);`
*
* @param {Number} x - The x-axis coordinate of the radial's center point
* @param {Number} y - The y-axis coordinate of the radial's center point
* @param {Number} innerRadius - The inner radius of the circle. Use 0 for a full circle
* @param {Number} outerRadius - The outer radius of the circle
* @param {Number} startAngle - Radial starting angle
* @param {Number} endAngle - Radial finishing angle. If smaller than `startAngle` nothing is drawn
*/
CanvasRenderingContext2D.rockyFillRadial = function(x, y, innerRadius, outerRadius, startAngle, endAngle) { };
