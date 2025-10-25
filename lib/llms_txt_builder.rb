require 'fileutils'

module LlmsTxt
  # Builder module for generating LLM-friendly text files from Jekyll content
  class Builder
    SEPARATOR = "---"

    def initialize(site)
      @site = site
      @base_url = site.config['url'] || ''
    end

    # Process a Jekyll collection and return formatted content
    def process_collection(collection_name)
      collection = @site.collections[collection_name]
      return '' unless collection

      content = []
      collection.docs.each do |doc|
        next if should_exclude?(doc)
        content << format_page(doc)
      end
      content.join("\n\n#{SEPARATOR}\n\n")
    end

    # Process multiple collections and return formatted content
    def process_collections(collection_names)
      content = []
      collection_names.each do |name|
        @site.collections[name]&.docs&.each do |doc|
          next if should_exclude?(doc)
          content << format_page(doc)
        end
      end
      content.join("\n\n#{SEPARATOR}\n\n")
    end

    # Process generated pages matching a URL pattern
    def process_pages(url_pattern)
      content = []
      @site.pages.each do |page|
        next unless page.url.match?(url_pattern)
        next if should_exclude?(page)
        content << format_page(page)
      end
      content.join("\n\n#{SEPARATOR}\n\n")
    end

    # Format a single page/document
    def format_page(page)
      title = extract_title(page)
      url = build_url(page.url)
      markdown_content = extract_content(page)

      output = []
      output << "# #{title}"
      output << "URL: #{url}"
      output << ""
      output << markdown_content
      output.join("\n")
    end

    # Write content to a file in the llms directory
    def write_file(filename, content, section_name = nil)
      # Create temp directory for llms files
      tmp_dir = File.join(@site.source, '../tmp/')
      llms_dir = File.join(tmp_dir, 'llms')
      FileUtils.mkdir_p(llms_dir)

      filepath = File.join(llms_dir, filename)

      output = []
      if section_name
        output << "# #{section_name}"
        output << ""
        output << "This file contains all #{section_name.downcase} from the Pebble Developer Documentation."
        output << ""
        output << SEPARATOR
        output << ""
      end
      output << content

      File.write(filepath, output.join("\n"))

      # Register the file with Jekyll as a static file so it gets copied to output
      @site.static_files << Jekyll::StaticFile.new(@site, tmp_dir, 'llms', filename)

      Jekyll.logger.info('LLMS.txt:', "Generated #{filename}")
    end

    private

    # Check if a page should be excluded from LLM files
    def should_exclude?(page)
      return true if page.data['llms_exclude'] == true

      # Exclude redirect pages (they have no useful content)
      return true if page.data['layout'] == 'redirect'

      # Exclude pages with very little content (likely stubs or redirects)
      content = page.content || ''
      return true if content.strip.length < 100

      false
    end

    # Extract the title from a page
    def extract_title(page)
      page.data['title'] || page.data['name'] || File.basename(page.url, '.*')
    end

    # Build the full URL for a page
    def build_url(path)
      "#{@base_url}#{path}"
    end

    # Extract and clean content from a page
    def extract_content(page)
      content = page.content || ''

      # Remove liquid tags and variables (including multiline)
      content = content.gsub(/\{%.*?%\}/m, '')
      content = content.gsub(/\{\{.*?\}\}/m, '')

      # Clean up extra whitespace
      content = content.gsub(/\n{3,}/, "\n\n")
      content.strip
    end
  end
end
