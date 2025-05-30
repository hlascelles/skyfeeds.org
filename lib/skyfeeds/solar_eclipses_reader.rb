require "csv"
require "icalendar"
require "fileutils"
require "erubis"
require "sorbet-runtime"
require_relative "constants"
require_relative "eclipse"

module Skyfeeds
  class SolarEclipsesReader
    extend T::Sig

    sig { returns(T::Array[Eclipse]) }
    def process
      eclipses = []
      CSV.foreach("config/solar_eclipses.csv", headers: true, header_converters: :symbol) do |row|
        date = row[:calendar_date]
        time = row[:td_of_greatest_eclipse]
        type = row[:eclipse_type]
        region = row[:geographic_region_of_eclipse_visibility] || ""
        countries = (row[:countries_visible] || "").split(",").map(&:strip).uniq
        continents = determine_continents(region)

        date = Date.parse(date)
        eclipses << Eclipse.new(
          date: date,
          time: Time.zone.parse("#{date} #{time}").utc,
          type: EclipseType.deserialize(type.downcase),
          region: region,
          countries: countries,
          continents: continents,
          category: EclipseCategory::SOLAR
        )
      end
      eclipses
    end

    sig { params(region: String).returns(T::Array[String]) }
    def determine_continents(region)
      return [Constants::UNKNOWN] if region.nil?

      continents = []
      Constants::ALL_CONTINENTS.each do |continent|
        continents << continent if region.match?(/#{continent}/)
      end
      continents << Constants::UNKNOWN if continents.empty?
      continents
    end
  end
end
