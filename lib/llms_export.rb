require 'fileutils'
require 'json'
require 'shellwords'
require 'nokogiri'
require 'reverse_markdown'

module LlmsExport
  SITE_URL = 'https://developer.repebble.com'.freeze
  PLATFORMS = %w(aplite basalt chalk diorite emery flint gabbro).freeze
  ALLOY_PLATFORMS = %w(emery gabbro).freeze

  # The .md twin of a rendered page. /foo/, /foo/index.html and /foo.html
  # all map to /foo.md so "append .md to the URL" works for every page.
  def self.md_path_for(url)
    path = url.to_s.sub(%r{/index\.html\z}, '/')
    return '/index.md' if path == '/'
    return path.chomp('/') + '.md' if path.end_with?('/')
    return path.sub(/\.html\z/, '.md') if path.end_with?('.html')
    path + '.md'
  end

  # Earlier exports wrote the twin of /foo/index.html at /foo/index.md and
  # links to that form exist elsewhere; keep writing it as an alias.
  def self.md_alias_for(url)
    url.to_s.end_with?('/index.html') ? url.to_s.sub(/\.html\z/, '.md') : nil
  end

  # Key under which /foo, /foo/ and /foo/index.html are the same page.
  def self.normalize_path(path)
    key = path.to_s.sub(%r{/index\.html\z}, '/').chomp('/')
    key.empty? ? '/' : key
  end

  def self.sdk_version(site)
    site.data.dig('sdk', 'c', 'version').to_s
  end

  class Builder
    SITE_TITLE = 'Pebble Developer Documentation'.freeze
    SITE_DESCRIPTION = 'Official documentation for building apps for Pebble smartwatches.'.freeze

    # Prefixes that get a concatenated llms-full.txt of every page below them.
    FULL_FILE_PREFIXES = ['/', '/guides/', '/guides/alloy/', '/docs/c/', '/docs/pebblekit-js/'].freeze

    EXCLUDED_URL_PATTERNS = [
      %r{\A/assets/},
      %r{\A/images/},
      %r{\A/css/},
      %r{\A/js/},
      %r{\A/blog/\d+/?\z},
      %r{\A/blog/?\z},
      %r{\A/blog/(tags|authors)/},
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
    # Tutorials listed in llms.txt in this order; any others follow by name.
    TUTORIAL_ORDER = %w(watchface alloy-watchface advanced).freeze

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

    # Before rendering: tell the layout which pages will get a .md twin so it
    # can emit <link rel="alternate" type="text/markdown">. Content-based
    # exclusions are only known after rendering; see strip_alternate_link.
    def self.mark_pages(site)
      candidates = site.pages.dup
      site.collections.each_value { |collection| candidates.concat(collection.docs) }
      candidates.each do |page|
        next if static_exclude?(page)
        page.data['llms_md_path'] = LlmsExport.md_path_for(page.url)
      end
    end

    def self.static_exclude?(page)
      return true if page.data['llms_exclude'] == true
      return true if page.data['layout'] == 'redirect'
      return true if page.data['sitemap'] == false

      url = page.url.to_s
      return true if url.empty?
      return true if EXCLUDED_URL_PATTERNS.any? { |pattern| url.match?(pattern) }
      return true unless url == '/' || url.end_with?('/') || url.end_with?('.html')

      false
    end

    # Absolute URL of the .md twin for an internal page URL, or nil when the
    # page has none. Used by the API index so it never advertises a dead link.
    def md_url_for(url)
      target = @emitted && @emitted[LlmsExport.normalize_path(url)]
      target && absolute_url(LlmsExport.md_path_for(target))
    end

    def run
      collect_pages
      Jekyll.logger.info('LLMS Export:', "#{@pages.size} pages eligible")
      discover_sections
      emit_per_page_markdown
      emit_index
      emit_full_files
    end

    private

    def collect_pages
      candidates = @site.pages.dup
      @site.collections.each_value { |collection| candidates.concat(collection.docs) }
      @pages = candidates.reject { |page| exclude?(page) }
      register_emitted(@pages)
    end

    def register_emitted(pages)
      @emitted = pages.each_with_object({}) do |page, map|
        map[LlmsExport.normalize_path(page.url)] = page.url
      end
    end

    def exclude?(page)
      return true if self.class.static_exclude?(page)
      return true if page.output.to_s.strip.empty?
      node = main_node(page)
      if node.nil? || node.text.strip.length < 100
        strip_alternate_link(page)
        return true
      end

      false
    end

    def strip_alternate_link(page)
      return unless page.output.is_a?(String)
      page.output = page.output.sub(%r{\s*<link rel="alternate" type="text/markdown"[^>]*>}, '')
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
        next if markdown.nil?
        content = front_matter(page) + markdown
        write_static_file(LlmsExport.md_path_for(page.url), content)
        alias_path = LlmsExport.md_alias_for(page.url)
        write_static_file(alias_path, content) if alias_path
      end
    end

    def front_matter(page)
      <<~YAML
        ---
        title: #{extract_title(page).to_s.to_json}
        canonical_url: #{canonical_url(page)}
        last_updated: #{last_updated(page)}
        sdk_version: #{LlmsExport.sdk_version(@site)}
        ---
      YAML
    end

    # Date of the last commit touching the page's source file, or the build
    # date for generated pages and when git history is unavailable.
    def last_updated(page)
      path = page.respond_to?(:relative_path) ? File.join('source', page.relative_path.to_s) : nil
      (path && git_dates[path]) || @site.time.strftime('%Y-%m-%d')
    end

    def git_dates
      @git_dates ||= begin
        root = File.expand_path('..', @site.source)
        log = `git -C #{Shellwords.escape(root)} log --format=%x01%cs --name-only -- source 2>/dev/null`
        dates = {}
        current = nil
        log.each_line do |line|
          line = line.strip
          next if line.empty?
          if line.start_with?("\x01")
            current = line[1..]
          else
            dates[line] ||= current
          end
        end
        dates
      end
    end

    # Body markdown for a page: title, source URL and converted content.
    # Memoized because the .md twin and the llms-full.txt files share it.
    def page_to_markdown(page)
      @markdowns ||= {}
      return @markdowns[page.url] if @markdowns.key?(page.url)
      @markdowns[page.url] = build_page_markdown(page)
    end

    def build_page_markdown(page)
      node = main_node(page)
      return nil if node.nil?
      rewrite_internal_links(node)
      # Newlines inside running text are spaces in HTML; ReverseMarkdown drops
      # them, which glues words to the links that follow ("enable the[link]").
      node.xpath('.//text()[not(ancestor::pre)]').each do |text|
        next unless text.content.include?("\n") && text.content.match?(/\S/)
        text.content = text.content.gsub(/\s*\n\s*/, ' ')
      end
      html = node.inner_html
      return nil if html.strip.empty?

      body = ReverseMarkdown.convert(html, unknown_tags: :bypass, github_flavored: true)
      body = body.gsub(/\n{3,}/, "\n\n").strip
      return nil if body.empty?

      <<~MARKDOWN
        # #{extract_title(page)}

        Source: #{canonical_url(page)}

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

    # Make every internal link and image absolute so the .md file reads the
    # same from anywhere; links to pages with a .md twin point to the twin.
    def rewrite_internal_links(node)
      node.css('a[href]').each do |anchor|
        rewritten = rewrite_href(anchor['href'])
        anchor['href'] = rewritten if rewritten
      end
      node.css('img[src]').each do |img|
        rewritten = rewrite_href(img['src'])
        img['src'] = rewritten if rewritten
      end
    end

    # Internal /foo, /foo/ and /foo/index.html all resolve to the same page.
    def rewrite_href(href)
      return nil if href.nil? || href.empty?

      path, fragment, = extract_internal_path(href)
      return nil if path.nil?

      target = @emitted[LlmsExport.normalize_path(path)]
      path = LlmsExport.md_path_for(target) if target
      "#{@base_url}#{path}#{fragment}"
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

    def canonical_url(page)
      absolute_url(page.url.to_s.sub(%r{/index\.html\z}, '/'))
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
      lines = []
      lines << "# #{SITE_TITLE}"
      lines << ''
      lines << "> #{SITE_DESCRIPTION}"
      lines << ''
      lines << instructions

      sections.each do |title, sub_groups|
        render_section(lines, title, sub_groups)
      end

      write_static_file('/llms.txt', lines.join("\n") + "\n")
    end

    def instructions
      version = LlmsExport.sdk_version(@site)
      <<~TEXT.strip
        Most guide and reference pages on this site have a Markdown version: replace the trailing `/` or `/index.html` of the page URL with `.md` (for example `#{@base_url}/guides/events-and-services/buttons.md`). Fetch the `.md` version when reading a page; the links below already point to it. `#{@base_url}/llms-full.txt` holds every page in one file, and `/guides/llms-full.txt`, `/guides/alloy/llms-full.txt`, `/docs/c/llms-full.txt` and `/docs/pebblekit-js/llms-full.txt` hold one section each. `#{@base_url}/api-index.json` lists every C and PebbleKit JS symbol with its platforms and page.

        The current SDK version is #{version}. The target platforms are #{PLATFORMS.join(', ')}. Alloy (JavaScript on the watch) runs on #{ALLOY_PLATFORMS.join(' and ')} only. Rocky.js has been removed from the SDK. The timeline web API is no longer available: the Pebble mobile app does not sync pins from a server, so use local pins instead.
      TEXT
    end

    # [[section title, [[sub title, pages]]]] in index order. Blog goes last
    # so posts do not sit between the reference sections and the rest.
    def sections
      @sections ||= begin
        buckets = bucket_pages_by_section
        section_render_order.filter_map do |key|
          pages = buckets[key]
          next if pages.nil? || pages.empty?
          [@section_titles[key] || humanize(key), sub_group(pages)]
        end
      end
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
      (known + extra.sort + [UNCATEGORIZED_KEY]).partition { |key| key != 'blog' }.flatten
    end

    # One llms-full.txt per prefix: every page below it, in index order.
    def emit_full_files
      ordered = sections.flat_map { |_, subs| subs.flat_map { |_, pages| pages } }
      FULL_FILE_PREFIXES.each do |prefix|
        pages = ordered.select { |page| page.url.start_with?(prefix) }
        bodies = pages.filter_map { |page| page_to_markdown(page) }
        next if bodies.empty?
        header = "# #{SITE_TITLE}#{prefix == '/' ? '' : ": #{prefix}"}\n\n" \
                 "SDK #{LlmsExport.sdk_version(@site)}. #{bodies.size} pages. " \
                 "Index: #{@base_url}/llms.txt\n\n"
        write_static_file("#{prefix}llms-full.txt", header + bodies.join("\n\n---\n\n"))
      end
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

    def render_section(lines, title, sub_groups)
      lines << ''
      lines << "## #{title}"

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
      return tutorials_sub_group(pages)        if pages.any? { |page| page.data['tutorial'] }
      return guides_sub_group(pages)           if pages.any? { |page| page.data['guide_group'] }
      return docs_language_sub_group(pages)    if pages.any? { |page| page.data['docs_language'] }
      return mixed_collection_sub_group(pages) if mixed_collections?(pages)
      return menu_subsection_sub_group(pages)  if pages.any? { |page| page.data['menu_subsection'] }
      [['', sort_default(pages)]]
    end

    # Tutorials: the section index first, then one tutorial at a time in
    # TUTORIAL_ORDER with parts in order, so parts of different tutorials
    # that share a title do not interleave.
    def tutorials_sub_group(pages)
      sorted = pages.sort_by do |page|
        tutorial = page.data['tutorial'].to_s
        rank = tutorial.empty? ? -1 : (TUTORIAL_ORDER.index(tutorial) || TUTORIAL_ORDER.size)
        [rank, tutorial, page.data['tutorial_part'].to_i, extract_title(page).to_s.downcase]
      end
      [['', sorted]]
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
      url = absolute_url(LlmsExport.md_path_for(page.url))
      description = entry_description(page)
      date_suffix = with_date && page.data['date'] ? " — #{page.data['date'].strftime('%Y-%m-%d')}" : ''

      if description.empty?
        "- [#{title}](#{url})#{date_suffix}"
      else
        "- [#{title}](#{url}): #{description}#{date_suffix}"
      end
    end

    # Front matter description first; for C API pages the doxygen group
    # brief; otherwise the first sentence of the first paragraph.
    def entry_description(page)
      explicit = page.data['description'].to_s.gsub(/\s+/, ' ').strip
      return explicit unless explicit.empty?

      # C API pages: the doxygen group brief, or nothing. The first paragraph
      # of a group page is a member's docstring, not a description.
      if page.respond_to?(:group) && page.group.respond_to?(:to_liquid)
        return Nokogiri::HTML.fragment(page.group.to_liquid['summary'].to_s).text.gsub(/\s+/, ' ').strip
      end

      node = main_node(page)
      paragraph = node&.at_css('p')&.text&.gsub(/\s+/, ' ')&.strip.to_s
      return '' if paragraph.empty?

      first_sentence = paragraph.split(/(?<=[.!?])\s/).first.to_s.strip
      first_sentence.length > 140 ? first_sentence[0, 137] + '...' : first_sentence
    end
  end
end
