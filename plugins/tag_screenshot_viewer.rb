# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'json'

class TagScreenshotViewer < Liquid::Block
  def render(context)
    site = context.registers[:site]
    data = JSON.parse(super)

    viewer_html = '<div class="screenshot-viewer">'

    viewer_html += '<div class="screenshot-viewer__tabs js-screenshot-tabs">'
    data['platforms'].each do |platform|
      viewer_html += "<h4 data-platform=\"#{platform['hw']}\">#{platform['hw']}</h4>"
    end
    viewer_html += '</div>'

    viewer_html += '<div class="screenshot-viewer__screenshots">'
    data['platforms'].each do |platform|
      viewer_html += "<div class=\"screenshot-viewer__platform\" data-platform=\"#{platform['hw']}\">"
      image_url = make_image_url(data, platform)
      viewer_html += "<img src=\"#{site.config['asset_path']}#{image_url}\" class=\"pebble-screenshot pebble-screenshot--#{platform['wrapper']}\" />"
      viewer_html += '</div>'
    end
    viewer_html += '</div>'

    viewer_html += '</div>'
    viewer_html
  end

  private

  def make_image_url(data, platform)
    File.dirname(data['image']) + '/' + File.basename(data['image'], File.extname(data['image'])) +
        "~#{platform['hw']}" + File.extname(data['image'])
  end
end
Liquid::Template.register_tag('screenshot_viewer', TagScreenshotViewer)
