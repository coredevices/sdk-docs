require_relative '../lib/llms_txt_builder.rb'

module Jekyll
  # Generator for creating LLM-friendly text files from documentation
  class GeneratorLlmsTxt < Generator
    # Run last so all other generators have completed
    priority :lowest

    def generate(site)
      @site = site
      @builder = LlmsTxt::Builder.new(site)

      Jekyll.logger.info('LLMS.txt:', 'Generating LLM documentation files...')

      begin
        generate_guides
        generate_api_docs
        generate_community

        Jekyll.logger.info('LLMS.txt:', 'Done.')
      rescue StandardError => e
        Jekyll.logger.error('LLMS.txt Error:', e.message)
        Jekyll.logger.error('LLMS.txt Error:', e.backtrace.join("\n"))
      end
    end

    private

    # Generate guides.txt from the guides collection
    def generate_guides
      content = @builder.process_collection('guides')
      if content.empty?
        Jekyll.logger.warn('LLMS.txt:', 'No guides found to process')
        return
      end
      @builder.write_file('guides.txt', content, 'Guides')
    end

    # Generate api-docs.txt from generated API documentation pages
    def generate_api_docs
      # Match pages under /docs/ that are actual API documentation
      # This includes C, Android, iOS, JavaScript, and Rocky.js docs
      api_patterns = [
        %r{^/docs/c/},
        %r{^/docs/pebblekit-android/},
        %r{^/docs/pebblekit-ios/},
        %r{^/docs/pebblekit-js/},
        %r{^/docs/rockyjs/}
      ]

      content = []
      api_patterns.each do |pattern|
        pattern_content = @builder.process_pages(pattern)
        content << pattern_content unless pattern_content.empty?
      end

      if content.empty?
        Jekyll.logger.warn('LLMS.txt:', 'No API docs found to process (DOCS_URL not set or no valid content)')
        return
      end

      separator = "\n\n#{LlmsTxt::Builder::SEPARATOR}\n\n"
      @builder.write_file('api-docs.txt', content.join(separator), 'API Documentation')
    end

    # Generate community.txt from community collections
    def generate_community
      community_collections = ['community_tools', 'community_apps', 'community_libraries']
      content = @builder.process_collections(community_collections)

      if content.empty?
        Jekyll.logger.warn('LLMS.txt:', 'No community resources found to process')
        return
      end

      @builder.write_file('community.txt', content, 'Community Resources')
    end
  end
end
