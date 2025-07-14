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
  class GeneratorExamples < Generator
    def initialize(_config)
    end

    def generate(site)
      @site = site
      process_tags
      process_languages
      process_hardware_platforms
      @site.data['examples_metadata'] = {
        'tags' => @tags,
        'languages' => @languages,
        'hardware_platforms' => @hardware_platforms
      }
    end

    def process_tags
      @tags = {}
      @site.data['examples'].each do |example|
        next if example['tags'].nil?
        example['tags'].each do |tag|
          @tags[tag] = { 'count' => 0 } unless @tags.has_key?(tag)
          @tags[tag]['count'] += 1
        end
      end
    end

    def process_languages
      @languages = {}
      @site.data['examples'].each do |example|
        next if example['languages'].nil?
        example['languages'].each do |language|
          @languages[language] = { 'count' => 0 } unless @languages.has_key?(language)
          @languages[language]['count'] += 1
        end
      end
    end

    def process_hardware_platforms
      @hardware_platforms = {}
      @site.data['examples'].each do |example|
        next if example['hardware_platforms'].nil?
        example['hardware_platforms'].each do |hw|
          @hardware_platforms[hw] = { 'count' => 0 } unless @hardware_platforms.has_key?(hw)
          @hardware_platforms[hw]['count'] += 1
        end
      end
    end
  end
end
