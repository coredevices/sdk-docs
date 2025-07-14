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

# Generates a list page for each blog tag.

require 'slugize'

module Jekyll

  class TagPage < Page

    def initialize(site, base, dir, tag)
      @site = site
      @base = base
      @dir = dir
      @name = tag[0].slugize + '/index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'blog/tag_page.html')
      self.data['posts'] = tag[1].sort_by(&:date).reverse
      self.data['name'] = tag[0]
      self.data['tag'] = tag[0]
      self.data['title'] = "Pebble Developer Blog: #{tag[0]}"
    end

  end

  class TagPageRedirect < Page

    def initialize(site, base, dir, tag)
      @site = site
      @base = base
      @dir = dir
      @name = tag[0].slugize + '.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'utils/redirect_permanent.html')
      self.data['path'] = '/' + File.join(dir, tag[0].slugize) + '/'
    end

  end

  class TagPageGenerator < Generator

    def generate(site)
      if ! site.layouts.key? 'blog/tag_page'
        throw 'Layout for the blog tag pages is missing.'
      end
      dir = site.config['tag_dir'] || 'blog/tags'
      site.tags.each do |tag|
        site.pages << TagPage.new(site, site.source, dir, tag)
        site.pages << TagPageRedirect.new(site, site.source, dir, tag)
      end
    end

  end

end
