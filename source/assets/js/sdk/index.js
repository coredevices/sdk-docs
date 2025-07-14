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

$sdkLink = $('.js-sdk-link');
$('.instructions-other').hide();
if ((navigator.userAgent.match(/MSIE/i)) || (navigator.userAgent.match(/Windows/i))) {
  $sdkLink.attr('href', '/sdk/install/windows/');
  $('.instructions-windows').show();
}
else if (navigator.userAgent.match(/Macintosh/i)) {
  $sdkLink.attr('href', '/sdk/install/mac/');
  $('.instructions-mac').show();
  if (document.location.hash === '#homebrew') {
    setTimeout(function () {
      $('a[data-modal-target="#modal-mac-auto"]').click();
    }, 100);
  }
}
else if (navigator.userAgent.match(/Linux/i) && ! navigator.userAgent.match(/Android/i)) {
  $sdkLink.attr('href', '/sdk/install/linux/');
  $('.instructions-linux').show();
}
else {
  $('.instructions-other').show();
}
