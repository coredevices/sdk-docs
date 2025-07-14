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

# Liquid inline tag to produce an Edit Gist in CloudPebble button
class TagCloudPebbleEditGist < Liquid::Tag
  def initialize(tag_name, gist_id, tokens)
    super
    @gist_id = gist_id.strip
  end

  def render(context)
    page = context.registers[:page]
    extension = File.extname(page['name'])
    if extension == '.md'
      render_markdown
    else
      render_html
    end
  end

  def render_markdown
    "[#{content} >{#{markdown_classes}}](#{url})"
  end

  def render_html
    "<a href=\"#{url}\" title=\"\" class=\"#{html_classes}\">#{content}</a>"
  end

  private

  def url
    "https://cloudpebble.net/ide/gist/#{@gist_id}"
  end

  def html_classes
    'btn btn--wide btn--pink'
  end

  def markdown_classes
    'wide,pink'
  end

  def content
    'Edit in CloudPebble'
  end
end
Liquid::Template.register_tag('cloudpebble_edit_gist', TagCloudPebbleEditGist)
