require "spec_helper"
require "fileutils"

describe Skyfeeds::EclipsesProcessor do
  it "generates the icals" do
    described_class.run
    [
      "docs/solar/solar_eclipse_all.ics",
      "docs/solar/solar_eclipse_annular.ics",
      "docs/solar/africa/solar_eclipse_africa_partial.ics",
      "docs/solar/africa/solar_eclipse_africa_total.ics",
      "docs/solar/mexico/solar_eclipse_mexico_total.ics",
      "docs/lunar/lunar_eclipse_partial.ics",
    ].each do |file|
      raise "File not found: #{file}" unless File.exist?(file)
    end
  end
end
