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
 * @namespace Pebble
 *
 * @desc The Pebble namespace is where all of the Pebble specific methods and 
 * properties exist. This class contains methods belonging to PebbleKit JS and 
 * allows bi-directional communication with a C or JavaScript watchapp, as well as managing 
 * the user's timeline subscriptions, creating AppGlance slices and obtaining 
 * information about the currently connected watch.
 */
var Pebble = new Object;


/**
 * @desc Adds a listener for PebbleKit JS events, such as when an ``AppMessage`` is
 *     received or the configuration view is opened or closed.
 *
 *   #### Event Type Options
 *
 *   Possible values:
 *
 *   * `ready` - The watchapp has been launched and the PebbleKit JS component 
 *     is now ready to receive events.
 *   * `appmessage` - The watch sent an ``AppMessage`` to PebbleKit JS. The 
 *     AppMessage ``Dictionary`` is contained in the payload property (i.e: 
 *     `event.payload`). The payload consists of key-value pairs, where the keys 
 *     are strings containing integers (e.g: "0"), or aliases for keys defined 
 *     in package.json (e.g: "KEY_EXAMPLE"). Values should be integers, strings 
 *     or byte arrays (arrays of characters). This event is not available to 
 *     {@link /docs/rockyjs/ Rocky.js} applications, and attempting to register it will throw an exception.
 *   * `showConfiguration` - The user has requested the app's configuration 
 *     webview to be displayed. This can occur either upon the app's initial 
 *     install or when the user taps 'Settings' in the 'My Pebble' view within 
 *     the phone app.
 *   * `webviewclosed` - The configuration webview was closed by the user. If 
 *     the webview had a response, it will be contained in the response property 
 *     (i.e: `event.response`). This response can be used to feed back user 
 *     preferences to the watchapp.
 *   * `message` - Provide a {@link #PostMessageCallback PostMessageCallback} 
 *     as the callback. The message event is emitted every time PebbleKit JS 
 *     receives a {@link #postMessage postMessage} from the {@link /docs/rockyjs/ Rocky.js}  
 *      application. The payload contains a simple JavaScript object. (i.e. `event.data`). 
 *     This event type can only be used with {@link /docs/rockyjs/ Rocky.js} applications.
 *   * `postmessageconnected` - Provide a {@link #PostMessageConnectedCallback PostMessageConnectedCallback} 
 *     as the callback. The event may be emitted immediately upon subscription, 
 *     if the subsystem is already connected. It is also emitted when connectivity is established. 
 *     This event type can only be used with {@link /docs/rockyjs/ Rocky.js} applications.
 *   * `postmessagedisconnected` - Provide a {@link #PostMessageDisconnectedCallback PostMessageDisconnectedCallback} 
 *     as the callback. The event may be emitted immediately upon subscription, 
 *     if the subsystem is already disconnected. It is also emitted when connectivity is lost. 
 *     This event type can only be used with {@link /docs/rockyjs/ Rocky.js} applications.
 *   * `postmessageerror` - Provide a {@link #PostMessageErrorCallback PostMessageErrorCallback} 
 *     as the callback. The event is emitted when a transmission error occurrs. 
 *     Your message has not been delivered. The type of error is not provided. 
 *     This event type can only be used with {@link /docs/rockyjs/ Rocky.js} applications.
 *
 * @param {String} type - The type of the event, from the list described above.
 * @param {EventCallback} callback - The developer defined {@link #EventCallback EventCallback} 
 *   to receive any events of the type specified that occur.
*/
Pebble.addEventListener = function(type, callback) { };

/**
 * @desc Attaches an event handler to the specified events. Synonymous with 
        [Pebble.addEventListener()](#addEventListener). Only applicable to 
        {@link /docs/rockyjs/ Rocky.js} applications.
 *
 * `Pebble.on(type, callback);`
 *
 * @param {String} type - The type of the event, from the list described above.
 * @param {EventCallback} callback - The developer defined {@link #EventCallback EventCallback}
 *   to receive any events of the type specified that occur.
 */
Pebble.on = function(type, callback) { };

/**
 * @desc Remove an existing event listener previously registered with 
 *   [Pebble.addEventListener()](#addEventListener) or [Pebble.on()](#on).
 *
 * @param {String} type - The type of the event listener to be removed. See 
 *   [Pebble.addEventListener()](#addEventListener) for a list of available event types.
 * @param {Function} callback - The existing developer-defined function that was 
 *   previously registered.
 */
