require "fileutils"
require "icalendar"
require "erubis"
require_relative "constants"
require_relative "eclipse"
require_relative "solar_eclipses_reader"
require_relative "lunar_eclipses_reader"

module Skyfeeds
  class EclipsesProcessor
    extend T::Sig

    OUTPUT_DIR = "docs".freeze

    def self.country_data(country)
      TZInfo::Country.all.find { |c| c.name.downcase == country.downcase }
    end

    def self.country_timezone(country)
      return TZInfo::Timezone.get("America/New_York") if country == "US"

      country_data(country)&.zones&.first || TZInfo::Timezone.get("UTC")
    end

    def self.local_time_for_country(eclipse, country)
      tzid = country_timezone(country)
      tzid.to_local(eclipse.time)
    end

    def self.clean_output_dir
      FileUtils.rm_rf(OUTPUT_DIR)
      FileUtils.mkdir_p(OUTPUT_DIR)
      FileUtils.cp("views/google_calendar_import.png", OUTPUT_DIR)
    end

    def self.run
      # Clean output directory
      clean_output_dir

      # Read eclipse data
      solar_eclipses = SolarEclipsesReader.new.process
      lunar_eclipses = LunarEclipsesReader.new.process

      # Process solar eclipses (pass lunar_eclipses as argument)
      process_solar_eclipses(solar_eclipses, lunar_eclipses)

      # Process lunar eclipses
      process_lunar_eclipses(lunar_eclipses)

      all_eclipses = solar_eclipses + lunar_eclipses
      generate_ical_file(all_eclipses, "all/all_all.ics")

      # Generate HTML
      generate_html(solar_eclipses, lunar_eclipses)

      # Return all eclipses for testing purposes
      all_eclipses
    end

    def self.process_solar_eclipses(solar_eclipses, lunar_eclipses)
      # Create directories
      FileUtils.mkdir_p("#{OUTPUT_DIR}/solar")

      # Generate file for all solar eclipses
      generate_ical_file(solar_eclipses, "all/all_solar_all.ics")

      # Generate files by continent (all solar eclipses and all celestial events)
      continents = solar_eclipses.flat_map(&:continents).compact.uniq
      continents.each do |continent|
        next if continent.nil? || continent.empty?

        continent_str = continent.downcase.tr(" ", "_")
        continent_dir = File.join(OUTPUT_DIR, continent_str)
        FileUtils.mkdir_p(continent_dir)

        # All solar eclipses for this continent
        continent_solar_eclipses = solar_eclipses.select { |e| e.continents&.include?(continent) }
        if continent_solar_eclipses.any?
          generate_ical_file(continent_solar_eclipses,
                             "#{continent_str}/#{continent_str}_solar_total.ics")
        end

        # All celestial events: all solar for this continent + all lunar globally
        if continent_solar_eclipses.any? || lunar_eclipses.any?
          generate_ical_file(continent_solar_eclipses + lunar_eclipses,
                             "#{continent_str}/#{continent_str}_all.ics")
        end
      end

      # Generate files by country (all solar eclipses and all celestial events)
      countries = solar_eclipses.flat_map(&:countries).compact.uniq
      countries.each do |country|
        next if country.nil? || country.empty?

        country_str = country.downcase.tr(" ", "_")
        country_dir = File.join(OUTPUT_DIR, country_str)
        FileUtils.mkdir_p(country_dir)

        # All solar eclipses for this country
        country_solar_eclipses = solar_eclipses.select { |e| e.countries&.include?(country) }
        if country_solar_eclipses.any?
          generate_ical_file(country_solar_eclipses, "#{country_str}/#{country_str}_solar_total.ics")
        end

        # All celestial events: all solar for this country + all lunar globally
        if country_solar_eclipses.any? || lunar_eclipses.any?
          generate_ical_file(country_solar_eclipses + lunar_eclipses,
                             "#{country_str}/#{country_str}_all.ics")
        end
      end
    end

    def self.process_lunar_eclipses(lunar_eclipses)
      # Create directory
      FileUtils.mkdir_p("#{OUTPUT_DIR}/lunar")

      # Generate file for all lunar eclipses
      generate_ical_file(lunar_eclipses, "all/all_lunar_all.ics")
    end

    def self.generate_ical_file(eclipses, filename)
      cal = Icalendar::Calendar.new

      eclipses.each do |eclipse|
        event = Icalendar::Event.new

        # Set event details
        date_str = eclipse.date.strftime("%Y-%m-%d")
        time_str = eclipse.time.strftime("%H:%M:%S")
        datetime = DateTime.parse("#{date_str}T#{time_str}")
        event.dtstart = datetime
        event.dtstamp = datetime
        event.summary = "#{eclipse.type} #{eclipse.category} Eclipse"

        # Create a UID without spaces
        event.uid = "#{date_str}-#{time_str}-#{eclipse.type}-#{eclipse.category}".downcase.tr(
          " ", "_"
        )

        # Add description
        description = "Type: #{eclipse.type} #{eclipse.category} Eclipse"

        description += "\nRegion: #{eclipse.region}" if eclipse.region && !eclipse.region.empty?

        description += "\nCountries: #{eclipse.countries.join(', ')}" if eclipse.countries&.any?

        event.description = description

        # Add to calendar
        cal.add_event(event)
      end

      # Write to file
      filepath = File.join(OUTPUT_DIR, filename)
      FileUtils.mkdir_p(File.dirname(filepath))
      File.write(filepath, cal.to_ical)
    end

    def self.generate_html(solar_eclipses, lunar_eclipses)
      view_file = "views/index.erb"
      template = Erubis::Eruby.new(File.read(view_file))

      html_content = template.result(
        solar_eclipses: solar_eclipses,
        lunar_eclipses: lunar_eclipses,
        country_timezone: method(:country_timezone),
        local_time_for_country: method(:local_time_for_country)
      )
      File.write(File.join(OUTPUT_DIR, "index.html"), html_content)
    end
  end
end
