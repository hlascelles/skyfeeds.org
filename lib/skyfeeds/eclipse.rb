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

    def summary
      "#{type.to_s.capitalize} #{category.to_s.capitalize} Eclipse"
    end

    def description
      desc = "Type: #{summary}"
      desc += "\nRegion: #{region_formatted}" if region && !region.empty?
      desc += "\nCountries: #{countries.join(', ')}" if countries&.any?
      desc += "\nMore info: #{url}"
      desc
    end

    def uid_parts
      [date.strftime("%Y-%m-%d"), time.strftime("%H:%M:%S"), type.to_s, category.to_s]
    end

    private def region_formatted
      # Expand NASA single-letter directional abbreviations (s Africa → S. Africa)
      region.gsub(/\b(?<dir>[nsewc]) /) do
        "#{Regexp.last_match[:dir].upcase}. "
      end
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

    def time
      nil
    end

    def url
      nil
    end

    def summary
      event_name.capitalize
    end

    def celestial_description
      event_type_formatted = event_type.to_s.tr("_", " ").capitalize
      "Type: #{event_type_formatted}\nName: #{event_name}\n#{description}"
    end

    def uid_parts
      type = event_type.to_s.downcase.tr("_", "-")
      name = event_name.downcase.gsub(/[^a-z0-9]+/, "-")
      [date.strftime("%Y-%m-%d"), "12:00:00", type, name]
    end
  end
end
