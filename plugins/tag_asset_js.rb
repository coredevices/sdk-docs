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

# Liquid tag for including a script tag.
class TagAssetJs < Liquid::Tag
  def initialize(tag_name, text, tokens)
    super
    @text = text
  end

  def render(context)
    script = context[@text]
    site = context.registers[:site]
    unless %r{^//}.match(script)
      script = "#{site.config['asset_path']}/js/#{script}.js"
    end
    "<script type=\"text/javascript\" src=\"#{script}\"></script>"
  end
end
Liquid::Template.register_tag('asset_js', TagAssetJs)
