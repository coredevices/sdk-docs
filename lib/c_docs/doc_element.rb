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

module Pebble
  # DocElement is an abstract C Documentation class that is subclasses for 
  # each of the various items that build up a documentation page, symbol or
  # tree item.
  class DocElement
    KNOWN_SECT_TYPES = %w(return note)
    attr_reader :url

    def initialize(root, platform)
      @root = root
      @data = {}
      @data[platform] = {}
      @doxygen_processor = DoxygenProcessor.new(platform)
    end

    def to_symbol
      {
        name:    @name,
        url:     url,
        summary: default_data('summary')
      }
    end

    def to_mapping
      {
        id:  @id,
        url: url
      }
    end

    private

    def default_data(key)
      return @data['basalt'][key] unless @data['basalt'].nil? || @data['basalt'][key].nil?
      return @data['aplite'][key] unless @data['aplite'].nil? || @data['aplite'][key].nil?
      ''
    end

    def url
      "#{@root}#{@path}"
    end

    def add_data(type, value, platform)
      @data[platform] = {} if @data[platform].nil?
      @data[platform][type] = [] if @data[platform][type].nil?
      @data[platform][type] << value
    end

    def process_simplesects(node, mapping, platform)
      if node.name.to_s == 'detaileddescription'
        desc = node
      else
        desc = node.at_css('detaileddescription')
      end
      return if desc.nil?
      desc.css('simplesect').each do |sect|
        if KNOWN_SECT_TYPES.include?(sect['kind'])
          process_simplesect_basic(sect, mapping, platform)
        elsif sect['kind'] == 'see'
          process_simplesect_see(sect, mapping, platform)
        end
      end
    end

    def process_simplesect_basic(sect, mapping, platform)
      value = @doxygen_processor.process_summary(sect.clone, mapping)
      add_data(sect['kind'], value, platform)
      sect.remove
    end

    def process_simplesect_see(sect, mapping, platform)
      if sect.at_css('para > ref').nil?
        add_data(sect['kind'],
                 @doxygen_processor.process_paragraph(sect.at_css('para'),
                                                    mapping), platform)
      else
        see_node = sect.at_css('para > ref').clone
        @doxygen_processor.process_node_ref(see_node, mapping)
        add_data(sect['kind'], see_node.to_html.to_s, platform)
      end
      sect.remove
    end
  end
end
