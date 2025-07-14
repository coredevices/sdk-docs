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

module FilterHashSort
  def hash_sort(hash, property=nil)
    return [] if hash.nil?
    sorted_hash = []
    hash.each { |key, value| sorted_hash << [key, value] }
    if property.nil?
      sorted_hash.sort! { |a, b| a[0] <=> b[0] }
    else
      sorted_hash.sort! { |a, b| a[1][property] <=> b[1][property] }
    end
    sorted_hash
  end
end

Liquid::Template.register_filter(FilterHashSort)
