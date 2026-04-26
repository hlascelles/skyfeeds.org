require "spec_helper"
require "icalendar"

RSpec.describe Skyfeeds::EclipsesProcessor do
  let(:ics_path) { "docs/all/all_all.ics" }

  before do
    described_class.run
  end

  it "contains Leonids Peak events" do
    cal_data = File.read(ics_path)
    cal = Icalendar::Calendar.parse(cal_data).first
    leonids = cal.events.select { |e| e.summary == "Leonids Peak" }
    expect(leonids).not_to be_empty
  end

  it "contains Geminids Peak events" do
    cal_data = File.read(ics_path)
    cal = Icalendar::Calendar.parse(cal_data).first
    geminids = cal.events.select { |e| e.summary == "Geminids Peak" }
    expect(geminids).not_to be_empty
  end

  it "contains Lyrids Peak events (the April one)" do
    cal_data = File.read(ics_path)
    cal = Icalendar::Calendar.parse(cal_data).first
    lyrids = cal.events.select { |e| e.summary == "Lyrids Peak" }
    expect(lyrids).not_to be_empty

    # Check for the 2026 one specifically
    target_year = 2026
    target_month = 4
    lyrids_current_year = lyrids.find do |e|
      e.dtstart.year == target_year && e.dtstart.month == target_month
    end
    expect(lyrids_current_year).not_to be_nil
    expect(lyrids_current_year.dtstart.day).to be_between(20, 23)
  end
end
