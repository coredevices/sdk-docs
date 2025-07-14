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

require 'pygments'

# Liquid block tag to run code through Pygments syntax highlighter.
class Highlight < Liquid::Block
  def initialize(tag_name, markup, tokens)
    super
    options = JSON.parse(markup)
    return unless options
    @language = options['language']
    @classes = options['classes']
    @options = options['options'] || {}
  end

  def render(context)
    str = Pygments.highlight(super.strip, lexer: @language, options: @options)
    str.gsub!(/<div class="highlight"><pre>/,
              "<div class=\"highlight #{@classes}\"><pre>")
    str
  end
end
Liquid::Template.register_tag('highlight', Highlight)
