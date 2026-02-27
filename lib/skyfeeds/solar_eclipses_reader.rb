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

    class << self
      extend T::Sig

      sig { returns(T::Array[Eclipse]) }
      def process
        eclipses = []
        CSV.foreach("config/solar_eclipses.csv", headers: true, header_converters: :symbol) do |row|
          eclipses << map_row_to_eclipse(row)
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

      sig { params(row: CSV::Row).returns(Eclipse) }
      private def map_row_to_eclipse(row)
        date = Date.parse(row[:calendar_date])
        region = row[:geographic_region_of_eclipse_visibility] || ""
        countries = (row[:countries_visible] || "").split(",").map(&:strip).uniq

        Eclipse.new(
          date: date,
          time: Time.zone.parse("#{date} #{row[:td_of_greatest_eclipse]}").utc,
          type: EclipseType.deserialize(row[:eclipse_type].downcase),
          region: region,
          countries: countries,
          continents: determine_continents(region),
          category: EclipseCategory::SOLAR
        )
      end
    end
  end
end
