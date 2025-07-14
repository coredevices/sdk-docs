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

module Jekyll
  class PlatformBlock < Liquid::Block
    alias_method :render_block, :render

    def initialize(tag_name, text, tokens)
      super
      @platform = text.strip
    end

    def render(context)
      if (@platform == "local") || (@platform == "cloudpebble")
        site = context.registers[:site]
        converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
        content = converter.convert(super)

        return "<div class=\"platform-specific\" data-sdk-platform=\"#{@platform}\">#{content}</div>"
      end

      Jekyll.logger.error "Liquid Error:", "Platform '#{@platform}' is not valid. Use 'local' or 'cloudpebble'."
      return ''
    end
  end
end

Liquid::Template.register_tag('platform', Jekyll::PlatformBlock)
