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
require_relative '../lib/search_markdown'

module Jekyll

  module Convertible

    def get_output
      process_search
      @search_markdown.get_contents
    end

    def get_sections
      process_search
      @search_markdown.get_sections
    end

    private

    def process_search
      unless @search_markdown.nil?
        return
      end
      @search_markdown = Pebble::SearchMarkdown.new()
      redcarpet = Redcarpet::Markdown.new(@search_markdown,
        fenced_code_blocks: true,
        autolink: true,
        tables: true,
        no_intra_emphasis: true,
        strikethrough: true,
        highlight: true)
      payload = {}
      info = { :filters => [Jekyll::Filters], :registers => { :site => site, :page => payload['page'] } }
      raw_content = render_liquid(content, payload, info, '.')
      redcarpet.render(raw_content)
    end

  end

end