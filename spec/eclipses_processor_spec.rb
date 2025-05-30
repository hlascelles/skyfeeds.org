require "spec_helper"
require "fileutils"

describe Skyfeeds::EclipsesProcessor do
  %w[
    docs/europe/europe_all.ics
    docs/europe/europe_solar_total.ics
    docs/brazil/brazil_all.ics
    docs/brazil/brazil_solar_total.ics
  ].each do |file|
    it "generates the ical file #{file}" do
      described_class.run
      raise "File not found: #{file}" unless File.exist?(file)
    end
  end
end
