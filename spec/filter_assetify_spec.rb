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

require 'liquid'
require_relative '../plugins/filter_assetify'

describe FilterAssetify, '#assetify' do

  let(:liquid) { Class.new.extend(FilterAssetify) }

  before do
    site = double(Class)
    allow(site).to receive_messages(:config => { 'asset_path' => 'ASSET_PATH' })
    context = double(Liquid::Context)
    allow(context).to receive_messages(:registers => { :site => site })
    liquid.instance_variable_set("@context", context)
  end

  it 'prepends the provided asset_path when needed' do
    expect(liquid.assetify('/images/foo.png')).to eql('ASSET_PATH/images/foo.png')
  end

  it 'does not prepend the provided asset_path when not needed' do
    expect(liquid.assetify('//images/foo.png')).to eql('//images/foo.png')
    expect(liquid.assetify('images/foo.png')).to eql('images/foo.png')
  end

end
