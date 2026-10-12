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

require 'open-uri'
require 'zip'
require 'nokogiri'

require_relative '../lib/pebble_documentation_pebblekit_android.rb'
require_relative '../lib/pebble_documentation_c.rb'
require_relative '../lib/pebble_documentation_js.rb'
require_relative '../lib/pebble_documentation_pebblekit_ios.rb'
require_relative '../lib/toc_generator.rb'

OpenURI::Buffer.send :remove_const, 'StringMax' if OpenURI::Buffer.const_defined?('StringMax')
OpenURI::Buffer.const_set 'StringMax', 0

# Master plugins for processing the documentation on the site.
# The actual work is done in individual classes for each language type.
# Each class generates three types of data:
# - Symbols
# - Pages
# - Tree
#
# The Symbols are a list of objects that are things such as methods, classes
# or enums, that are used to populate the search indexes, and power the double
# backtick docs linking.
#
# The Pages are the Jekyll pages that will be part of the built site and are
# what the user will see.
#
# The Tree is used to build the site navigation.
#
# Note: The docs_url variable is created from the environment.
# See environment.md for more information.

module Jekyll
  class DocsGenerator < Generator
    priority :high

    def generate(site)
      @site = site
      @docs = {
        symbols: [],
        pages: [],
        tree: {}
      }
      if !@site.config['skip_docs'].nil? && (@site.config['skip_docs'] == 'true')
        Jekyll.logger.info('Docs Generation:', 'Skipping documentation generation...')
      else
        Jekyll.logger.info('Docs Generation:', 'Generating pages...')
        generate_docs
        render_pages
        Jekyll.logger.info('Docs Generation:', 'Done.')
      end
      set_data
    end

    private

    def generate_docs
      # The order of these functions will determine the order of preference
      # when looking up symbols e.g. double backticks
      # DO NOT CHANGE THE ORDER UNLESS YOU KNOW WHAT YOU ARE DOING
      generate_docs_c
      generate_docs_pebblekit_js
      if @site.config['docs_url'] && !@site.config['docs_url'].empty?
        generate_docs_pebblekit_android
        generate_docs_pebblekit_ios
      end
    end

    def render_pages
      @docs[:pages].each { |page| @site.pages << page }
    end

    def set_data
      # A somewhat ugly hack to let the Markdown parser have access
      # to this data.
      @site.config[:docs] = @docs
      @site.data['docs'] = @docs
      # Another ugly hack to make accessing the data much easier from Liquid.
      @site.data['docs_tree'] = JSON.parse(JSON.dump(@docs[:tree]))
      @site.data['symbols'] = JSON.parse(JSON.dump(@docs[:symbols]))
    end

    def generate_docs_c
      c_docs_dir = @site.config['c_docs_dir'] || File.join(@site.source, '..')
      docs = Pebble::DocumentationC.new(
        @site,
        c_docs_dir,
        '/docs/c/'
      )
      load_data(docs, :c)
    end

    def generate_docs_pebblekit_js
      docs = Pebble::DocumentationJs.new(
        @site,
        @site.data['docs']['pebblekit_js'],
        '/docs/pebblekit-js/',
        'pebblekit_js'
      )
      load_data(docs, :pebblekit_js)
    end

    def generate_docs_pebblekit_android
      docs = Pebble::DocumentationPebbleKitAndroid.new(
        @site,
        @site.config['docs_url'] + @site.data['docs']['pebblekit_android']
      )
      load_data(docs, :pebblekit_android)
    end

    def generate_docs_pebblekit_ios
      docs = Pebble::DocumentationPebbleKitIos.new(
        @site,
        @site.config['docs_url'] + @site.data['docs']['pebblekit_ios'],
        '/docs/pebblekit-ios/'
      )
      load_data(docs, :pebblekit_ios)
    end

    def load_data(docs, type)
      @docs[:tree][type] = []
      docs.load_symbols(@docs[:symbols])
      docs.create_pages(@docs[:pages])
      docs.build_tree(@docs[:tree][type])
    end
  end
end
