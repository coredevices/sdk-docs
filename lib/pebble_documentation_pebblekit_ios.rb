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

require 'zip'
require 'nokogiri'
require 'slugize'
require 'open-uri'

module Pebble
  # PebbleKit iOS documentation processing class.
  class DocumentationPebbleKitIos < Documentation
    def initialize(site, source, root)
      super(site)
      @site = site
      @url_root = root
      open(source) do |zf|
        Zip::File.open(zf.path) do |zipfile|
          zipfile.each { |entry| process_entry(entry) }
        end
      end
    end

    private

    def language
      'pebblekit_ios'
    end

    def process_entry(entry)
      return unless File.extname(entry.name) == '.html'
      doc = Nokogiri::HTML(entry.get_input_stream.read)
      process_index(doc) if File.basename(entry.name) == 'index.html'
      process_normal_entry(doc, entry)
    end

    def process_normal_entry(doc, entry)
      doc_entry = DocEntryPebbleKitIos.new(entry, doc, @url_root)
      add_symbol(doc_entry.to_symbol)
      doc_entry.anchor_symbols.map { |symbol| add_symbol(symbol) }
      @pages << doc_entry.create_page(@site)
    end

    def process_index(doc)
      headers = doc.at_css('#content').css('h2').map(&:content)
      lists = doc.at_css('#content').css('ul').map { | list | list.css('li') }
      headers.each_with_index do |header, index|
        process_index_header(header, index, lists)
      end
    end

    def process_index_header(header, index, lists)
      tree_item = {
        name: header,
        url: "#{@url_root}##{header.slugize}",
        children: []
      }
      lists[index].each { |item| process_index_header_item(tree_item, item) }
      @tree << tree_item
    end

    def process_index_header_item(tree_item, item)
      tree_item[:children] << {
        name: item.content,
        url: "#{@url_root}#{item.at_css('a')['href'].sub('.html', '/').gsub('+', '%2B')}",
        path: [item.content],
        children: []
      }
    end
  end

  # DocEntryIos is an iOS documentation class used to process a single page
  # of the iOS documentation.
  class DocEntryPebbleKitIos
    def initialize(entry, doc, url_root)
      @entry = entry
      @doc = doc
      @url_root = url_root
    end

    def to_symbol
      { name: name, url: url.gsub('+', '%2B') }
    end

    def anchor_symbols
      @doc.css('a[name^="//api"][title]').map do |anchor|
        anchor_to_symbol(anchor)
      end
    end

    def create_page(site)
      return nil if @doc.at_css('#content').nil?
      contents = @doc.at_css('#content')
      title = @doc.at_css('.title').content
      group = { 'path' => [File.basename(path)] }
      PageDocPebbleKitIos.new(site, url, title, contents, group)
    end

    private

    def name
      File.basename(@entry.name).sub('.html', '')
    end

    def url
      @url_root + path
    end

    def path
      @entry.name.sub('.html', '/')
    end

    def anchor_to_symbol(anchor)
      summary = @doc.at_css("a[name=\"#{anchor['name']}\"] + h3 + div")
      {
        name: anchor['title'],
        url: (url + '#' + anchor['name']).gsub('+', '%2B'),
        summary: summary.content
      }
    end
  end

  # Jekyll Page subclass for rendering the iOS documentation pages.
  class PageDocPebbleKitIos < Jekyll::Page
    attr_reader :group

    def initialize(site, dir, title, contents, group)
      @site = site
      @base = site.source
      @dir = dir
      @name = 'index.html'
      @contents = contents
      @group = group
      process(@name)
      process_contents
      read_yaml(File.join(@base, '_layouts', 'docs'), 'pebblekit-ios.html')
      data['title'] = title
    end

    def to_liquid(attrs = ATTRIBUTES_FOR_LIQUID)
      super(attrs + %w(
        contents
        group
      ))
    end

    def contents
      @contents.to_html
    end

    private

    def process_contents
      # Clean up links
      @contents.css('a').each { |link| process_page_link(link) }

      remove_duplicated_title
      switch_specification_section_table_headers_to_normal_cells
      clean_up_method_titles
      switch_parameter_tables_into_definition_lists
      remove_footer
    end

    def process_page_link(link)
      process_page_link_class(link) unless link['name'].nil?
      process_page_link_href(link) unless link['href'].nil?
    end

    def process_page_link_class(link)
      link['class'] = '' if link['class'].nil?
      link['class'] << ' anchor'
    end

    def process_page_link_href(link)
      link['href'] = link['href'].gsub('../', '../../')
      link['href'] = link['href'].gsub('.html', '/')
      link['href'] = link['href'].gsub('+', '%2B')
    end

    def remove_duplicated_title
      @contents.css('h1').each(&:remove)
    end

    def switch_specification_section_table_headers_to_normal_cells
      @contents.css('.section-specification th').each do |n|
        n.node_name = 'td'
        n['class'] = 'specification-title'
      end
    end

    def clean_up_method_titles
      # Remove the <code><a> tags inside h3.method-title nodes, strip nbsp and
      # add the subsubtitle class.
      @contents.css('h3.method-title').each do |n|
        method_title = n.at_css('code a')
        n.content = method_title.content.gsub(/\A\u00A0+/, '') if method_title
        n['class'] = 'subsubtitle method-title'
      end
    end

    def switch_parameter_tables_into_definition_lists
      # Change the table node into a definition list
      # For each row recover the parameter name and the description, and add
      # them to the list as term and definition.
      @contents.css('table.argument-def').each do |table|
        table.node_name = 'dl'

        parameters = table.css('tr').map do |row|
          parameter = row.at_css('th.argument-name code')
          parameter.node_name = 'em'
          dt = Nokogiri::XML::Element.new('dt', table.document)
          dt.add_child parameter

          definition = row.at_css('td:not(.argument-name)').content
          dd = Nokogiri::XML::Element.new('dd', table.document)
          dd.children = definition

          [dt, dd]
        end.flatten(1)
        
        table.children.unlink
        parameters.each { |p| table.add_child p }
      end
    end

    def remove_footer
      @contents.css('footer').each(&:remove)
    end
  end
end