Pebble.removeEventListener = function(type, callback) { };

/**
 * @desc Remove an existing event handler from the specified events. Synonymous 
 *        with [Pebble.removeEventListener()](#removeEventListener). Only applicable to 
 *       {@link /docs/rockyjs/ Rocky.js} applications.
 *
 * `Pebble.off(type, callback);`
 *
 * @param {String} type - The type of the event listener to be removed. See 
 *   [Pebble.addEventListener()](#addEventListener) for a list of available types.
 * @param {Function} callback - The existing developer-defined function that was 
 *   previously registered.
 */
Pebble.off = function(type, callback) { };

/**
 * @desc Show a simple modal notification on the connected watch.
 *
 * @param {String} title - The title of the notification
 * @param {String} body - The main content of the notification
 */
Pebble.showSimpleNotificationOnPebble = function(title, body) { };

/**
 * @desc Send an AppMessage to the app running on the watch. Messages should be 
 *     in the form of JSON objects containing key-value pairs. See 
 *     Pebble.sendAppMessage() for valid key and value data types. 
 *     `Pebble.sendAppMessage = function(data, onSuccess, onFailure) { };` 
 *     Please note that `sendAppMessage` is `undefined` in 
 *     {@link /docs/rockyjs/ Rocky.js} applications, see {@link #postMessage postMessage} instead.
 *
 * @returns {Number} The transaction id for this message
 *
 * @param {Object} data - A JSON object containing key-value pairs to send to 
 *     the watch. Values in arrays that are greater then 255 will be mod 255 
 *     before sending.
 * @param {AppMessageAckCallback} onSuccess - A developer-defined {@link #AppMessageAckCallback AppMessageAckCallback} 
 *     callback to run if the watch acknowledges (ACK) this message.
 * @param {AppMessageOnFailure} onFailure - A developer-defined {@link #AppMessageNackCallback AppMessageNackCallback} 
 *     callback to run if the watch does NOT acknowledge (NACK) this message.
 */
Pebble.sendAppMessage = function(data, onSuccess, onFailure) { };

/**
 * @desc Sends a message to the {@link /docs/rockyjs/ Rocky.js} component. Please be aware 
 *    that messages should be kept concise. Each message is queued, so 
 *    `postMessage()` can be called multiple times immediately. If there is a momentary loss of connectivity, queued 
 *    messages may still be delivered, or automatically removed from the queue 
 *    after a few seconds of failed connectivity. Any transmission failures, or 
 *    out of memory errors will be raised via the `postmessageerror` event.
 *
 * `Pebble.postMessage({temperature: 30, conditions: 'Sunny'});`
 *
 * @param {Object} data - A {@link #PostMessageCallback PostMessageCallback} containing 
 *         the data to deliver to the watch.
 *         This will be received in the `data` field of the `type` delivered to 
 *         the `on('message', ...)` handler.
 */
Pebble.postMessage = function(data) { };

/**
 * @desc Get the user's timeline token for this app. This is a string and is 
 *     unique per user per app. Note: In order for timeline tokens to be 
 *     available, the app must be submitted to the Pebble appstore, but does not 
 *     need to be public. Read more in the 
 *     {@link /guides/pebble-timeline/timeline-js/ timeline guides}.
 *
 * @param {TimelineTokenCallback} onSuccess - A developer-defined {@link #TimelineTokenCallback TimelineTokenCallback} 
 *     callback to handle a successful attempt to get the timeline token.
 * @param {Function} onFailure - A developer-defined callback to handle a 
 *     failed attempt to get the timeline token.
 */
 Pebble.getTimelineToken = function(onSuccess, onFailure) { };

/**
 * @desc Subscribe the user to a timeline topic for your app. This can be used 
 *     to filter the different pins a user could receive according to their 
 *     preferences, as well as maintain groups of users.
 *
 * @param {String} topic - The desired topic to be subscribed to. Users will 
 *     receive all pins pushed to this topic.
 * @param {Function} onSuccess - A developer-defined callback to handle a 
 *     successful subscription attempt.
 * @param {Function} onFailure - A developer-defined callback to handle a 
 *     failed subscription attempt.
 */
Pebble.timelineSubscribe = function(topic, onSuccess, onFailure) { };

