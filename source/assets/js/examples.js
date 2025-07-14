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

var exampleFilters = {};

$('.js-examples-tag').on('click', function (event) {
  event.preventDefault();

  var $tag = $(this);
  var $filters = $tag.parents('.examples__filters');

  if ($tag.hasClass('js-selected-tag')) {
    $tag.removeClass('js-selected-tag');
    $tag.removeClass('selected');
    $filters.removeClass('examples__filters--selected');

    exampleFilters[$filters.data('filter-type')] = null;
    updateExamples();
  }
  else {
    var $selectedTag = $filters.find('.js-selected-tag');
    $selectedTag.removeClass('js-selected-tag');
    $selectedTag.removeClass('selected');

    $tag.addClass('js-selected-tag');
    $tag.addClass('selected');
    $filters.addClass('examples__filters--selected');

    exampleFilters[$filters.data('filter-type')] = $tag.text();
    updateExamples();
  }
});

function updateExamples() {
  $('.js-example').each(function (index, elem) {
    var $example = $(elem);
    var tags = $example.data('tags').split('|');
    var languages = $example.data('languages').split('|');
    var hardwarePlatforms = $example.data('hardware-platforms').split('|');

    if (exampleFilters['tags'] && tags.indexOf(exampleFilters['tags']) === -1) {
      $example.hide();
      return;
    }
    if (exampleFilters['languages'] && languages.indexOf(exampleFilters['languages']) === -1) {
      $example.hide();
      return;
    }
    if (exampleFilters['hardware-platforms'] && hardwarePlatforms.indexOf(exampleFilters['hardware-platforms']) === -1) {
      $example.hide();
      return;
    }

    $example.show();
  });

  if ($('.js-example:visible').length > 0) {
    $('.js-no-examples').hide();
  }
  else {
    $('.js-no-examples').show();
  }
}
