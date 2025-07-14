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

  class SearchMarkdown < Redcarpet::Render::HTML

    def initialize()
      @contents = Array.new
      @sections = []
      @section = {
        :title => nil,
        :contents => []
      }
      super()
    end

    def get_contents()
      @contents.join(" \n ")
    end

    def get_sections()
      unless @section.nil?
        @sections << @section
      end
      @sections.map do | section |
        section[:contents] = section[:contents].join("\n")
        section
      end
      @sections
    end

    def block_code(code, language)
      ""
    end

    def header(text, header_level)
      unless @section.nil?
        @sections << @section
      end
      @section = {
        :title => text,
        :contents => []
      }
      @contents << text
      ""
    end

    def paragraph(text)
      @contents << text
      @section[:contents] << text
      ""
    end

    def codespan(text)
      text
    end

    def image(link, title, alt_text)
      ""
    end

    def link(link, title, content)
      content
    end

    def list(contents, type)
      @contents << contents
      @section[:contents] << contents
      ""
    end

    def list_item(text, list_type)
      @contents << text
      @section[:contents] << text
      ""
    end

    def autolink(link, link_type)
      link
    end

    def double_emphasis(text)
      text
    end

    def emphasis(text)
      text
    end

    def linebreak()
      ""
    end

    def raw_html(raw_html)
      ""
    end

    def triple_emphasis(text)
      text
    end

    def strikethrough(text)
      text
    end

    def superscript(text)
      text
    end

    def underline(text)
      text
    end

    def highlight(text)
      text
    end

    def quote(text)
      text
    end

    def footnote_ref(number)
      ""
    end

  end

end