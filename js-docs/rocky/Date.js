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
 * @namespace Date
 *
 * @desc Creates a JavaScript Date instance that represents a single moment in
 *  time. Date objects are based on a time value that is the number of
 *  milliseconds since 1 January, 1970 UTC.
 *
 * `var d = new Date();`
 *
 * We fully implement standard JavaScript `Date` functions, such as: `getDay()`, `getHours()` etc.
 *
 * For full `Date` documentation see:
 *  {@link https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Date}
 *
 * ### Locale Date Methods
 *
 * The locale date methods ({@link #toLocaleString toLocaleString}, 
 *  {@link #toLocaleTimeString toLocaleTimeString} and 
 *  {@link #toLocaleDateString toLocaleDateString})  are currently limited in 
 *  their initial implementation.
 *
 * Available **options**:
 *
 * **hour12**
 *
 * Use 12-hour time (as opposed to 24-hour time). Possible values are `true` and `false`; the default is locale dependent (Pebble setting).
 *
 * **weekday**
 *
 * The representation of the weekday. Possible values are "narrow", "short", "long".
 *
 * **year**
 *
 * The representation of the year. Possible values are "numeric", "2-digit".
 *
 * **month**
 *
 * The representation of the month. Possible values are "numeric", "2-digit", "narrow", "short", "long".
 *
 * **day**
 *
 * The representation of the day. Possible values are "numeric", "2-digit".
 *
 * **hour**
 *
 * The representation of the hour. Possible values are "numeric", "2-digit".
 *
 * **minute**
 *
 * The representation of the minute. Possible values are "numeric", "2-digit".
 *
 * **second**
 *
 * The representation of the second. Possible values are "numeric", "2-digit".
 *
 *
 * Please note that locale based date and time functions have the following
 *  limitations at this time:
 *
 *   * You cannot manually specify a locale, it's automatically based upon the 
 *  current device settings. Locale is optional, or you can specify `undefined`.
 *
 *  `console.log(d.toLocaleDateString());`
 *
 *   * Only a single date/time value can be requested in each method call. Do 
 *  NOT request multiple options. e.g. `{hour: 'numeric', minute: '2-digit'}`
 *
 *  `console.log(d.toLocaleTimeString(undefined, {hour: 'numeric'}));`
 */
var Date = new Object();

/**
 * @desc This method returns a string with a language sensitive representation
 *  of this date object.
 *
 * `d.toLocaleString();`
 *
 * @param {String} locale - (Optional) The name of the locale.
 * @param {Object} options - (Optional) Only a single option is currently supported.
 */
Date.toLocaleString = function(locale, options) { };

/**
 * @desc This method returns a string with a language sensitive representation
 * of the date portion of this date object.
 *
 * `d.toLocaleTimeString(undefined, {hour: 'numeric'});`
 *
 * @param {String} locale - (Optional) The name of the locale.
 * @param {Object} options - (Optional) Only a single option is currently supported.
 */
Date.toLocaleTimeString = function(locale, options) { };

/**
 * @desc This method returns a string with a language sensitive representation
 * of the time portion of this date object.
 *
 * `d.toLocaleDateString(undefined, {weekday: 'long'});`
 *
 * @param {String} locale - (Optional) The name of the locale.
 * @param {Object} options - (Optional) Only a single option is currently supported.
 */
Date.toLocaleDateString = function() { };


