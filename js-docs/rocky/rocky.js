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
 * @namespace rocky
 *
 * @desc Provides an interface for interacting with application context and
 *    events. Developers can access the Rocky object with the following line of
 *    code:
 *
 *    `var rocky = require('rocky');`
 *
 */
var rocky = {
  /**
   * @typedef {Object} WatchInfo
   * @desc Provides information about the currently connected Pebble smartwatch.
   *
   * @property {String} model - The name of the Pebble model. (e.g. pebble_time_round_silver_20mm)
   * @property {String} platform - The name of the Pebble platform. (e.g. basalt)
   * @property {String} language - Not available yet.
   * @property {String} firmware - An object with the following fields:
   *   * `major` - The major version of the smartwatch's firmware.
   *   * `minor` - The minor version of the smartwatch's firmware.
   *   * `patch` - The patch version of the smartwatch's firmware.
   *   * `suffix` - The suffix of the smartwatch's firmware. (e.g. beta3)
  */

  /**
   * @typedef {Object} UserPreferences
   * @desc Provides access to user related settings from the currently connected Pebble smartwatch. 
   *       The size itself will vary between platforms, see the 
   *       {@link /guides/user-interfaces/content-size/ ContentSize guide} for more information.
   *
   * @property {String} contentSize - Pebble > System > Notifications > Text Size:
   *   * `small` - Not available on Emery.
   *   * `medium` - The default setting.
   *   * `large` - The default setting on Emery.
   *   * `x-large` - Only available on Emery.
  */

  /**
   * @typedef {Function} RockyDrawCallback
   * @desc The callback function signature to be used with the draw {@link #on event}.
   *
   * @param {Object} event - An object containing information about the event:
   *   * `context` - A {@link /docs/rockyjs/CanvasRenderingContext2D CanvasRenderingContext2D}
   *       object that can be used to draw information on the disply.
  */

  /**
   * @typedef {Function} RockyTickCallback
   * @desc The callback function signature to be used with the `secondchange`,
   *   `minutechange`, `hourchange` and `daychange` {@link #on events}.
   *
   * In addition to firing these tick events at the appropriate time change, 
   *  they are also emitted when the application starts.
   *
   * @param {Object} event - An object containing information about the event:
   *   * `date` - A JavaScript
   *      {@link http://www.w3schools.com/jsref/jsref_obj_date.asp date} object
   *      representing the current time.
   */

  /**
   * @typedef {Function} RockyMessageCallback
   * @desc The callback function signature to be used with the `message`
   *    {@link #on event}.
   *
   * @param {Object} event - An object containing information about the event:
   *   * `type` - The type of event which was triggered.
   *   * `data` - The data sent within the message.
   */

  /**
   * @typedef {Function} RockyPostMessageErrorCallback
   * @desc The callback function signature to be used with the `postmessageerror`
   *    {@link #on event}.
   *
   * @param {Object} event - An object containing information about the event:
   *   * `type` - The type of event which was triggered.
   *   * `data` - The data failed to send within the message.
   */

  /**
   * @typedef {Function} RockyPostMessageConnectedCallback
   * @desc The callback function signature to be used with the `postmessageconnected`
   *    {@link #on event}.
   *
   * @param {Object} event - An object containing information about the event:
   *   * `type` - The type of event which was triggered.
   */

  /**
   * @typedef {Function} RockyPostMessageDisconnectedCallback
   * @desc The callback function signature to be used with the `postmessagedisconnected`
   *    {@link #on event}.
   *
   * @param {Object} event - An object containing information about the event:
   *   * `type` - The type of event which was triggered.
   */

  /**
   * @typedef {Function} RockyMemoryPressureCallback
   * @desc The callback function signature to be used with the `memorypressure`
   *    {@link #on event}.
   *
   * @param {Object} event - An object containing information about the event:
   *  * `level` (String) - The current level of memory pressure.
   *
   *     * `high` - This is a critical level, indicating that the application will 
   *       be terminated if memory isn't immediately free'd.
   *
   *       Important Notes:
   *       - Avoid creating any new objects/arrays/strings when this level is raised.
   *       - Drop object properties you don't need using the `delete` operator or by assigning `undefined` to it.
   *       - Don't use the `in` operator in the handler for large objects/arrays. Avoid `for (var x in y)` due to memory constraints.
   *       - Array has large memory requirements for certain operations/methods. Avoid `Array.pop()`, `Array.slice` and length assignment `Array.length = 123`, on large arrays.
   *
   *     * `normal` - Not yet implemented.
   *
   *     * `low` - Not yet implemented.
   */

  /**
   * @desc A {@link #WatchInfo WatchInfo} object containing information about the
   *   connected Pebble smartwatch.
   *
   * `console.log(rocky.watchInfo.model);<br>&gt; pebble_2_hr_lime`
   *
  */
  watchInfo,

  /**
   * @desc A {@link #UserPreferences UserPreferences} object access to user related settings from the currently connected Pebble smartwatch.
   *
   * `console.log(rocky.userPreferences.contentSize);<br>&gt; medium`
   *
  */
  userPreferences
};

