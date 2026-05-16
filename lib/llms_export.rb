require 'fileutils'
require 'set'
require 'nokogiri'
require 'reverse_markdown'

module LlmsExport
  class Builder
    SITE_TITLE = 'Pebble Developer Documentation'.freeze
    SITE_DESCRIPTION = 'Official documentation for building apps for Pebble smartwatches.'.freeze

    EXCLUDED_URL_PATTERNS = [
      %r{\A/assets/},
      %r{\A/images/},
      %r{\A/css/},
      %r{\A/js/},
      %r{\A/blog/\d+/?\z},
      %r{\A/search/?\z},
      %r{sitemap\.xml\z},
      %r{robots\.txt\z},
      %r{\.xml\z},
      %r{\.json\z},
      %r{\.css\z},
      %r{\.js\z},
      %r{\A/404(\.html)?\z},
    ].freeze

    UNCATEGORIZED_KEY = '_uncategorized'.freeze

    CHROME_SELECTORS = [
      '.search', '.quicksearch', '#search__blackout',
      '.gray-box', '#disqus_thread', '.pagetitle',
      '.hidden-l', '.visible-m', '.visible-s', '.visible-xs',
      '[role="navigation"]', 'nav', 'script', 'style', 'noscript',
    ].join(', ').freeze

    def initialize(site)
      @site = site
      @base_url = site.config['url'] || ''
      @tmp_root = File.join(site.source, '../tmp/llms-export/')
      @pages = []
      @section_order = []
      @section_titles = {}
      @main_nodes = {}
    end

    def run
      collect_pages
      Jekyll.logger.info('LLMS Export:', "#{@pages.size} pages eligible")
      @emitted_urls = @pages.map(&:url).to_set
      discover_sections
      emit_per_page_markdown
      emit_index
    end

    private

    def collect_pages
      candidates = @site.pages.dup
      @site.collections.each_value { |collection| candidates.concat(collection.docs) }
      @pages = candidates.reject { |page| exclude?(page) }
    end

    def exclude?(page)
      return true if page.data['llms_exclude'] == true
      return true if page.data['layout'] == 'redirect'
      return true if page.data['sitemap'] == false

      url = page.url.to_s
      return true if url.empty?
      return true if EXCLUDED_URL_PATTERNS.any? { |pattern| url.match?(pattern) }
      return true unless url == '/' || url.end_with?('/') || url.end_with?('.html')

      return true if page.output.to_s.strip.empty?
      node = main_node(page)
      return true if node.nil? || node.text.strip.length < 100

      false
    end

    # Parse the rendered mainmenu HTML on a sample page to learn the canonical
    # section keys, display titles, and order — the same nav humans see. The
    # key comes from the link's first URL segment (matching `menu_section`
    # values set in layouts), not the CSS class, since the classes use legacy
    # names that don't match (e.g. "getting-started" for "/tutorials/").
    def discover_sections
      sample = @pages.find { |page| (page.output || '').include?('mainmenu__item') }
      return unless sample

      doc = Nokogiri::HTML(sample.output)
      items = doc.css('.mainmenu .mainmenu__item, ul.mainmenu > li.mainmenu__item')
      items.each do |item|
        anchor = item.at_css('a')
        next unless anchor
        href = anchor['href'].to_s
        key = nil
        unless href.empty? || href.start_with?('http')
          key = href.split('/').reject(&:empty?).first
        end
        if key.nil? || key.empty?
          match = item['class'].to_s.match(/mainmenu__item--(\S+)/)
          key = match && match[1]
        end
        next if key.nil? || key.empty?
        label = item.at_css('span')&.text&.strip
        @section_order << key unless @section_order.include?(key)
        @section_titles[key] = label && !label.empty? ? label : humanize(key)
      end
    end

    def emit_per_page_markdown
      @pages.each do |page|
        markdown = page_to_markdown(page)
        next if markdown.nil? || markdown.empty?
        write_static_file(md_path_for(page.url), markdown)
      end
    end

    def md_path_for(url)
      return '/index.md' if url == '/'
      return url.chomp('/') + '.md' if url.end_with?('/')
      return url.sub(/\.html\z/, '.md') if url.end_with?('.html')
      url + '.md'
    end

    def page_to_markdown(page)
      node = main_node(page)
      return nil if node.nil?
      rewrite_internal_links(node)
      html = node.inner_html
      return nil if html.strip.empty?

      body = ReverseMarkdown.convert(html, unknown_tags: :bypass, github_flavored: true)
      body = body.gsub(/\n{3,}/, "\n\n").strip
      return nil if body.empty?

      <<~MARKDOWN
        # #{extract_title(page)}

        Source: #{absolute_url(page.url)}

        #{body}
      MARKDOWN
    end

    # The chrome-stripped main content node for a page, memoized so the
    # exclude check, MD conversion, and description extraction share one
    # Nokogiri parse instead of three.
    def main_node(page)
      key = page.url
      return @main_nodes[key] if @main_nodes.key?(key)
      @main_nodes[key] = build_main_node(page.output)
    end

    def build_main_node(output)
      return nil if output.nil? || output.empty?
      doc = Nokogiri::HTML(output)
      content_node = doc.at_css('.content')
      return nil unless content_node

      content_node.css(CHROME_SELECTORS).each(&:remove)
      content_node.at_css('.col-l-8') ||
        content_node.at_css('.container') ||
        content_node
    end

    # Rewrite <a href> values that point to an emitted page so the .md
    # version links to other .md versions. Preserves fragments and the
    # original absolute/relative form.
    def rewrite_internal_links(node)
      node.css('a[href]').each do |anchor|
        rewritten = rewrite_href(anchor['href'])
        anchor['href'] = rewritten if rewritten
      end
    end

    def rewrite_href(href)
      return nil if href.nil? || href.empty?

      path, fragment, had_absolute_prefix = extract_internal_path(href)
      return nil if path.nil?

      target = @emitted_urls.include?(path) ? path : "#{path}/"
      return nil unless @emitted_urls.include?(target)

      md_path = md_path_for(target)
      had_absolute_prefix ? "#{@base_url}#{md_path}#{fragment}" : "#{md_path}#{fragment}"
    end

    # Returns [path, fragment, had_absolute_prefix] for an internal URL, or
    # nils for external/invalid. Accepts root-relative paths, absolute URLs
    # whose host matches an internal alias, and protocol-relative URLs.
    def extract_internal_path(href)
      path = nil
      had_absolute_prefix = false

      if href.start_with?('/') && !href.start_with?('//')
        path = href
      elsif (match = href.match(%r{\A(https?:)?//([^/]+)(/.*)?\z}i))
        return [nil, nil, false] unless internal_hosts.include?(match[2].downcase)
        path = match[3] || '/'
        had_absolute_prefix = true
      else
        return [nil, nil, false]
      end

      fragment = ''
      if (idx = path.index(/[#?]/))
        fragment = path[idx..]
        path = path[0, idx]
      end
      return [nil, nil, false] if path.empty?
      [path, fragment, had_absolute_prefix]
    end

    # Hosts treated as the same site for link-rewriting purposes. Derived
    # from site config (URL / HTTPS_URL) plus any path prefix that looks
    # like a hostname in unfiltered site.pages — that's how the redirects
    # plugin registers legacy aliases (pages at /<host>/<orig-path>/).
    def internal_hosts
      @internal_hosts ||= begin
        from_config = [@base_url, @site.config['https_url']]
                        .compact
                        .map { |url| url.to_s[%r{\Ahttps?://([^/]+)}i, 1] }
                        .compact
        from_pages = @site.pages
                          .map { |page| page.url.to_s.split('/').reject(&:empty?).first }
                          .compact
                          .select { |segment| segment.match?(/\.[a-z]+\z/i) }
                          .uniq
        (from_config + from_pages).map(&:downcase).uniq
      end
    end

    def extract_title(page)
      explicit = page.data['title'] || page.data['name']
      return explicit if explicit && !explicit.to_s.strip.empty?
      return 'Home' if page.url == '/'
      basename = File.basename(page.url, '.*')
      basename.empty? ? 'Untitled' : basename
    end

    def absolute_url(path)
      "#{@base_url}#{path}"
    end

    def write_static_file(rel_path, content)
      dest_path = File.join(@tmp_root, rel_path)
      FileUtils.mkdir_p(File.dirname(dest_path))
      File.write(dest_path, content)

      dir = File.dirname(rel_path).sub(%r{\A/}, '')
      dir = '' if dir == '.'
      @site.static_files << Jekyll::StaticFile.new(@site, @tmp_root, dir, File.basename(rel_path))
    end

    def emit_index
      buckets = bucket_pages_by_section
      lines = []
      lines << "# #{SITE_TITLE}"
      lines << ''
      lines << "> #{SITE_DESCRIPTION}"

      section_render_order.each do |section_key|
        pages = buckets[section_key]
        next if pages.nil? || pages.empty?
        render_section(lines, @section_titles[section_key] || humanize(section_key), pages)
      end

      write_static_file('/llms.txt', lines.join("\n") + "\n")
    end

    def section_render_order
      known = @section_order.dup
      extra = []
      @pages.each do |page|
        key = effective_menu_section(page)
        next if known.include?(key) || extra.include?(key)
        extra << key
      end
      extra.delete(UNCATEGORIZED_KEY)
      known + extra.sort + [UNCATEGORIZED_KEY]
    end

    def bucket_pages_by_section
      buckets = Hash.new { |hash, key| hash[key] = [] }
      @pages.each do |page|
        buckets[effective_menu_section(page)] << page
      end
      buckets
    end

    # Resolve a page's section using (in order):
    #   1. page front matter `menu_section`
    #   2. the layout chain — walk page.layout → layout.layout, taking the
    #      first menu_section found
    #   3. UNCATEGORIZED_KEY (URL segment fallback is intentionally avoided
    #      so that one-off legacy pages don't spawn singleton sections)
    def effective_menu_section(page)
      explicit = page.data['menu_section']
      return explicit if explicit && explicit.to_s != '' && explicit.to_s != 'none'

      section_from_layout_chain(page.data['layout']) || UNCATEGORIZED_KEY
    end

    def section_from_layout_chain(layout_name, seen = [])
      return nil if layout_name.nil? || seen.include?(layout_name)
      seen << layout_name
      layout = @site.layouts[layout_name]
      return nil unless layout
      value = layout.data['menu_section']
      return value if value && value.to_s != '' && value.to_s != 'none'
      section_from_layout_chain(layout.data['layout'], seen)
    end

    def render_section(lines, title, pages)
      lines << ''
      lines << "## #{title}"

      sub_groups = sub_group(pages)
      sub_groups.each do |sub_title, sub_pages|
        next if sub_pages.empty?
        if sub_title.empty?
          lines << ''
        else
          lines << ''
          lines << "### #{sub_title}"
        end
        sub_pages.each { |page| lines << format_entry(page, with_date: emit_date?(sub_pages)) }
      end
    end

    # Detect the right sub-grouping for a section's pages based on front
    # matter signals — no hardcoded section knowledge. Order matters: more
    # specific signals take priority. Collection-based grouping outranks
    # menu_subsection so a single tagged page doesn't override a large
    # collection-vs-loose split (e.g. SDK pages + changelogs collection).
    def sub_group(pages)
      return guides_sub_group(pages)           if pages.any? { |page| page.data['guide_group'] }
      return docs_language_sub_group(pages)    if pages.any? { |page| page.data['docs_language'] }
      return mixed_collection_sub_group(pages) if mixed_collections?(pages)
      return menu_subsection_sub_group(pages)  if pages.any? { |page| page.data['menu_subsection'] }
      [['', sort_default(pages)]]
    end

    # Guides: categories from _data/guide-categories.yaml, then groups from
    # _data/guides.yaml, then pages sorted by each group's sort_by.
    def guides_sub_group(pages)
      categories = @site.data['guide-categories'] || []
      guides_meta = @site.data['guides'] || {}

      pages_by_group = pages.group_by { |page| page.data['guide_group'] }
      result = []

      categories.each do |category|
        category_groups = guides_meta.select { |_, meta| meta['category'] == category['id'] }
        category_pages_groups = []
        category_groups.each do |group_key, group_meta|
          group_pages = pages_by_group[group_key] || []
          next if group_pages.empty?
          sort_key = (group_meta['sort_by'] || 'title').to_s
          sorted = group_pages.sort_by { |page| (page.data[sort_key] || page.data['title'] || '').to_s }
          category_pages_groups.concat(sorted)
        end
        next if category_pages_groups.empty?
        result << [category['title'].to_s, category_pages_groups]
      end

      # Uncategorized groups (any guide_group not declared in guides.yaml)
      uncategorized = pages_by_group.reject { |group, _| guides_meta.key?(group) }.values.flatten
      result << ['Other Guides', sort_default(uncategorized)] unless uncategorized.empty?
      result
    end

    # API docs: bucket by `docs_language`, use the language landing page's
    # title as the display title.
    def docs_language_sub_group(pages)
      by_language = Hash.new { |hash, key| hash[key] = [] }
      pages.each { |page| by_language[page.data['docs_language'] || 'other'] << page }

      ordered_keys = order_keys_by_first_seen(pages, 'docs_language', by_language.keys)
      ordered_keys.map do |language_key|
        [docs_language_title(language_key), sort_default(by_language[language_key])]
      end
    end

    # Look up the docs_language landing page (e.g. /docs/c/, /docs/pebblekit-js/)
    # and use its title, stripped of a trailing " Documentation" if present.
    def docs_language_title(language_key)
      landing_url = "/docs/#{language_key.to_s.tr('_', '-')}/"
      landing = @pages.find { |page| page.url == landing_url }
      title = landing&.data&.dig('title')&.to_s&.sub(/\s+Documentation\z/i, '')
      title && !title.empty? ? title : humanize(language_key)
    end

    def menu_subsection_sub_group(pages)
      meaningful = ->(value) { value && !value.to_s.empty? && value.to_s != 'none' }
      by_sub = Hash.new { |hash, key| hash[key] = [] }
      pages.each do |page|
        sub = page.data['menu_subsection']
        next unless meaningful.call(sub)
        by_sub[sub.to_s] << page
      end

      with_sub = pages.select { |page| meaningful.call(page.data['menu_subsection']) }
      ordered_keys = order_keys_by_first_seen(with_sub, 'menu_subsection', by_sub.keys)
      result = ordered_keys.map { |sub_key| [humanize(sub_key), sort_default(by_sub[sub_key])] }

      orphans = pages - with_sub
      result.unshift(['', sort_default(orphans)]) unless orphans.empty?
      result
    end

    # Pages that span multiple collections (or mix collection + loose pages):
    # render loose pages first (further split by menu_subsection if signals
    # exist), then one sub-section per collection. Loose pages whose
    # menu_subsection matches a collection's suffix (e.g. menu_subsection:
    # tools ↔ collection community_tools) are folded into that collection.
    def mixed_collection_sub_group(pages)
      loose = pages.select { |page| collection_label(page).nil? }
      collection_pages = pages.reject { |page| collection_label(page).nil? }
      by_collection = collection_pages.group_by { |page| collection_label(page) }

      remaining = []
      loose.each do |page|
        sub = page.data['menu_subsection'].to_s
        match = by_collection.keys.find do |label|
          !sub.empty? && (label == sub || label.end_with?("_#{sub}"))
        end
        match ? (by_collection[match] << page) : remaining << page
      end

      result = []
      unless remaining.empty?
        if remaining.any? { |page| page.data['menu_subsection'] }
          result.concat(menu_subsection_sub_group(remaining))
        else
          result << ['', sort_default(remaining)]
        end
      end
      by_collection.each do |label, items|
        result << [humanize(label), sort_default(items)]
      end
      result
    end

    def mixed_collections?(pages)
      labels = pages.map { |page| collection_label(page) }
      labels.compact.uniq.size > 1 || (labels.any?(&:nil?) && labels.any? { |l| !l.nil? })
    end

    def collection_label(page)
      return nil unless page.respond_to?(:collection) && page.collection
      page.collection.label
    end

    # Preserve original key order for stable rendering.
    def order_keys_by_first_seen(pages, field, all_keys)
      seen = []
      pages.each do |page|
        value = page.data[field]
        next if value.nil? || value.to_s.empty?
        seen << value.to_s unless seen.include?(value.to_s)
      end
      (seen + all_keys.map(&:to_s)).uniq
    end

    def sort_default(pages)
      return pages if pages.empty?
      if pages.all? { |page| page.data['date'] }
        return pages.sort_by { |page| page.data['date'] }.reverse
      end
      pages.sort_by { |page| extract_title(page).to_s.downcase }
    end

    def emit_date?(pages)
      dates = pages.map { |page| page.data['date'] }.compact
      dates.size >= 2 && dates.uniq.size >= 2
    end

    def humanize(key)
      key.to_s.tr('_-', '  ').split.map(&:capitalize).join(' ')
    end

    def format_entry(page, with_date: false)
      title = extract_title(page)
      url = absolute_url(md_path_for(page.url))
      description = entry_description(page)
      date_suffix = with_date && page.data['date'] ? " — #{page.data['date'].strftime('%Y-%m-%d')}" : ''

      if description.empty?
        "- [#{title}](#{url})#{date_suffix}"
      else
        "- [#{title}](#{url}): #{description}#{date_suffix}"
      end
    end

    def entry_description(page)
      explicit = page.data['description'].to_s.gsub(/\s+/, ' ').strip
      return explicit unless explicit.empty?

      node = main_node(page)
      paragraph = node&.at_css('p')&.text&.gsub(/\s+/, ' ')&.strip.to_s
      return '' if paragraph.empty?

      first_sentence = paragraph.split(/(?<=[.!?])\s/).first.to_s.strip
      first_sentence.length > 140 ? first_sentence[0, 137] + '...' : first_sentence
    end
  end
end
