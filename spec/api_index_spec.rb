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

require_relative './spec_helper'
require 'json'
require_relative '../lib/api_index'

describe ApiIndex do
  SITE_URL = 'https://developer.repebble.com'.freeze

  describe '.js_records' do
    let(:records) do
      modules = JSON.parse(File.read('spec/fixtures/js.json'))
      ApiIndex.js_records(modules, '/docs/pebblekit-js/', SITE_URL)
    end

    it 'emits the module and one record per member' do
      names = records.map { |r| r['name'] }
      expect(names.first).to eq('Pebble')
      expect(names).to include('addEventListener', 'sendAppMessage')
    end

    it 'builds signatures, briefs and .md URLs' do
      add = records.find { |r| r['name'] == 'addEventListener' }
      expect(add['kind']).to eq('function')
      expect(add['signature']).to eq('Pebble.addEventListener(event, callback)')
      expect(add['brief']).to start_with('Adds a listener')
      expect(add['url']).to eq("#{SITE_URL}/docs/pebblekit-js/Pebble/#addEventListener")
      expect(add['url_md']).to eq("#{SITE_URL}/docs/pebblekit-js/Pebble.md#addEventListener")
      expect(add['platforms']).to eq(LlmsExport::PLATFORMS)
    end
  end

  describe '.c_records' do
    FakeMember = Struct.new(:name, :kind, :children, :liquid) do
      def to_liquid
        liquid
      end
    end
    FakeGroup = Struct.new(:name, :members, :classes, :liquid) do
      def to_liquid
        liquid
      end
    end
    FakeDocPage = Struct.new(:url, :group)

    let(:function) do
      data = { 'emery' => { 'summary' => '<p>Creates a new <a href="#">Window</a>.</p>',
                            'type' => '<a href="#">Window</a> *', 'params' => [] },
               'aplite' => { 'summary' => '<p>Old brief.</p>', 'type' => 'Window *', 'params' => [] } }
      FakeMember.new('window_create', 'function', [], 'data' => data, 'platforms' => %w(aplite basalt emery))
    end
    let(:enum) do
      value = FakeMember.new('GColorBlack', nil, [], 'data' => { 'aplite' => { 'summary' => 'Black.' } }, 'platforms' => %w(aplite))
      FakeMember.new('GColor', 'enum', [value], 'data' => { 'aplite' => { 'summary' => '' } }, 'platforms' => %w(aplite))
    end
    let(:define) do
      data = { 'basalt' => { 'summary' => 'Maximum.', 'params' => [{ 'name' => 'x' }], 'initializer' => '(x)' } }
      FakeMember.new('MAX_THING', 'define', [], 'data' => data, 'platforms' => %w(basalt emery))
    end
    let(:struct) { FakeMember.new('GRect', 'struct', [], 'data' => { 'emery' => { 'summary' => 'A rectangle.' } }, 'platforms' => %w(emery)) }
    let(:group) do
      FakeGroup.new('Window', [function, enum, define], [struct],
                    'path' => ['User Interface', 'Window'], 'summary' => '<p>The basic building block.</p>', 'platforms' => %w(aplite basalt emery))
    end
    let(:records) do
      ApiIndex.c_records([FakeDocPage.new('/docs/c/User_Interface/Window/index.html', group), Struct.new(:url).new('/other/')], SITE_URL)
    end

    it 'emits group, members, enumerators and structs with platforms' do
      expect(records.map { |r| [r['name'], r['kind']] }).to eq([
        ['Window', 'group'], ['window_create', 'function'], ['GColor', 'enum'], ['GColorBlack', 'enumerator'],
        ['MAX_THING', 'macro'], ['GRect', 'struct'],
      ])
      expect(records[1]['platforms']).to eq(%w(aplite basalt emery))
      expect(records[3]['platforms']).to eq(%w(aplite))
    end

    it 'prefers the newest platform data and strips HTML' do
      expect(records[1]['signature']).to eq('Window * window_create()')
      expect(records[1]['brief']).to eq('Creates a new Window.')
      expect(records[4]['signature']).to eq('#define MAX_THING(x) (x)')
      expect(records[0]['group']).to eq('User Interface / Window')
      expect(records[0]['url']).to eq("#{SITE_URL}/docs/c/User_Interface/Window/")
      expect(records[0]['url_md']).to eq("#{SITE_URL}/docs/c/User_Interface/Window.md")
    end
  end
end
