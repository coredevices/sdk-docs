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

require_relative 'doc_element.rb'
require_relative 'doc_member.rb'
require_relative 'doc_class.rb'
require_relative 'doxygen_processor.rb'

module Pebble
  # A DocGroup is a a collection of members, structs and subgroups that will
  # become a page in the C documentation.
  class DocGroup < DocElement
    attr_accessor :groups, :members, :name, :path, :menu_path, :classes, :id

    def initialize(root, dir, platform, id, menu_path = [])
      super(root, platform)
      @dir       = dir
      @menu_path = Array.new(menu_path)
      @xml       = {}
      @groups    = []
      @members   = []
      @classes   = []
      @group_id  = id
      @doxygen_processor = DoxygenProcessor.new(platform)
      @root = root
      load_xml(platform)
    end

    def load_xml(platform)
      @xml[platform] = Nokogiri::XML(File.read("#{@dir}/#{platform}/xml/group___#{@group_id}.xml"))
      @id            = @xml[platform].at_css('compounddef')['id']
      @name          = @xml[platform].at_css('compounddef > title').content.to_s
      @menu_path    << @name if @path.nil?
      @path          = @menu_path.join('/').gsub(' ', '_') + '/'
      create_descendents(platform)
    end

    def process(mapping, platform)
      return if @xml[platform].nil?
      @data[platform] = {} if @data[platform].nil?
      @data[platform]['summary'] = @doxygen_processor.process_summary(
        @xml[platform].at_css('compounddef > briefdescription'), mapping)
      description = @xml[platform].at_css('compounddef > detaileddescription')
      process_simplesects(description, mapping, platform)
      @data[platform]['description'] = @doxygen_processor.process_description(
        description, mapping)
      process_descendents(mapping, platform)
    end

    def to_page(site)
      PageDocC.new(site, @root, site.source, "#{@path}index.html", self)
    end

    def to_branch
      {
        'name'     => @name,
        'url'      => url,
        'children' => @groups.map(&:to_branch),
        'summary'  => default_data('summary')
      }
    end

    def mapping_array
      mapping = [to_mapping]
      @groups.each  { |group| mapping += group.mapping_array }
      @members.each { |member| mapping << member.to_mapping }
      @classes.each { |cls| mapping << cls.to_mapping }
      mapping
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def to_liquid
      {
        'name'        => @name,
        'url'         => url,
        'path'        => @menu_path,
        'groups'      => @groups,
        'members'     => @members,
        'functions'   => @members.select { |member| member.kind == 'function' },
        'enums'       => @members.select { |member| member.kind == 'enum'     },
        'defines'     => @members.select { |member| member.kind == 'define'   },
        'typedefs'    => @members.select { |member| member.kind == 'typedef'  },
        'structs'     => @classes.select { |member| member.kind == 'struct'   },
        'unions'      => @classes.select { |member| member.kind == 'union'    },
        'data'        => @data,
        'basalt_only' => !@xml.key?('aplite'),
        'summary'     => default_data('summary'),
        'description' => default_data('description')
      }
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    private

    def create_descendents(platform)
      create_inner_groups(platform)
      create_members(platform)
      create_inner_classes(platform)
      @members.sort! { |m, n| m.position <=> n.position }
    end

    def create_inner_groups(platform)
      @xml[platform].css('innergroup').each do |child|
        id = child['refid'].sub(/^group___/, '')
        new_group  = DocGroup.new(@root, @dir, platform, id, @menu_path)
        group = @groups.select { |grp| new_group.name == grp.name }.first
        if group.nil?
          @groups << new_group
        else
          group.load_xml(platform)
        end
      end
    end

    def create_members(platform)
      @xml[platform].css('memberdef').map do |child|
        new_member =  DocMember.new(@root, child, self, platform)
        member = @members.select { |mem| mem.name == new_member.name }.first
        if member.nil?
          @members << new_member
        else
          member.add_platform(platform, child)
        end
      end
    end

    def create_inner_classes(platform)
      @xml[platform].css('innerclass').map do |child|
        next if child.content.to_s.match(/__unnamed__/)
        next if child.content.to_s.match(/\./)
        if child['refid'].match(/^struct_/)
          create_struct(child, platform) 
        elsif child['refid'].match(/^union_/)
          create_union(child, platform)
        end
      end
    end

    def create_struct(node, platform)
      id = node['refid'].sub(/^struct_/, '')
      new_struct = DocClass.new(@root, @dir, platform, 'struct', id, self)
      struct = @classes.select { |str| new_struct.name == str.name }.first
      if struct.nil?
        @classes << new_struct
      else
        struct.load_xml(platform)
      end
    end

    def create_union(node, platform)
      id = node['refid'].sub(/^union_/, '')
      new_union = DocClass.new(@root, @dir, platform, 'union', id, self)
      union = @classes.select { |un| un.name == new_union.name }.first
      if union.nil?
        @classes << new_union
      else
        union.load_xml(platform)
      end
    end

    def process_descendents(mapping, platform)
      @groups.each  { |group| group.process(mapping, platform) }
      @members.each { |member| member.process(mapping, platform) }
      @classes.each { |member| member.process(mapping) }
    end
  end
end
