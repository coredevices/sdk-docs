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
require 'jekyll'
require_relative '../lib/pebble_documentation'
require_relative '../lib/pebble_documentation_js'
require_relative '../plugins/pebble_markdown_parser'

require_relative './docs'

describe Pebble::DocumentationJs do
  include_context 'docs'

  before do
    @docs_config = load_config
    @site = fake_site
    @site.data['js'] = JSON.parse(File.read('spec/fixtures/js.json'))
    @doc = Pebble::DocumentationJs.new(@site, 'js', '/docs/js/', 'js')
  end

  describe '#load_symbols' do
    before do
      @symbols = []
      @doc.load_symbols(@symbols)
    end

    it 'should add symbols to the list' do
      expect(@symbols.size).to be > 0
    end

    it 'should contain some known symbols' do
      expect(find_symbol(@symbols, 'addEventListener')).to_not be(nil)
      expect(find_symbol(@symbols, 'removeEventListener')).to_not be(nil)
    end

    it 'should tag all symbols with the correct language' do
      expect(@symbols.any? { |symbol| symbol[:language] != 'js' }).to be(false)
    end

    it 'should create symbols with correct URLS' do
      expect(@symbols.any? { |symbol| !symbol[:url].start_with?('/docs/js/') })
        .to be(false)
    end

    it 'should not create two symbols that clash' do
      expect(clashing_symbols(@symbols)).to be false
    end
  end

  describe '#create_pages' do
    before do
      @pages = []
      @doc.create_pages(@pages)
    end

    it 'should add some pages to the list' do
      expect(@pages.size).to be > 0
    end

    it 'should create pages with module details exposed' do
      page = @pages[0]
      expect(page.js_module).to_not be(nil)
    end
  end

  describe '#build_tree' do
    before do
      @tree = []
      @doc.build_tree(@tree)
    end

    it 'should populate the tree' do
      expect(@tree.size).to be > 0
    end

    it 'should create tree objects formatted properly' do
      @tree.each { |branch| valid_branch(branch) }
    end
  end

  describe 'completeness' do
    before do
      @tree = []
      @symbols = []
      @pages = []
      @doc.build_tree(@tree)
      @doc.create_pages(@pages)
      @doc.load_symbols(@symbols)
    end

    it 'should have a page for every symbol' do
      symbol_to_page_completeness(@symbols, @pages)
    end
  end
end
