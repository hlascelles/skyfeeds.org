require "csv"
require "icalendar"
require "fileutils"
require "erubis"
require "sorbet-runtime"
require_relative "constants"
require_relative "eclipse"

module Skyfeeds
  class LunarEclipsesReader
    extend T::Sig

    sig { returns(T::Array[Eclipse]) }
    def process
      eclipses = []
      CSV.foreach("config/lunar_eclipses.csv", headers: true, header_converters: :symbol) do |row|
        date = row[:date]
        time = "00:00:00"
        type = row[:type]

        # Lunar eclipses are visible from entire night side of Earth
        # We'll use "Global" as region and continent
        eclipses << Eclipse.new(
          date: Date.parse(date),
          time: Time.zone.parse("#{date} #{time}").utc,
          type: EclipseType.deserialize(type.downcase),
          region: "Global",
          countries: nil,
          continents: nil,
          category: EclipseCategory::LUNAR
        )
      end
      eclipses
    end
  end
end
