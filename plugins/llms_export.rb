require_relative '../lib/llms_export.rb'
require_relative '../lib/api_index.rb'

# Before rendering, mark the pages that will get a .md twin so master.html can
# link to it with <link rel="alternate" type="text/markdown">.
Jekyll::Hooks.register :site, :pre_render do |site, _payload|
  LlmsExport::Builder.mark_pages(site)
end

# Build per-page .md siblings, /llms.txt, the llms-full.txt files and
# /api-index.json after
# Jekyll has rendered every page. A :site, :post_render hook is the only point
# in the pipeline where page.output is populated — generators run before render.
Jekyll::Hooks.register :site, :post_render do |site|
  Jekyll.logger.info('LLMS Export:', 'Building per-page .md and llms.txt...')
  begin
    builder = LlmsExport::Builder.new(site)
    builder.run
    ApiIndex.write(site, builder)
    Jekyll.logger.info('LLMS Export:', 'Done.')
  rescue StandardError => error
    Jekyll.logger.error('LLMS Export Error:', error.message)
    Jekyll.logger.error('LLMS Export Error:', error.backtrace.first(15).join("\n"))
  end
end
