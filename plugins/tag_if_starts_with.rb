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

class TagIfStartsWith < Liquid::Block
  def initialize(tag_name, text, tokens)
    super
    matches = /^([A-Za-z\.\_\-\/]+) ([A-Za-z\.\_\-\/\']+)$/.match(text.strip)
    @pieces = {
      :outer => matches[1],
      :inner => matches[2]
    }
    @text = text
  end

  def render(context)
    outer = context[@pieces[:outer]]
    inner = context[@pieces[:inner]]
    if inner.nil? || outer.nil?
      return ""
    end
    if outer.downcase.start_with?(inner.downcase)
      return super.to_s.strip
    end
    ""
  end
end
Liquid::Template.register_tag('if_starts_with', TagIfStartsWith)
