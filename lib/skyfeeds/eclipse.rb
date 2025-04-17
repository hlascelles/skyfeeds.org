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

    def totalish? = [TOTAL, HYBRID, ANNULAR]

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
end
