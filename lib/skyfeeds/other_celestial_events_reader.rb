require "csv"
require "sorbet-runtime"
require_relative "eclipse" # To use CelestialEvent and CelestialEventType

module Skyfeeds
  class OtherCelestialEventsReader
    extend T::Sig

    # Path to the CSV file
    CSV_PATH = "config/other_celestial_events.csv".freeze

    sig { returns(T::Array[CelestialEvent]) }
    def self.read
      events = []
      CSV.foreach(CSV_PATH, headers: true) do |row|
        events << CelestialEvent.new(
          date: Date.parse(row["Date"]),
          event_type: map_event_type(row["Event Type"], row["Event Name"]),
          event_name: row["Event Name"],
          description: row["Description"]
        )
      end
      events
    end

    def self.map_event_type(type_str, name)
      case type_str
      when "Supermoon" then CelestialEventType::SUPERMOON
      when "Full Moon"
        raise "Unrecognized Full Moon: '#{name}'" unless name.downcase.include?("strawberry moon")

        CelestialEventType::STRAWBERRY_MOON
      when "Meteor Shower" then map_meteor_shower(name)
      else raise "Unrecognized event type: '#{type_str}'"
      end
    end

    def self.map_meteor_shower(name)
      case name
      when /Leonids Peak/ then CelestialEventType::LEONIDS_PEAK
      when /Geminids Peak/ then CelestialEventType::GEMINIDS_PEAK
      when /Lyrids Peak/ then CelestialEventType::LYRIDS_PEAK
      else raise "Unrecognized meteor shower: '#{name}'"
      end
    end
  end
end
