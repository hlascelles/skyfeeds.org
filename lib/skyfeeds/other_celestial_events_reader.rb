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
        date = Date.parse(row["Date"])
        event_type_str = row["Event Type"]
        event_name = row["Event Name"]
        description = row["Description"]

        # Revised mapping logic to correctly handle 'Full Moon' and 'Meteor Shower' types
        event_type = if event_type_str == "Supermoon"
                       CelestialEventType::SUPERMOON
                     elsif event_type_str == "Full Moon" &&
                           event_name.downcase.include?("strawberry moon")
                       CelestialEventType::STRAWBERRY_MOON
                     elsif event_type_str == "Meteor Shower"
                       case event_name
                       when /Leonids Peak/ then CelestialEventType::LEONIDS_PEAK
                       when /Geminids Peak/ then CelestialEventType::GEMINIDS_PEAK
                       else
                         # Raise an error if the meteor shower name is not recognized
                         raise "Unrecognized meteor shower name: '#{event_name}' in #{CSV_PATH}"
                       end
                     else
                       # Raise an error for any other unrecognized event types
                       raise "Unrecognized event type: '#{event_type_str}' in #{CSV_PATH}"
                     end

        events << CelestialEvent.new(
          date: date,
          event_type: event_type,
          event_name: event_name,
          description: description
        )
      end
      events
    end
  end
end
