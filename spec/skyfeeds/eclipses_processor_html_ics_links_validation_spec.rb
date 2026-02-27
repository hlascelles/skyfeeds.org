require "spec_helper"
require "nokogiri"

RSpec.describe Skyfeeds::EclipsesProcessor do
  describe "HTML ICS links validation" do
    let(:docs_dir) { File.join(File.dirname(__FILE__), "..", "..", "docs") }
    let(:index_html_path) { File.join(docs_dir, "index.html") }
    let(:html_content) { File.read(index_html_path) }
    let(:document) { Nokogiri::HTML(html_content) }

    it "ensures all linked .ics files exist in the docs directory" do
      described_class.run
      # Find all links ending with .ics
      ics_links = document.css('a[href$=".ics"]').map { |link| link["href"] }

      # Make sure we found some links
      expect(ics_links).not_to be_empty, "No ICS links found in index.html"

      # Verify each linked file exists
      missing_files = []

      ics_links.each do |relative_path|
        absolute_path = File.join(docs_dir, relative_path)
        missing_files << relative_path unless File.exist?(absolute_path)
      end

      # Report any missing files
      message = "The following linked ICS files are missing: #{missing_files.join(', ')}"
      expect(missing_files).to be_empty, message

      # Output some stats about the number of files checked
      puts "Validated #{ics_links.count} ICS file links in index.html"
    end

    it "validates example file specifically mentioned in requirements" do
      # Check a specific example file exists and is linked
      example_path = "europe/europe_all.ics"
      absolute_example_path = File.join(docs_dir, example_path)

      # First check if it's linked in the HTML
      is_linked = document.css("a[href$=\"#{example_path}\"]").any?
      expect(is_linked).to be_truthy,
                           "Example file #{example_path} is not linked in index.html"

      # Then check if it exists
      expect(File).to exist(absolute_example_path),
                      "Example file #{example_path} does not exist on disk"
    end
  end
end
