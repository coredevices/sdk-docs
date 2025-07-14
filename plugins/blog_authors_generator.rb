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

# Generates a list page for each blog author.
# The list of authors is in /source/_data/blog_authors.yml

module Jekyll

  class AuthorPage < Page

    def initialize(site, base, dir, author)
      @site = site
      @base = base
      @dir = dir
      @name = author[0] + '/index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'blog/author_page.html')
      self.data['posts'] = site.posts.docs.select { |post| post['author'] == author[0] }
      self.data['author_name'] = author[1]['name']
      self.data['author'] = author[0]
      self.data['title'] = "Pebble Developer Blog: #{author[1]['name']}"
    end

  end

  class AuthorPageGenerator < Generator

    def generate(site)
      if ! site.layouts.key? 'blog/author_page'
        throw 'Layout for the blog author pages is missing.'
      end
      dir = site.config['tag_dir'] || 'blog/authors'
      site.data['authors'].each do |author|
        author[1]['num_posts'] = site.posts.docs.select { |post| post['author'] == author[0] }.length
        site.pages << AuthorPage.new(site, site.source, dir, author)
      end
    end

  end

end