/**
 * @desc Unsubscribe the user from a timeline topic for your app. Once 
 *     unsubscribed, the user will no longer receive any pins pushed to this 
 *     topic.
 *
 * @param {String} topic - The desired topic to be unsubscribed from.
 * @param {Function} onSuccess - A developer-defined callback to handle a 
 *     successful unsubscription attempt.
 * @param {Function} onFailure - A developer-defined callback to handle a 
 *     failed unsubscription attempt.
 */
Pebble.timelineUnsubscribe = function(topic, onSuccess, onFailure) { };

/**
 * @desc Obtain a list of topics that the user is currently subscribed to. The 
 *     length of the list should be checked to determine whether the user is 
 *     subscribed to at least one topic.
 *
 *    `Pebble.timelineSubscriptions(function(topics) { console.log(topics); }, function() { console.log('error'); } );`
 *
 * @param {TimelineTopicsCallback} onSuccess - The developer-defined function to process the 
 *     retuned list of topic strings.
 * @param {Function} onFailure - The developer-defined function to gracefully 
 *     handle any errors in obtaining the user's subscriptions.
 */
Pebble.timelineSubscriptions = function(onSuccess, onFailure) { };


/**
 * @desc Obtain an object containing information on the currently connected 
 *     Pebble smartwatch.
 *
 *     **Note:** This function is only available when using the Pebble Time 
 *     smartphone app. Check out our guide on {@link /guides/communication/using-pebblekit-js Getting Watch Information} 
 *     for details on how to use this function.
 *
 * @returns {WatchInfo} A {@link #WatchInfo WatchInfo} object detailing the 
 *     currently connected Pebble watch.
 */
Pebble.getActiveWatchInfo = function() { };

/**
 * @desc Returns a unique account token that is associated with the Pebble 
 *     account of the current user.
 *
 *     **Note:** The behavior of this changed slightly in SDK 3.0. Read the 
 *     {@link /guides/migration/migration-guide-3/ Migration Guide} to learn the 
 *     details and how to adapt older tokens.
 *
 * @returns {String} A string that is guaranteed to be identical across devices 
 *     if the user owns several Pebble or several mobile devices. From the 
 *     developer's perspective, the account token of a user is identical across 
 *     platforms and across all the developer's watchapps. If the user is not 
 *     logged in, this function will return an empty string ('').
 */

Pebble.getAccountToken = function() { };

/**
 * @desc Returns a a unique token that can be used to identify a Pebble device.
 *
 * @returns {String} A string that is is guaranteed to be identical for each 
 *     Pebble device for the same app across different mobile devices. The token 
 *     is unique to your app and cannot be used to track Pebble devices across 
 *     applications.
 */
Pebble.getWatchToken = function() { };


/**
 * @desc Triggers a reload of the app glance which first clears any existing 
 *  slices and then adds the provided slices.
 *
 * @param {AppGlanceSlice} appGlanceSlices - {@link #AppGlanceSlice AppGlanceSlice} 
 *     JSON objects to add to the app glance.
 * @param {AppGlanceReloadSuccessCallback} onSuccess - The developer-defined 
 *     callback which is called if the reload operation succeeds.
 * @param {AppGlanceReloadFailureCallback} onFailure - The developer-defined 
 *     callback which is called if the reload operation fails.
 */
Pebble.appGlanceReload = function(appGlanceSlices, onSuccess, onFailure) { };

/**
 * @desc When an app is marked as configurable, the PebbleKit JS component must 
 *  implement `Pebble.openURL()` in the `showConfiguration` event handler. The 
 *  Pebble mobile app will launch the supplied URL to allow the user to configure 
 *  the watchapp or watchface. See the 
 *  {@link /guides/user-interfaces/app-configuration-static/ App Configuration guide}.
 *
 * @param {String} url - The URL of the static configuration page.
 */
Pebble.openURL = function(url) { };

/**
 * @typedef {Function} AppGlanceReloadSuccessCallback
 * @memberof Pebble
 *
 * @desc Called when AppGlanceReload is successful.
 * @param {AppGlanceSlice} AppGlanceSlices - An {@link #AppGlanceSlice AppGlanceSlice} object 
 *     containing the app glance slices.
 */

 /**
 * @typedef {Function} AppGlanceReloadFailureCallback
 * @memberof Pebble
 *
 * @desc Called when AppGlanceReload has failed.
 * @param {AppGlanceSlice} AppGlanceSlices - An {@link #AppGlanceSlice AppGlanceSlice} object 
 *     containing the app glance slices.
 */

