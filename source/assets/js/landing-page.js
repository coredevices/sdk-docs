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

function willPlayVideo() {
  return ! (/iPad|iPhone|iPod/i.test(navigator.userAgent) || /Android/i.test(navigator.userAgent));
}

$('body').on('pbl-menu-loaded', function () {
  if (! willPlayVideo()) {
    return;
  }
  $('.js-video-slide').each(function (index, elem) {
    $(elem).vide({
      mp4: $(elem).data('video'),
      ogv: $(elem).data('video').replace(/\.mp4$/, '.ogv'),
      webm: $(elem).data('video').replace(/\.mp4$/, '.webm')
    }, {
      loop: false,
      posterType: 'none'
    });
    $(elem).data('vide').getVideoObject().onended = function (event) {
      $(elem).trigger('video-ended');
    };
  });
});

var slideTimeout = null;
var previousSlide = null;
var indexSlick = $('.js-slider').slick({
  autoplay: false,
  arrows: false,
  dots: true,
  onBeforeChange: function (event, from, to) {
    if (slideTimeout) {
      clearTimeout(slideTimeout);
      slideTimeout = null;
    }
    var toSlide = findSlideByIndex(to);
    if (isVideoSlide(toSlide) && willPlayVideo()) {
      var video = toSlide.data('vide').getVideoObject();
      if (video) {
        video.currentTime = 0;
        video.play();
      }
    }
    previousSlide = findSlideByIndex(from);
  },
  onAfterChange: function (event) {
    if (previousSlide && isVideoSlide(previousSlide) && willPlayVideo()) {
      var video = previousSlide.data('vide').getVideoObject();
      if (video) {
        video.pause();
        video.currentTime = 0;
      }
    }
    previousSlide = null;
  }
});

function setupSlideTransition() {
  var slide = $('.js-slide[data-slide-index="' + indexSlick.slickCurrentSlide() + '"]:not(.slick-cloned)');
  var isVideoSlide = slide.hasClass('js-video-slide');
  if (isVideoSlide && willPlayVideo()) {
    slide.on('video-ended', function () {
      if (slide.data('slide-index') === indexSlick.slickCurrentSlide()) {
        indexSlick.slickNext();
        setupSlideTransition();
      }
    });
  }
  else {
    var duration = slide.data('duration');
    slideTimeout = setTimeout(function () {
      indexSlick.slickNext();
      setupSlideTransition();
      slideTimeout = null;
    }, duration);
  }
}

function findSlideByIndex(index) {
  return $('.js-slide[data-slide-index="' + index + '"]:not(.slick-cloned)');
}

function isVideoSlide(slide) {
  return slide.hasClass('js-video-slide');
}

setupSlideTransition();
