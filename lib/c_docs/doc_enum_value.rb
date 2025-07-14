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
  # DocEnumValue is a DocElement that is one of the possible values of an enum.
  class DocEnumValue < DocElement
    attr_reader :position, :summary, :id, :platforms, :name, :data

    def initialize(root, node, group, platform)
      super(root, platform)
      @name      = node.at_css('name').content.to_s
      @id        = node['id']
      @group     = group
      @path      = "#{@group.path}##{@name}"
      @nodes     = { platform => node }
      @platforms = [platform]
      @doxygen_processor = DoxygenProcessor.new(platform)
    end

    def add_platform(node, platform)
      @nodes[platform] = node
      @platforms      << platform
      @data[platform]  = {}
    end

    def process(mapping, platform)
      return unless @platforms.include? platform
      process_simplesects(@nodes[platform], mapping, platform)
      @data[platform]['summary'] = @doxygen_processor.process_summary(
        @nodes[platform].at_css('briefdescription'), mapping
      )
    end

    def uniform?
      data['aplite'].to_json == data['basalt'].to_json
    end

    def to_liquid
      {
        'name'      => @name,
        'data'      => @data,
        'url'       => url,
        'platforms' => @platforms
      }
    end
  end
end
