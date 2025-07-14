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

require_relative '../lib/toc_generator'

# Overriding the Jekyll Page class to do magic

module Jekyll

  class Page

    def to_liquid(attrs = ATTRIBUTES_FOR_LIQUID)
      super(attrs + %w[
        toc
      ])
    end

    private

    def toc
      unless @toc
        generate_toc if data['generate_toc']
      end
      (@toc.nil? || @toc.empty?) ? nil : @toc
    end

    def generate_toc
      generator = Pebble::TocGenerator.new(data['toc_max_depth'] || -1)
      @toc = generator.generate(content)
    end

  end

end
