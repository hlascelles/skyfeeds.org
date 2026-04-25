require "fileutils"
require "icalendar"
require_relative "constants"
require_relative "eclipse"
require_relative "solar_eclipses_reader"
require_relative "lunar_eclipses_reader"
require_relative "ical_generator"
require_relative "other_celestial_events_reader" # Added require

module Skyfeeds
  class EclipsesProcessor
    extend T::Sig

    OUTPUT_DIR = "docs".freeze

    class << self
      def country_data(country)
        TZInfo::Country.all.find { |c| c.name.downcase == country.downcase }
      end

      def country_timezone(country)
        return TZInfo::Timezone.get("America/New_York") if country == "US"

        country_data(country)&.zones&.first || TZInfo::Timezone.get("UTC")
      end

      # Generic 'event' and handle potential missing time for celestial events
      def local_time_for_country(event, country)
        tzid = country_timezone(country)
        # Use event.time or default to noon UTC if not present
        time_to_convert = event.time || Time.parse("#{event.date}T12:00:00Z")
        tzid.to_local(time_to_convert)
      end

      def clean_output_dir
        FileUtils.rm_rf(OUTPUT_DIR)
        FileUtils.mkdir_p(OUTPUT_DIR)
        FileUtils.cp("views/google_calendar_import.png", OUTPUT_DIR)
        FileUtils.cp("CNAME", OUTPUT_DIR)
      end

      def run
        # Clean output directory
        clean_output_dir

        # Read eclipse data
        solar_eclipses = SolarEclipsesReader.process
        lunar_eclipses = LunarEclipsesReader.process
        celestial_events = OtherCelestialEventsReader.read # Read new celestial events

        # Process solar eclipses (pass lunar_eclipses as argument)
        process_solar_eclipses(solar_eclipses, lunar_eclipses)

        # Process lunar eclipses
        process_lunar_eclipses(lunar_eclipses)

        # Combine all events (eclipses and celestial events)
        all_events = solar_eclipses + lunar_eclipses + celestial_events
        # Sort events by date
        all_events.sort_by!(&:date)

        # Generate overall ICS feed with all events
        Skyfeeds::IcalGenerator.create_calendar(all_events, "all/all_all.ics", OUTPUT_DIR)

        # Generate HTML
        generate_html(solar_eclipses, lunar_eclipses, all_events)

        # Return all events for testing purposes
        all_events
      end

      def process_solar_eclipses(solar_eclipses, lunar_eclipses)
        # Create directories
        FileUtils.mkdir_p("#{OUTPUT_DIR}/solar")

        # Generate file for all solar eclipses
        Skyfeeds::IcalGenerator.create_calendar(
          solar_eclipses, "all/all_solar_all.ics", OUTPUT_DIR
        )

        # Generate files by continent and country
        generate_location_files(solar_eclipses, lunar_eclipses, :continents)
        generate_location_files(solar_eclipses, lunar_eclipses, :countries)
      end

      # Modified to only consider eclipses for location-specific files
      def generate_location_files(solar_eclipses, lunar_eclipses, attribute)
        locations = solar_eclipses.flat_map { |e| e.send(attribute) }.compact.uniq
        locations.each do |location|
          generate_location_file(solar_eclipses, lunar_eclipses, attribute, location)
        end
      end

      def generate_location_file(solar_eclipses, lunar_eclipses, attribute, location)
        return if location.nil? || location.empty?

        location_str = location.downcase.tr(" ", "_")
        FileUtils.mkdir_p(File.join(OUTPUT_DIR, location_str))

        # All solar eclipses for this location
        location_solar_eclipses = solar_eclipses.select do |e|
          e.send(attribute)&.include?(location)
        end

        # Only generate if there are eclipses for this location.
        # Celestial events are global and not added to location-specific files.
        return unless location_solar_eclipses.any? || lunar_eclipses.any?

        filename = "#{location_str}/#{location_str}_all.ics"
        Skyfeeds::IcalGenerator.create_calendar(
          location_solar_eclipses + lunar_eclipses, filename, OUTPUT_DIR
        )
      end

      def process_lunar_eclipses(lunar_eclipses)
        # Create directory
        FileUtils.mkdir_p("#{OUTPUT_DIR}/lunar")

        # Generate file for all lunar eclipses
        Skyfeeds::IcalGenerator.create_calendar(
          lunar_eclipses, "all/all_lunar_all.ics", OUTPUT_DIR
        )
      end

      # Updated to pass individual eclipse lists and the combined all_events list to the template.
      def generate_html(solar_eclipses, lunar_eclipses, all_events)
        view_file = "views/index.erb"
        template = Erubis::Eruby.new(File.read(view_file))

        html_content = template.result(
          solar_eclipses: solar_eclipses, # Pass solar eclipses
          lunar_eclipses: lunar_eclipses, # Pass lunar eclipses
          all_events: all_events, # Pass combined list of all events
          country_timezone: method(:country_timezone),
          local_time_for_country: method(:local_time_for_country)
        )
        File.write(File.join(OUTPUT_DIR, "index.html"), html_content)
      end
    end
  end
end
