require "date"
require "sorbet-runtime"

module Skyfeeds
  class EclipseCategory < T::Enum
    enums do
      SOLAR = new
      LUNAR = new
    end

    def to_s = serialize

    def downcase = to_s.downcase
  end

  class EclipseType < T::Enum
    enums do
      TOTAL = new
      PARTIAL = new
      ANNULAR = new
      PENUMBRAL = new # Lunar only
      HYBRID = new # Solar only
    end

    TOTALISH_TYPES = [TOTAL, HYBRID, ANNULAR].freeze

    def totalish?
      TOTALISH_TYPES.include?(self)
    end

    def to_s = serialize

    def downcase = to_s.downcase
  end

  class Eclipse < T::Struct
    const :category, EclipseCategory
    const :date, Date
    const :time, Time
    const :type, EclipseType
    const :region, String
    const :countries, T.nilable(T::Array[String])
    const :continents, T.nilable(T::Array[String])

    def url
      # Generate URL based on the date
      formatted_date = date.strftime("%Y-%B-%d").downcase
      "https://www.timeanddate.com/eclipse/#{category}/#{formatted_date}"
    end
  end

  # New Enums and Structs for other celestial events
  class CelestialEventType < T::Enum
    enums do
      SUPERMOON = new
      STRAWBERRY_MOON = new
      LEONIDS_PEAK = new
      GEMINIDS_PEAK = new
    end

    def to_s = serialize
    def downcase = to_s.downcase
  end

  class CelestialEvent < T::Struct
    const :date, Date
    # The CSV has "Event Type" and "Event Name".
    # It makes sense to map "Event Type" to our CelestialEventType enum
    # and store the specific name from "Event Name" as a string.
    const :event_type, CelestialEventType
    const :event_name, String # e.g. "Full Wolf Moon", "Strawberry Moon"
    const :description, String
  end
end
