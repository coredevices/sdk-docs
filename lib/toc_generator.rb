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

require 'redcarpet'
require 'nokogiri'

module Pebble

  class TocGenerator

    def initialize(max_depth=-1)
      @max_depth = max_depth
      @markdown = TocMarkdown.new()
      @redcarpet = Redcarpet::Markdown.new(@markdown,
        fenced_code_blocks: true,
        autolink: true,
        tables: true,
        no_intra_emphasis: true,
        strikethrough: true,
        highlight: true)
    end

    def generate(content)
      @redcarpet.render(content)
      page_toc = @markdown.get_toc
      toc_array(toc_normalised(page_toc))
    end

    private

    # Convert the ToC array of hashes into an array of array so that it can
    # be used in the Liquid template.
    def toc_array(array)
      array.map { |entry| [ entry[:id], entry[:title], entry[:level] ] }
    end

    # Normalised the ToC array by ensuring that the smallest level number is 1.
    def toc_normalised(array)
      min_level = 100
      array.each { |entry| min_level = [ min_level, entry[:level] ].min }
      level_offset = min_level - 1
      array.map { |entry| entry[:level] -= level_offset; entry }.select do |entry|
        @max_depth == -1 || entry[:level] <= @max_depth
      end
    end

  end

  class TocMarkdown < Redcarpet::Render::HTML

    def initialize()
      @toc = Array.new
      @depth = 0
      super()
    end

    def get_toc()
      @toc
    end

    def header(text, header_level)
      text = Nokogiri::HTML(text).text if text.include?('<')
      entry = { title: text, id: text.slugize, level: header_level }
      @toc << entry
      ""
    end

  end

end
