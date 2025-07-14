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

class TagGuideLink < Liquid::Tag
  def initialize(tag_name, text, tokens)
    super
    @text = text.strip
  end

  def make_html(title, url)
    return "<a href=\"#{url}\"><em>#{title}</em></a>"
  end

  def render(context)
    guide_path = @text.split('#')[0].strip
    guide_hash = (@text.split('#').length > 1 ? @text.split('#')[1] : '').strip
    if guide_hash.length > 1
      guide_hash = (guide_hash.split(' ')[0]).strip
    end

    # Custom title?
    guide_title = nil
    index = @text.index('"')
    if index != nil
      guide_title = (@text.split('"')[1]).strip
      guide_title = guide_title.gsub('"', '')
      guide_path = guide_path.split(' ')[0]
    end

    site = context.registers[:site]
    site.collections['guides'].docs.each do |guide|
      path = guide.relative_path.sub(/^_guides\//, '').sub(/\.md$/, '')

      # Check if it's a 'section/guide' path
      if path.index('/') != nil
        if path == guide_path
          return make_html(guide_title != nil ? guide_title : guide.data['title'], 
                           "#{guide.url}#{guide_hash == '' ? '' : "##{guide_hash}"}")
        end
      end

      # Check if it's a 'section' path
      site.data['guides'].each do |id, group|
        if id == guide_path
          return make_html(guide_title != nil ? guide_title : group['title'], "/guides/#{guide_path}")
        end
      end
    end

    # No match
    Jekyll.logger.error "Liquid Error:", "Could not find the guide or section for #{@text}."
    return ''
  end
end

Liquid::Template.register_tag('guide_link', TagGuideLink)