/**
 * @typedef {Function} AppMessageAckCallback
 * @memberof Pebble
 *
 * @desc Called when an AppMessage is acknowledged by the watch.
 * @param {Object} data - An object containing the callback data. This contains 
 *   the `transactionId` which is the transaction ID of the message.
 */

/**
 * @typedef {Function} AppMessageNackCallback
 * @memberof Pebble
 *
 * @desc Called when an AppMessage is not acknowledged by the watch.
 * @param {Object} data - An object containing the callback data. This contains 
 *   the `transactionId` which is the transaction ID of the message
 * @param {String} error - The error message
 */

/**
 * @typedef {Function} EventCallback
 * @memberof Pebble
 *
 * @desc Called when an event of any type previously registered occurs. The 
 *     parameters are different depending on the type of event, shown in 
 *     brackets for each parameter listed here.
 * @param {Object} event - An object containing the event information, including:
 *    * `type` - The type of event fired, from the list in the description of [Pebble.addEventListener()](#addEventListener).
 *    * `payload` - The dictionary sent over ``AppMessage`` consisting of 
 *      key-value pairs. *This field only exists for `appmessage` events.*
 *    * `response` - The contents of the URL navigated to when the 
 *      configuration page was closed, after the anchor. This may be encoded, 
 *      which will require use of decodeURIComponent() before reading as an 
 *      object. *This field only exists for for `webviewclosed` events.*
 */

/**
 * @typedef {Function} TimelineTokenCallback
 * @memberof Pebble
 *
 * @desc Called when the user's timeline token is available.
 * @param {String} token - The user's token.
 */

/**
 * @typedef {Function} TimelineTopicsCallback
 * @memberof Pebble
 *
 * @desc Called when the user's list of subscriptions is available for processing by the developer.
 * @param {[String]} List of topic strings that the user is subscribed to
 */

/**
 * @typedef {Function} PostMessageCallback
 * @memberof Pebble
 *
 * @desc The callback function signature to be used with the `message`
 *    {@link #on event}.
 *
 * @param {Object} event - An object containing information about the event:
 *   * `type` - The type of event which was triggered.
 *   * `data` - The data sent within the message.
 */

/**
 * @typedef {Function} PostMessageErrorCallback
 * @memberof Pebble
 *
 * @desc The callback function signature to be used with the `postmessageerror`
 *    {@link #on event}.
 *
 * @param {Object} event - An object containing information about the event:
 *   * `type` - The type of event which was triggered.
 *   * `data` - The data failed to send within the message.
 */

/**
 * @typedef {Function} PostMessageConnectedCallback
 * @memberof Pebble
 *
 * @desc The callback function signature to be used with the `postmessageconnected`
 *    {@link #on event}.
 *
 * @param {Object} event - An object containing information about the event:
 *   * `type` - The type of event which was triggered.
 */

/**
 * @typedef {Function} PostMessageDisconnectedCallback
 * @memberof Pebble
 *
 * @desc The callback function signature to be used with the `postmessagedisconnected`
 *    {@link #on event}.
 *
 * @param {Object} event - An object containing information about the event:
 *   * `type` - The type of event which was triggered.
 */


/**
 * @typedef {Object} WatchInfo
 * @memberof Pebble
 *
 * @desc Provides information about the connected Pebble smartwatch.
 *
 * @property {String} platform - The hardware platform, such as `basalt` or `emery`.
 * @property {String} model - The watch model, such as `pebble_black`
 * @property {String} language - The user's currently selected language on
 *     this watch.
 * @property {Object} firmware - An object containing information about the
 *     watch's firmware version, including:
 *    * `major` - The major version
 *    * `minor` - The minor version
 *    * `patch` - The patch version
 *    * `suffix` - Any additional version information, such as `beta3`
*/

/**
 * @typedef {Object} AppGlanceSlice
 * @memberof Pebble
 *
 * @desc The structure of an app glance.
 *
 * @property {String} expirationTime - Optional ISO date-time string of when 
       the entry should expire and no longer be shown in the app glance.
 * @property {Object} layout - An object containing:
 *    * `icon` - URI string of the icon to display in the app glance, e.g. system://images/ALARM_CLOCK.
 *    * `subtitleTemplateString` - Template string that will be displayed in the subtitle of the app glance.
*/
