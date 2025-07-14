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

class TagImportJs < Liquid::Tag

  def initialize(tag_name, text, tokens)
    super
    @text = text
  end

  def render(context)
    site = context.registers[:site]
    filename = File.join(site.source, "_js", @text).strip
    File.read(filename)
  end
end

Liquid::Template.register_tag('import_js', TagImportJs)

