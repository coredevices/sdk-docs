require 'json'
require 'fileutils'
require 'nokogiri'
require_relative 'llms_export'

# Builds /api-index.json: one record per public symbol in the C SDK and
# PebbleKit JS references, with the page (HTML and .md) that documents it.
module ApiIndex
  # Doxygen is built for these platforms only; a symbol's `platforms` lists
  # the ones whose build contains it (see Pebble::DocumentationC::PLATFORMS).
  C_PLATFORM_ORDER = %w(emery basalt aplite).freeze
  C_KINDS = { 'define' => 'macro' }.freeze

  module_function

  # Records for every C documentation page (Pebble::PageDocC) in `pages`.
  # `md_url_for` maps a page URL to its .md twin, or nil when there is none.
  def c_records(pages, site_url, md_url_for)
    pages.select { |page| page.respond_to?(:group) && page.group.respond_to?(:members) }.flat_map do |page|
      group_records(page.group, page.url, site_url, md_url_for)
    end
  end

  def group_records(group, page_url, site_url, md_url_for)
    liquid = group.to_liquid
    group_name = Array(liquid['path']).join(' / ')
    url = "#{site_url}#{LlmsExport.normalize_path(page_url)}/"
    url_md = md_url_for.call(page_url)
    records = []

    records << record(group.name, 'group', group.name, liquid['summary'], liquid['platforms'], group_name, url, url_md)

    group.members.each do |member|
      data = member.to_liquid
      kind = C_KINDS.fetch(member.kind, member.kind)
      records << record(member.name, kind, c_signature(member.kind, member.name, data), platform_data(data, 'summary'),
                        data['platforms'], group_name, url, url_md)
      next unless member.kind == 'enum'
      member.children.each do |value|
        value_data = value.to_liquid
        records << record(value.name, 'enumerator', value.name, platform_data(value_data, 'summary'),
                          value_data['platforms'], group_name, url, url_md)
      end
    end

    group.classes.each do |cls|
      data = cls.to_liquid
      records << record(cls.name, cls.kind, "#{cls.kind} #{cls.name}", platform_data(data, 'summary'),
                        data['platforms'], group_name, url, url_md)
    end

    records
  end

  def c_signature(kind, name, data)
    type = text(platform_data(data, 'type'))
    params = Array(platform_data(data, 'params')).map { |p| [text(p['type']), p['name']].reject { |s| s.to_s.empty? }.join(' ') }
    case kind
    when 'function' then "#{type} #{name}(#{params.join(', ')})".strip
    when 'define'
      # Doxygen emits <param> elements for function-like macros only.
      arglist = params.empty? ? '' : "(#{params.join(', ')})"
      initializer = text(platform_data(data, 'initializer'))
      "#define #{name}#{arglist}#{initializer.empty? ? '' : " #{initializer}"}"
    when 'typedef' then "typedef #{type} #{name}#{text(platform_data(data, 'argsstring'))}".squeeze(' ')
    when 'enum' then "enum #{name}"
    else name
    end
  end

  # Value of `key` from the newest platform that documents the symbol.
  def platform_data(liquid, key)
    data = liquid['data'] || {}
    C_PLATFORM_ORDER.each do |platform|
      value = data.dig(platform, key)
      return value unless value.nil? || value == ''
    end
    nil
  end

  # Records for a documentation.js JSON dump (source/_data/jsdocs-pkjs.json),
  # one module per array entry; `root` is the URL prefix of its pages.
  def js_records(modules, root, site_url, md_url_for)
    Array(modules).flat_map do |mod|
      page_url = "#{root}#{mod['name']}/"
      url = "#{site_url}#{page_url}"
      url_md = md_url_for.call(page_url)
      records = [record(mod['name'], mod['kind'] || 'namespace', mod['name'], mdast_text(mod['description']),
                        LlmsExport::PLATFORMS, mod['name'], url, url_md)]
      (mod['members'] || {}).each do |scope, members|
        members.each do |member|
          kind = scope == 'events' ? 'event' : (member['kind'] || 'member')
          records << record(member['name'], kind, js_signature(mod['name'], kind, member), mdast_text(member['description']),
                            LlmsExport::PLATFORMS, mod['name'], "#{url}##{member['name']}",
                            url_md && "#{url_md}##{member['name']}")
        end
      end
      records
    end
  end

  def js_signature(module_name, kind, member)
    params = Array(member['params']).map { |p| p['name'] }.join(', ')
    case kind
    when 'function' then "#{module_name}.#{member['name']}(#{params})"
    when 'event' then "#{module_name}.on('#{member['name']}', callback)"
    when 'typedef' then "#{member['name']}: #{member.dig('type', 'name') || 'Object'}"
    else "#{module_name}.#{member['name']}"
    end
  end

  # First paragraph of a remark/mdast tree as plain text.
  def mdast_text(node)
    return '' unless node.is_a?(Hash)
    paragraph = Array(node['children']).find { |child| child['type'] == 'paragraph' } || node
    collect_text(paragraph).gsub(/\s+/, ' ').strip.split(/(?<=[.!?])\s/).first.to_s
  end

  def collect_text(node)
    return node['value'].to_s if node['value']
    Array(node['children']).map { |child| collect_text(child) }.join
  end

  def text(html)
    Nokogiri::HTML.fragment(html.to_s).text.gsub(/\s+/, ' ').strip
  end

  def record(name, kind, signature, brief, platforms, group, url, url_md)
    {
      'name' => name,
      'kind' => kind,
      'signature' => signature.to_s,
      'brief' => text(brief),
      'platforms' => Array(platforms),
      'group' => group,
      'url' => url,
      'url_md' => url_md,
    }
  end

  # Write /api-index.json once the Markdown twins are known. Skipped when the
  # docs generator is off (SKIP_DOCS), since the pages it would link do not exist.
  def write(site, builder)
    return if site.config['skip_docs'].to_s == 'true'
    site_url = site.config['url'].to_s
    md_url_for = builder.method(:md_url_for)
    records = c_records(site.pages, site_url, md_url_for)
    records += js_records(site.data['jsdocs-pkjs'], '/docs/pebblekit-js/', site_url, md_url_for)
    Jekyll.logger.info('API Index:', "#{records.size} symbols")
    return if records.empty?

    tmp_root = File.join(site.source, '../tmp/api-index/')
    FileUtils.mkdir_p(tmp_root)
    File.write(File.join(tmp_root, 'api-index.json'), JSON.pretty_generate(document(records, LlmsExport.sdk_version(site))))
    site.static_files << Jekyll::StaticFile.new(site, tmp_root, '', 'api-index.json')
  end

  def document(records, sdk_version)
    {
      'sdk_version' => sdk_version,
      'notes' => 'C symbols list the SDK builds (aplite, basalt, emery) whose reference contains them. ' \
                 'A symbol present only in emery needs SDK 4.9 or later; one absent from aplite needs SDK 3.0 or later. ' \
                 'PebbleKit JS runs in the Pebble mobile app and is available for every platform.',
      'count' => records.size,
      'symbols' => records,
    }
  end
end
