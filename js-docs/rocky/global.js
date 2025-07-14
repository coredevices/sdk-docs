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

// Global Functions, Members, and Typedefs

/**
 * @desc Calls a function after a specified delay.
 *
 * `var timeoutId = setTimeout(function(...){}, 10000);`
 *
 * @returns {Number} timeoutId - The ID of the timeout
 * @param {Function} fct - The function to execute
 * @param {Number} delay - The delay (in ms)
 */
setTimeout = function(fct, delay) { };

/**
 * @desc Clears the delay set by ``setTimeout``.
 *
 * `clearTimeout(timeoutId);`
 *
 * @param {Number} timeoutId - The ID of the timeout you wish to clear.
 */
clearTimeout = function(timeoutId) { };

/**
 * @desc Repeatedly calls a function, with a fixed time delay between
 *  each call.
 *
 * `var intervalId = setInterval(function(...){}, 10000);`
 *
 * @returns {Number} intervalId - The ID of the interval
 * @param {Function} fct - The function to execute
 * @param {Number} delay - The delay (in ms)
 */
setInterval = function(fct, delay) { };

/**
 * @desc Clears the interval set by ``setInterval``.
 *
 * `clearInterval(intervalId);`
 *
 * @param {Number} intervalId - The ID of the interval you wish to clear
 */
clearInterval = function(intervalId) { };