/**
 * @desc Attaches an event handler to the specified events. You may subscribe
 *     with multiple handlers, but at present there is no way to unsubscribe.
 *
 *  `rocky.on('minutechange', function() {...});`
 *
 *   #### Event Type Options
 *
 *   Possible values:
 *
 *   * `draw` - Provide a {@link #RockyDrawCallback RockyDrawCallback} as the
 *       callback. The draw event is being emitted after each call to
 *       {@link #requestDraw requestDraw} but at most once for each screen update,
 *       even if {@link #requestDraw requestDraw} is called frequently the 'draw'
 *       event might also fire at other meaningful times (e.g. upon launch).
 *   * `secondchange` - Provide a {@link #RockyTickCallback RockyTickCallback} as the
 *       callback. The secondchange event is emitted every time the clock's second changes.
 *   * `minutechange` - Provide a {@link #RockyTickCallback RockyTickCallback} as the
 *       callback. The minutechange event is emitted every time the clock's minute changes.
 *   * `hourchange` - Provide a {@link #RockyTickCallback RockyTickCallback} as the
 *       callback. The hourchange event is emitted every time the clock's hour changes.
 *   * `daychange` - Provide a {@link #RockyTickCallback RockyTickCallback} as the
 *       callback. The daychange event is emitted every time the clock's day changes.
 *   * `memorypressure` - Provides a {@link #RockyMemoryPressureCallback RockyMemoryPressureCallback}. The
 *       event is emitted every time there is a notable change in available system memory.
 *       You can see an example implementation of memory pressure handling {@link https://github.com/pebble-examples/rocky-memorypressure here}.
 *   * `message` - Provide a {@link #RockyMessageCallback RockyMessageCallback}
 *       as the callback. The message event is emitted every time the application
 *       receives a {@link #postMessage postMessage} from the mobile companion.
 *   * `postmessageconnected` - Provide a {@link #RockyPostMessageConnectedCallback RockyPostMessageConnectedCallback}
 *       as the callback. The event may be emitted immediately upon subscription, 
 *       if the subsystem is already connected. It is also emitted when connectivity is established.
 *   * `postmessagedisconnected` - Provide a {@link #RockyPostMessageDisconnectedCallback RockyPostMessageDisconnectedCallback}
 *       as the callback. The event may be emitted immediately upon subscription, 
 *       if the subsystem is already disconnected. It is also emitted when connectivity is lost.
 *   * `postmessageerror` - Provide a {@link #RockyPostMessageErrorCallback RockyPostMessageErrorCallback}
 *       as the callback. The event is emitted when a transmission error occurrs. The type 
 *       of error is not provided, but the message has not been delivered.
 *
 * @param {String} type - The event being subscribed to.
 * @param {Function} callback - A callback function that will be executed when
 *   the event occurs. See below for more details.
 *
 */
rocky.on = function(type, callback) { };

/**
 * @desc Attaches an event handler to the specified events. Synonymous with 
 *       [rocky.on()](#on).
 *
 * `rocky.addEventListener(type, callback);`
 *
 * @param {String} type - The event being subscribed to.
 * @param {Function} callback - A callback function that will be executed when 
 *   the event occurs. See below for more details.
 */
rocky.addEventListener = function(type, callback) { };

/**
 * @desc Remove an existing event listener previously registered with 
 *   [rocky.on()](#on) or [rocky.addEventListener()](#addEventListener).
 *
 * @param {String} type - The type of the event listener to be removed. See 
 *   [rocky.on()](#on) for a list of available event types.
 * @param {Function} callback - The existing developer-defined function that was 
 *   previously registered.
 */
rocky.removeEventListener = function(type, callback) { };

/**
 * @desc Remove an existing event handler from the specified events. Synonymous 
 *        with [rocky.removeEventListener()](#removeEventListener).
 *
 * `rocky.off(type, callback);`
 *
 * @param {String} type - The type of the event listener to be removed. See 
 *   [rocky.on()](#on) for a list of available event types.
 * @param {Function} callback - The existing developer-defined function that was 
 *   previously registered.
 */
rocky.off = function(type, callback) { };

/**
 * @desc Sends a message to the mobile companion component. Please be aware 
 *    that messages should be kept concise. Each message is queued, so 
 *    `postMessage()` can be called multiple times immediately. If there is a momentary loss of connectivity, queued 
 *    messages may still be delivered, or automatically removed from the queue 
 *    after a few seconds of failed connectivity. Any transmission failures, or 
 *    out of memory errors will be raised via the `postmessageerror` event.
 *
 * `rocky.postMessage({cmd: 'fetch'});`
 *
 * @param {Object} data - An object containing the data to deliver to the mobile
 *         device. This will be received in the `data` field of the `event`
 *         delivered to the `on('message', ...)` handler.
 */
rocky.postMessage = function(data) { };

/**
 * @desc Flags the canvas (display) as requiring a redraw. Invoking this method
 *    will cause the {@link #on draw event} to be emitted. Only 1 draw event
 *    will occur, regardless of how many times the redraw is requested before
 *    the next draw event.
 *
 * `rocky.on('secondchange', function(e) {<br>&nbsp;&nbsp;rocky.requestDraw();<br>});`
 */
rocky.requestDraw = function() { };
