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

# FilterAssetify is a Liquid filter to prepend the asset_path when needed
module FilterAssetify
  def assetify(input)
    asset_path = @context.registers[:site].config['asset_path']
    %r{^/[^/]}.match(input) ? (asset_path + input) : input
  end
end

Liquid::Template.register_filter(FilterAssetify)
