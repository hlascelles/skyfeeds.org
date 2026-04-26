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
      when "Full Moon" then CelestialEventType::FULL_MOON
      when "Meteor Shower" then map_meteor_shower(name)
      when "Conjunction" then CelestialEventType::PLANETARY_CONJUNCTION
      when "Opposition" then CelestialEventType::OPPOSITION
      when "Comet Flyby" then CelestialEventType::COMET_FLYBY
      when "Transit" then CelestialEventType::TRANSIT_OF_MERCURY
      when "Planetary Parade" then CelestialEventType::PLANETARY_PARADE
      when "Elongation" then CelestialEventType::ELONGATION
      else raise "Unrecognized event type: '#{type_str}'"
      end
    end

    def self.map_meteor_shower(name)
      case name
      when /Leonids Peak/ then CelestialEventType::LEONIDS_PEAK
      when /Geminids Peak/ then CelestialEventType::GEMINIDS_PEAK
      when /Lyrids Peak/ then CelestialEventType::LYRIDS_PEAK
      when /Perseids Peak/ then CelestialEventType::PERSEIDS_PEAK
      when /Quadrantids Peak/ then CelestialEventType::QUADRANTIDS_PEAK
      when /Eta Aquariids Peak/ then CelestialEventType::ETA_AQUARIIDS_PEAK
      when /Orionids Peak/ then CelestialEventType::ORIONIDS_PEAK
      when /Ursids Peak/ then CelestialEventType::URSIDS_PEAK
      else raise "Unrecognized meteor shower: '#{name}'"
      end
    end
  end
end
