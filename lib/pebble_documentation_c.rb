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

require 'pygments'
require 'nokogiri'
require 'htmlentities'
require_relative 'c_docs/doc_group.rb'

module Pebble
  # Pebble C documentation processing class.
  # Reads doxygen XML from local platform directories.
  class DocumentationC < Documentation
    MASTER_GROUP_IDS = %w(foundation graphics u_i worker standard_c)
    PLATFORMS = %w(aplite basalt emery)

    def initialize(site, source_dir, root, language='c')
      super(site)
      @site = site
      @url_root = root
      @source_dir = source_dir
      @tmp_dir = 'tmp/docs/c'
      @groups = []
      @language = language
      run
    end

    private

    def language
      @language
    end

    def run
      cleanup
      prepare_local_docs
      process
      add_images
    end

    def cleanup
      FileUtils.rmtree @tmp_dir
    end

    def prepare_local_docs
      PLATFORMS.each do |platform|
        src = File.join(@source_dir, platform, 'doxygen_sdk')
        next unless File.directory?(src)
        dst = File.join(@tmp_dir, platform)
        FileUtils.mkdir_p(dst)
        FileUtils.cp_r(File.join(src, 'xml'), File.join(dst, 'xml'))
        html_src = File.join(src, 'html')
        FileUtils.cp_r(html_src, File.join(dst, 'html')) if File.directory?(html_src)
      end
    end

    def process
      DocumentationC::MASTER_GROUP_IDS.each do |id|
        @groups << DocGroup.new(@url_root, @tmp_dir, 'aplite', id)
      end
      @groups.each { |group| group.load_xml('basalt') }
      @groups.each { |group| group.load_xml('emery') }

      mapping = []
      @groups.each { |group| mapping += group.mapping_array }
      @groups.each do |group|
        group.process(mapping, 'aplite')
        group.process(mapping, 'basalt')
        group.process(mapping, 'emery')
      end
      apply_force_latest(@groups)

      add_symbols(@groups)
      @groups.each { |group| @tree << group.to_branch }
      add_pages(@groups)
      add_redirects(mapping)
    end

    def add_images
      move_images('aplite')
      move_images('basalt')
      move_images('emery')
      images = Dir.glob("#{@tmp_dir}/assets/images/**/*.png")
      images.each do |img|
        source = File.join(@site.source, '../tmp/docs/c/')
        if File.exist?(img)
          img.sub!('tmp/docs/c', '')
          @site.static_files << Jekyll::StaticFile.new(@site, source, '', img)
        end
      end
    end

    def move_images(platform)
      images = Dir.glob("#{@tmp_dir}/#{platform}/**/*.png")
      dir = File.join(@tmp_dir, 'assets', 'images', 'docs', 'c', platform)
      FileUtils.mkdir_p(dir)
      images.each do |img|
        FileUtils.cp(img, File.join(dir, File.basename(img)))
      end
    end

    # TODO: Make the groups handle their own subgroups and members etc
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def add_symbols(groups)
      groups.each do |group|
        add_symbol(group.to_symbol)
        group.members.each do |member|
          add_symbol(member.to_symbol)
          member.children.each do |child|
            add_symbol(child.to_symbol)
          end
        end
        group.classes.each do |child|
          add_symbol(child.to_symbol)
          # OPINION: I don't think we want to have struct members as symbols.
          # struct.children.each do |child|
          #   add_symbol(child.to_symbol)
          # end
        end
        add_symbols(group.groups)
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    def add_pages(groups)
      groups.each do |group|
        page = group.to_page(@site)
        page.set_language(@language)
        @pages << page
        add_pages(group.groups)
      end
    end

    def apply_force_latest(groups)
      groups.each do |group|
        group.force_latest!
        apply_force_latest(group.groups)
      end
    end

    def add_redirects(mapping)
      mapping.each do |map|
        next if map[:id].match(/_1/)
        @site.pages << Jekyll::RedirectPage.new(@site, @site.source, @url_root, map[:id] + '.html', map[:url])
      end
    end
  end

  # Jekyll Page subclass for rendering the C documentation pages.
  class PageDocC < Jekyll::Page
    attr_reader :group

    def initialize(site, root, base, dir, group)
      @site = site
      @base = base
      @dir = root
      @name = dir
      @group = group
      process(@name)
      read_yaml(File.join(base, '_layouts', 'docs'), 'c.html')
      data['title'] = @group.name
      data['platforms'] = @group.xml.keys

    end

    def set_language(language)
      data['docs_language'] = language
    end

    def to_liquid(attrs = ATTRIBUTES_FOR_LIQUID)
      super(attrs + %w(group))
    end
  end
end
