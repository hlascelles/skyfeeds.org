require "spec_helper"
require "fileutils"

describe Skyfeeds::SolarEclipsesReader do
  it "processes the CSV file and generates eclipses" do
    eclipses = described_class.process
    expect(eclipses).not_to be_empty
    expect(eclipses.first.type).to be_a Skyfeeds::EclipseType
  end
end
