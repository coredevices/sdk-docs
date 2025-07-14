---
---

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

var $results = $('#js-404-search');

var search = new Search({
  appId: '{{ site.algolia_app_id }}',
  apiKey: '{{ site.algolia_api_key }}',
  prefix: '{{ site.algolia_prefix }}',
  options: {
    hitsPerPage: 2,
    getRankingInfo: true,
    distinct: true,
    removeWordsIfNoResults: 'firstWords',
    analytics: false
  }
});

search.on('results', showResults);
search.on('error', function (err) {
  Rollbar.error('404 search error', err);
});

search.search(window.location.pathname.split('/').join(' '));

function showResults(results) {
  Object.keys(results).forEach(function (index) {
    var type = Search.indexes[index];
    var typeResults = results[index];
    $results.append('<li style="margin-top: 0.5em;"><strong>' + type.title + '</strong></li>');
    typeResults.hits.forEach(function (result) {
      $results.append(buildResult(result));
    });
  });
  $('#js-404-search-intro').show()
}

function buildResult(result) {
  var $result = $('<li>');
  $result.append($('<a/>').text(result.title).attr('href', result.url));
  return $result;
}
