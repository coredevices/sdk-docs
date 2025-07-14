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

class TagAuthorPhoto < Liquid::Tag
  def initialize(tag_name, text, tokens)
    super
    pieces = text.split(' ')
    @name = pieces[0]
    @size = pieces[1].to_i
  end

  def render(context)
    author_name = context[@name]
    site = context.registers[:site]
    author = site.data['authors'][author_name]
    unless author && author['photo']
      author = site.data['authors']['pebble']
    end
    photo = author['photo']
    photo = site.config['asset_path'] + photo if %r{^/[^/]}.match(photo)
    "<img src=\"#{photo}\" width=#{@size} height=#{@size}>"
  end
end

Liquid::Template.register_tag('author_photo', TagAuthorPhoto)
