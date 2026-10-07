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

require_relative './spec_helper'
require_relative '../lib/llms_export'

describe LlmsExport do
  FakePage = Struct.new(:url, :data, :output)
  FakeSite = Struct.new(:config, :source, :pages, :collections, :layouts, :data)

  def page(url, data = {})
    body = "<div class=\"content\"><div class=\"col-l-8\"><p>#{'Enough content to count as a page. ' * 4}</p></div></div>"
    FakePage.new(url, { 'layout' => 'guides/default' }.merge(data), "<html><head></head><body>#{body}</body></html>")
  end

  let(:pages) do
    [
      page('/'),
      page('/guides/tools-and-resources/pebble-tool/'),
      page('/docs/c/User_Interface/Window/index.html'),
      page('/blog/2016/10/04/ready-for-pebble-2/'),
      page('/blog/'),
      page('/blog/2/'),
      page('/blog/tags/freshly-baked/index.html'),
      page('/blog/authors/katharine/index.html'),
      page('/tutorials/redirected.html', 'layout' => 'redirect'),
    ]
  end

  let(:site) do
    FakeSite.new({ 'url' => 'https://developer.repebble.com' }, '/site/source/', pages, {}, {}, {})
  end

  let(:builder) do
    LlmsExport::Builder.new(site).tap { |b| b.send(:collect_pages) }
  end

  describe '.md_path_for' do
    it 'maps directory, index.html and .html URLs to one .md twin' do
      expect(LlmsExport.md_path_for('/')).to eq('/index.md')
      expect(LlmsExport.md_path_for('/guides/foo/')).to eq('/guides/foo.md')
      expect(LlmsExport.md_path_for('/docs/c/Foo/index.html')).to eq('/docs/c/Foo.md')
      expect(LlmsExport.md_path_for('/docs/c/Foo.html')).to eq('/docs/c/Foo.md')
    end

    it 'keeps the old /foo/index.md form as an alias for index.html pages' do
      expect(LlmsExport.md_alias_for('/docs/c/Foo/index.html')).to eq('/docs/c/Foo/index.md')
      expect(LlmsExport.md_alias_for('/guides/foo/')).to be_nil
    end
  end

  describe 'exclusions' do
    it 'drops blog archive pages and keeps posts' do
      urls = builder.instance_variable_get(:@pages).map(&:url)
      expect(urls).to include('/blog/2016/10/04/ready-for-pebble-2/')
      expect(urls).not_to include('/blog/', '/blog/2/', '/blog/tags/freshly-baked/index.html',
                                  '/blog/authors/katharine/index.html', '/tutorials/redirected.html')
    end

    it 'marks only eligible pages for the alternate link' do
      LlmsExport::Builder.mark_pages(site)
      expect(pages[2].data['llms_md_path']).to eq('/docs/c/User_Interface/Window.md')
      expect(pages[6].data).not_to have_key('llms_md_path')
    end
  end

  describe '#md_url_for' do
    it 'returns the twin URL only for emitted pages' do
      expect(builder.md_url_for('/docs/c/User_Interface/Window/index.html'))
        .to eq('https://developer.repebble.com/docs/c/User_Interface/Window.md')
      expect(builder.md_url_for('/blog/tags/freshly-baked/index.html')).to be_nil
    end
  end

  describe '#sub_group' do
    it 'orders tutorials by tutorial then part, not by title' do
      tutorial = lambda do |name, part, title|
        page("/tutorials/#{name}-tutorial/part#{part}/",
             'tutorial' => name, 'tutorial_part' => part, 'title' => title)
      end
      tutorials = [
        tutorial.call('watchface', 6, 'Adding a settings page'),
        tutorial.call('alloy-watchface', 1, 'Your First Watchface'),
        tutorial.call('rocky-watchface', 1, 'Build a Watchface in JavaScript'),
        tutorial.call('advanced', 1, 'Vector Animations'),
        tutorial.call('watchface', 1, 'Your First Watchface'),
        tutorial.call('alloy-watchface', 2, 'Customizing Your Watchface'),
        page('/tutorials/', 'title' => 'Tutorials'),
      ]
      groups = builder.send(:sub_group, tutorials)
      expect(groups.map(&:first)).to eq([''])
      expect(groups.first.last.map(&:url)).to eq([
        '/tutorials/',
        '/tutorials/watchface-tutorial/part1/',
        '/tutorials/watchface-tutorial/part6/',
        '/tutorials/alloy-watchface-tutorial/part1/',
        '/tutorials/alloy-watchface-tutorial/part2/',
        '/tutorials/advanced-tutorial/part1/',
        '/tutorials/rocky-watchface-tutorial/part1/',
      ])
    end
  end

  describe '#rewrite_href' do
    def rewrite(href)
      builder.send(:rewrite_href, href)
    end

    it 'rewrites /foo, /foo/ and /foo/index.html to the absolute .md twin' do
      md = 'https://developer.repebble.com/docs/c/User_Interface/Window.md'
      expect(rewrite('/docs/c/User_Interface/Window')).to eq(md)
      expect(rewrite('/docs/c/User_Interface/Window/')).to eq(md)
      expect(rewrite('/docs/c/User_Interface/Window/index.html#window_create')).to eq("#{md}#window_create")
      expect(rewrite('https://developer.repebble.com/guides/tools-and-resources/pebble-tool/'))
        .to eq('https://developer.repebble.com/guides/tools-and-resources/pebble-tool.md')
    end

    it 'makes other internal links absolute and leaves external links alone' do
      expect(rewrite('/blog/tags/freshly-baked/')).to eq('https://developer.repebble.com/blog/tags/freshly-baked/')
      expect(rewrite('/assets/images/foo.png')).to eq('https://developer.repebble.com/assets/images/foo.png')
      expect(rewrite('https://github.com/coredevices')).to be_nil
      expect(rewrite('#anchor')).to be_nil
    end
  end
end
