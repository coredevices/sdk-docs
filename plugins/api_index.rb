require_relative '../lib/api_index.rb'

# Emit /api-index.json from the parsed doxygen data (C) and the PebbleKit JS
# jsdocs. Runs after DocsGenerator (priority :high) so the C pages exist; when
# they do not (local builds, SKIP_DOCS) only the JS symbols are written.
module Jekyll
  class ApiIndexGenerator < Generator
    priority :low

    def generate(site)
      site_url = site.config['url'].to_s
      records = ApiIndex.c_records(site.pages, site_url)
      records += ApiIndex.js_records(site.data['jsdocs-pkjs'], '/docs/pebblekit-js/', site_url)
      Jekyll.logger.info('API Index:', "#{records.size} symbols")
      return if records.empty?

      tmp_root = File.join(site.source, '../tmp/api-index/')
      FileUtils.mkdir_p(tmp_root)
      document = ApiIndex.document(records, LlmsExport.sdk_version(site))
      File.write(File.join(tmp_root, 'api-index.json'), JSON.pretty_generate(document))
      site.static_files << Jekyll::StaticFile.new(site, tmp_root, '', 'api-index.json')
    end
  end
end
