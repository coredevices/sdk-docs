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

  class EnvironmentGenerator < Generator

    priority :highest

    def initialize(site)
      # TODO: Figure out how to check for the environment type.
      require 'dotenv'
      Dotenv.load
    end

    def generate(site)
      if !ENV.has_key?('URL') && ENV.has_key?('HEROKU_APP_NAME')
        ENV['URL'] = "https://#{ENV['HEROKU_APP_NAME']}.herokuapp.com"
        ENV['HTTPS_URL'] = "https://#{ENV['HEROKU_APP_NAME']}.herokuapp.com"
      end
      site.data['env'].each do |item|
        if ENV.has_key?(item['env'])
          set_config(site.config, item['config'], ENV[item['env']])
        elsif item.has_key?('default')
          set_config(site.config, item['config'], item['default'])
        end
      end
    end

    private

    # TODO: Rewrite this function to allow for nested keys.
    def set_config(config, key, value)
      config[key] = value
    end

  end

end
