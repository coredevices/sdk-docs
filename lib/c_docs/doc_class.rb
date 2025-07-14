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
  # DocClass is a special type of DocElement for structs and unions. 
  # It acts like a DocGroup in that it parses an XML file, but it acts like a
  # DocMember in that it belongs to a group etc.
  class DocClass < DocElement
    attr_reader :summary, :description, :kind, :position, :id, :name

    def initialize(root, dir, platform, kind, id, group)
      super(root, platform)
      @dir      = dir
      @group    = group
      @kind     = kind
      @children = []
      @xml      = {}
      @code     = id
      @doxygen_processor = DoxygenProcessor.new(platform)
      load_xml(platform)
    end

    def load_xml(platform)
      @xml[platform]  = Nokogiri::XML(File.read("#{@dir}/#{platform}/xml/#{@kind}_#{@code}.xml"))
      @data[platform] = {}
      @name           = @xml[platform].at_css('compounddef > compoundname').content.to_s
      @id             = @xml[platform].at_css('compounddef')['id']
      @path           = "#{@group.path}##{@name}"
      create_members(platform)
    end

    def to_liquid
      {
        'name'        => @name,
        'summary'     => @summary,
        'description' => @description,
        'url'         => url,
        'children'    => @children,
        'data'        => @data,
        'platforms'   => @xml.keys,
        'uniform'     => uniform?
      }
    end

    def process(mapping)
      @xml.each do |platform, xml|
        @data[platform]['summary'] = @doxygen_processor.process_summary(
          xml.at_css('compounddef > briefdescription'), mapping
        )
        description = xml.at_css('compounddef > detaileddescription')
        process_simplesects(description, mapping, platform)
        @data[platform]['description'] = @doxygen_processor.process_description(
          description, mapping)
        process_members(mapping, platform)
      end
      @children = @children.reject { |child| child.name.match(/^@/) }
      @children.sort! { |m, n| m.position <=> n.position }
    end

    def uniform?
      identical = @data['aplite'].to_json == @data['basalt'].to_json
      identical &&= @children.all?(&:uniform?)
      identical
    end

    private

    def create_members(platform)
      @xml[platform].css('memberdef').each do |child|
        variable = DocClassVariable.new(@root, child, @group, platform)
        existing = @children.select { |ex| ex.name == variable.name }.first
        if existing.nil?
          @children << variable
        else
          existing.add_platform(platform, child)
        end
      end
    end

    def process_members(mapping, platform)
      @children.each { |child| child.process(mapping, platform) }
    end
  end

  # DocClassVariable is a DocElement subclass that handles the members (or
  # variables) of a struct or union.
  class DocClassVariable < DocElement
    attr_reader :name, :position

    def initialize(root, node, group, platform)
      super(root, platform)
      @name      = node.at_css('name').content.to_s
      @group     = group
      @nodes     = { platform => node }
      @platforms = [platform]
      @path      = "#{@group.path}##{@name}"
      @position  = node.at_css(' > location')['line'].to_i
    end

    def add_platform(platform, node)
      @nodes[platform] = node
      @platforms      << platform
      @data[platform]  = {}
    end

    def to_liquid
      {
        'name'      => @name,
        'data'      => @data,
        'url'       => url,
        'type'      => @type,
        'platforms' => @platforms
      }
    end

    def uniform?
      @data['aplite'].to_json == @data['basalt'].to_json
    end

    def process(mapping, platform)
      return unless @platforms.include? platform
      @data[platform]['summary'] = @doxygen_processor.process_summary(
        @nodes[platform].at_css('briefdescription'), mapping
      )
      description = @nodes[platform].at_css('detaileddescription')
      process_simplesects(description, mapping, platform)
      process_type(mapping, platform)
      @data[platform]['description'] = @doxygen_processor.process_description(
        description, mapping)
    end

    def process_type(mapping, platform)
      if @nodes[platform].at_css('type > ref').nil?
        @data[platform]['type'] = @nodes[platform].at_css('type').content.to_s
      else
        type_node = @nodes[platform].at_css('type').clone()
        @doxygen_processor.process_node_ref(type_node.at_css('ref'), mapping)
        @data[platform]['type'] = type_node.to_html.to_s
      end
    end
  end
end
