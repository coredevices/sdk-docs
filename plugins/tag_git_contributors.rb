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

# Liquid tag that displays the names of everyone who contributed on the file.
class TagGitContributors < Liquid::Tag
  def initialize(tag_name, text, tokens)
    super
    @text = text
  end

  def render(context)
    list = '<ul class="git-contributors">'
    contributors(context).each do |name|
      list += "<li>#{name}</li>" unless name.empty?
    end
    list += '</ul>'
    list
  end

  private

  def contributors(context)
    site = context.registers[:site]
    page = context[@text]
    file_path = page['relative_path'] || page['path']
    full_path = './' + site.config['source'] + file_path
    names = `git log --follow --format='%aN |' "#{full_path}" | sort -u`
    names.split('|').map { |name| name.strip }
  end
end

Liquid::Template.register_tag('git_contributors', TagGitContributors)
