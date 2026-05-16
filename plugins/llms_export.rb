require_relative '../lib/llms_export.rb'

# Build per-page .md siblings and a /llms.txt index after Jekyll has rendered
# every page. A :site, :post_render hook is the only point in the pipeline
# where page.output is populated — generators run before render.
Jekyll::Hooks.register :site, :post_render do |site|
  Jekyll.logger.info('LLMS Export:', 'Building per-page .md and llms.txt...')
  begin
    LlmsExport::Builder.new(site).run
    Jekyll.logger.info('LLMS Export:', 'Done.')
  rescue StandardError => error
    Jekyll.logger.error('LLMS Export Error:', error.message)
    Jekyll.logger.error('LLMS Export Error:', error.backtrace.first(15).join("\n"))
  end
end
