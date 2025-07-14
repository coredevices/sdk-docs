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

require 'simplecov'
SimpleCov.start

require 'dotenv'
Dotenv.load

require 'open-uri'

if OpenURI::Buffer.const_defined?('StringMax')
  OpenURI::Buffer.send :remove_const, 'StringMax'
end
OpenURI::Buffer.const_set 'StringMax', 0

RSpec.configure do |config|
  config.fail_fast = true
  config.formatter = :documentation
  config.color = true
end
