require "spec_helper"
require "fileutils"

describe Skyfeeds::LunarEclipsesReader do
  let(:processor) { described_class.new }

  it "processes the CSV file and generates eclipses" do
    eclipses = processor.process
    expect(eclipses).not_to be_empty
    expect(eclipses.first.type).to be_a Skyfeeds::EclipseType
  end
end
