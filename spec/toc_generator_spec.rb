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

require 'redcarpet'
require 'jekyll'

require_relative '../lib/toc_generator'

describe Pebble::TocGenerator do

  describe '#generate' do

    before do
      @toc = Pebble::TocGenerator.new
    end

    it 'returns empty array on blank document' do
      expect(@toc.generate('')).to eql([])
    end

    it 'returns array of top level headers' do
      document = "# Header 1\n\n#Header 2"
      contents = @toc.generate(document)
      expect(contents.size).to eql(2)
      expect(contents[0][1]).to eql('Header 1')
      expect(contents[1][0]).to eql('header-2')
      expect(contents[1][2]).to eql(1)
    end

    it 'works for any depth of header' do
      document = "# Header 1\n\n#### Header 2\n\n###### Header 3"
      contents = @toc.generate(document)
      expect(contents.size).to eql(3)
      expect(contents[0][2]).to eql(1)
      expect(contents[1][2]).to eql(4)
      expect(contents[2][2]).to eql(6)
    end

    it 'normalises the headers so the smallest is 1' do
      document = "#### Header 1\n\n###### Header 2"
      contents = @toc.generate(document)
      expect(contents.size).to eql(2)
      expect(contents[0][2]).to eql(1)
      expect(contents[1][2]).to eql(3)
    end

  end

end
