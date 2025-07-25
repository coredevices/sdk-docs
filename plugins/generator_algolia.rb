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

require 'htmlentities'
require 'algoliasearch'
require 'slugize'
require 'dotenv'
require 'securerandom'

module Jekyll
  class GeneratorAlgolia < Generator
    # Do this last so everything else has been processed already.
    priority :lowest

    def initialize(_config)
      Dotenv.load
    end

    def generate(site)
      @site = site
      return unless check_config?
      @prefix = site.config['algolia_prefix'] || ''
      @random_code = random_code
      Algolia.init(application_id: site.config['algolia_app_id'],
                   api_key: site.config['algolia_api_key'])
      @indexes = setup_indexes
      generate_all
    end

    private

    def check_config?
      if @site.config['algolia_app_id'].nil? || @site.config['algolia_app_id'].empty?
        Jekyll.logger.warn(
          'Config Warning:',
          'You did not provide a ALGOLIA_APP_ID environment variable.'
        )
        return false
      end
      if @site.config['algolia_api_key'].nil? || @site.config['algolia_api_key'].empty?
        Jekyll.logger.warn(
          'Config Warning:',
          'You did not provide a ALGOLIA_API_KEY environment variable.'
        )
        return false
      end
      true
    end

    def generate_all
      generate_blog_posts
      generate_guides
      generate_community_resources
      generate_documentation
      generate_none_guide_guides
      generate_other
    end

    def random_code
      SecureRandom.hex
    end

    def setup_indexes
      indexes = {}
      @site.data['search_indexes'].each do |name, properties|
        index = Algolia::Index.new(@prefix + name)
        unless properties['settings'].nil?
          index.set_settings(properties['settings'])
        end
        indexes[name] = index
      end
      indexes
    end

    def generate_documentation
      return if @site.data['docs'].nil?

      documents = @site.data['docs'][:symbols].map do |item|
        next if item[:language] == 'c_preview'

        if item[:summary].nil? || item[:summary].strip.length == 0
          Jekyll.logger.warn(
            'Search Warning:',
            "There was no summary for the symbol '#{item[:name]}' in #{item[:language]}."
          )
        end
        {
          'objectID'   => item[:url],
          'title'      => item[:name],
          'splitTitle' => item[:name].split(/(?=[A-Z])/).join(' '),
          'url'        => item[:url],
          'summary'    => item[:summary],
          'kind'       => item[:kind],
          'language'   => item[:language],
          'type'       => 'documentation',
          'ranking'    => doc_language_rank[item[:language]] * 1000,
          'randomCode' => @random_code
        }
      end.compact
      @indexes['documentation'].save_objects(documents)
    end

    def generate_community_resources
      resources = %w(community_tools community_apps community_libraries)
      documents = []
      resources.each do | type |
        return nil if @site.collections[type].nil?

        @site.collections[type].docs.each do | resource |
          document = {
            'objectID'   => resource.url,
            'title'      => resource.data['name'],
            'url'        => resource.url,
            'content'    => HTMLEntities.new.decode(resource.get_output),
            'resourceType'       => type,
            'type'       => 'community resource',
            'randomCode' => @random_code
          }
          documents << document
        end
      end

      @indexes['community-resources'].save_objects(documents)
    end

    def generate_blog_posts
      documents = []
      @site.posts.docs.each do | post |
        # Calculate the age of the post so we can prioritise newer posts
        # over older ones.
        # NOTE: post.date is actually a Time object, despite its name
        age = (Time.now - post.date).round
        author = post.data['author']

        post.get_sections.each do | section |
          # Ignore sections without any contents.
          if section[:contents].strip.size == 0
            next
          end

          if section[:title].nil?
            url = post.url
          else
            url = post.url + '#' + section[:title].slugize
          end

          document = {
            'objectID'     => url,
            'title'        => post.data['title'],
            'sectionTitle' => section[:title],
            'url'          => url,
            'urlDisplay'   => post.url,
            'author'       => author,
            'content'      => HTMLEntities.new.decode(section[:contents]),
            'posted'       => post.date,
            'age'          => age,
            'type'         => 'blog post',
            'randomCode'   => @random_code
          }
          documents << document
        end
      end
      @indexes['blog-posts'].save_objects(documents)
    end

    def generate_guides
      documents = []
      return if @site.collections['guides'].nil?

      @site.collections['guides'].docs.each do | guide |
        group = @site.data['guides'][guide.data['guide_group']]
        unless group.nil? || group['subgroups'].nil? || guide.data['guide_subgroup'].nil?
          subgroup = group.nil? ? '' : group['subgroups'][guide.data['guide_subgroup']]
        end

        guide.get_sections.each do | section |
          url = guide.url
          unless section[:title].nil?
            url = url + '#' + section[:title].slugize
          end

          document = {
            'objectID'     => url,
            'title'        => guide.data['title'],
            'sectionTitle' => section[:title],
            'url'          => url,
            'urlDisplay'   => guide.url,
            'content'      => HTMLEntities.new.decode(section[:contents]),
            'group'        => group.nil? ? '' : group['title'],
            'subgroup'     => subgroup.nil? ? '' : subgroup['title'],
            'type'         => 'guide',
            'randomCode'   => @random_code
          }
          documents << document
        end
      end

      @indexes['guides'].save_objects(documents)
    end

    def generate_none_guide_guides
      documents = []
      gs_pages = @site.pages.select { |page| page.data['search_index'] }
      gs_pages.each do |page|
        page.get_sections.each do |section|
          url = page.url
          url = url + '#' + section[:title].slugize unless section[:title].nil?
          document = {
            'objectID'     => url,
            'title'        => page.data['title'],
            'sectionTitle' => section[:title],
            'url'          => url,
            'urlDisplay'   => page.url,
            'content'      => HTMLEntities.new.decode(section[:contents]),
            'group'        => page.data['search_group'],
            'subgroup'     => page.data['sub_group'],
            'type'         => 'not-guide',
            'randomCode'   => @random_code
          }
          documents << document
        end
      end
      @indexes['guides'].save_objects(documents)
    end

    def generate_other
      documents = @site.data['search-other'].map do |other|
        {
            'objectID' => other['id'],
            'title' => other['title'],
            'url' => other['url'],
            'content' => other['description'],
            'randomCode' => @random_code
        }
      end
      @indexes['other'].save_objects(documents)
    end

    def doc_language_rank
      {
          'c' => 10,
          'rockyjs' => 9,
          'pebblekit_js' => 8,
          'pebblekit_android' => 6,
          'pebblekit_ios' => 4
      }
    end
  end
end
