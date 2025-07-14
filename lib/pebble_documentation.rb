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
  class Documentation
    LANGUAGE = ''
    def initialize(site)
      @site = site
      @symbols = []
      @pages = []
      @tree = []
    end

    def load_symbols(symbols)
      symbols.concat(@symbols)
    end

    def create_pages(pages)
      pages.concat(@pages)
    end

    def build_tree(tree)
      tree.concat(@tree)
    end

    private

    def add_symbol(symbol)
      symbol[:language] = language
      symbol[:summary] = symbol[:summary].strip unless symbol[:summary].nil?
      @symbols << symbol
    end

    def language
      LANGUAGE
    end
  end
end
