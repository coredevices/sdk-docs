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

$(function () {
  
  $('.docs__item__tabs a[data-platform]').on('click', function () {
    var offset = $(this).position().top - $('body').scrollTop();
    var platform = $(this).data('platform');
    showPlatform(platform);
    savePlatform(platform);
    var newOffset = $(this).position().top - $('body').scrollTop();
    $('body').scrollTop($('body').scrollTop() + (newOffset - offset));
  });
  
  function showPlatform(platform) {
    $('.docs__item__tabs a[data-platform]').removeClass('active');
    $('.docs__item__tabs a[data-platform="' + platform + '"]').addClass('active');
    $('section[data-platform]').hide();
    $('section[data-platform="' + platform + '"]').show();
  }
  
  function savePlatform(platform) {
    Cookies.set('docs-platform', platform);
  }

  var defaultPlatform = $('[data-basalt-only]').length ? 'basalt' : 'aplite';
  showPlatform(Cookies.get('docs-platform') || defaultPlatform);

});
