require "fileutils"
require "icalendar"
require "erubis"
require_relative "constants"
require_relative "eclipse"
require_relative "solar_eclipses_reader"
require_relative "lunar_eclipses_reader"

module Skyfeeds
  class EclipsesProcessor
    OUTPUT_DIR = "docs".freeze

    def self.clean_output_dir
      FileUtils.rm_rf(OUTPUT_DIR)
      FileUtils.mkdir_p(OUTPUT_DIR)
    end

    def self.run
      # Clean output directory
      clean_output_dir

      # Read eclipse data
      solar_eclipses = SolarEclipsesReader.new.process
      lunar_eclipses = LunarEclipsesReader.new.process

      # Process solar eclipses
      process_solar_eclipses(solar_eclipses)

      # Process lunar eclipses
      process_lunar_eclipses(lunar_eclipses)

      # Generate combined eclipses file
      all_eclipses = solar_eclipses + lunar_eclipses
      generate_ical_file(all_eclipses, "combined/combined_eclipse_all.ics")

      # Generate HTML
      generate_html(solar_eclipses, lunar_eclipses)

      # Return all eclipses for testing purposes
      all_eclipses
    end

    def self.process_solar_eclipses(solar_eclipses)
      # Create directories
      FileUtils.mkdir_p("#{OUTPUT_DIR}/solar")

      # Generate file for all solar eclipses
      generate_ical_file(solar_eclipses, "solar/solar_eclipse_all.ics")

      # Generate files by eclipse type
      types = solar_eclipses.map(&:type).uniq
      types.each do |type|
        type_eclipses = solar_eclipses.select { |e| e.type == type }
        type_name = type.serialize.downcase
        generate_ical_file(type_eclipses, "solar/solar_eclipse_#{type_name}.ics")
      end

      # Generate files by continent
      continents = solar_eclipses.flat_map(&:continents).compact.uniq
      continents.each do |continent|
        cont_name = continent.downcase

        # Create continent directory
        FileUtils.mkdir_p("#{OUTPUT_DIR}/solar/#{cont_name}")

        # Get all eclipses for this continent
        continent_eclipses = solar_eclipses.select { |e| e.continents&.include?(continent) }

        # Generate all eclipses for this continent
        generate_ical_file(continent_eclipses,
                           "solar/#{cont_name}/solar_eclipse_#{cont_name}_all.ics")

        # Generate files by type for this continent
        continent_types = continent_eclipses.map(&:type).uniq
        continent_types.each do |type|
          type_name = type.serialize.downcase
          continent_type_eclipses = continent_eclipses.select { |e| e.type == type }
          generate_ical_file(continent_type_eclipses,
                             "solar/#{cont_name}/solar_eclipse_#{cont_name}_#{type_name}.ics")
        end
      end

      # Generate files by country (only total eclipses)
      countries = solar_eclipses.flat_map(&:countries).compact.uniq
      countries.each do |country|
        next if country.nil? || country.empty?

        country_str = country.downcase.tr(" ", "_")

        # Create country directory
        FileUtils.mkdir_p("#{OUTPUT_DIR}/solar/#{country_str}") # Get total and annular eclipses for this country
        special_eclipses = solar_eclipses.select do |e|
          e.countries&.include?(country) && e.type.totalish?
        end

        # Generate file for total & annular eclipses in this country if any exist
        if special_eclipses.any?
          generate_ical_file(special_eclipses,
                             "solar/#{country_str}/solar_eclipse_#{country_str}_total.ics")
        end
      end
    end

    def self.process_lunar_eclipses(lunar_eclipses)
      # Create directory
      FileUtils.mkdir_p("#{OUTPUT_DIR}/lunar")

      # Generate file for all lunar eclipses
      generate_ical_file(lunar_eclipses, "lunar/lunar_eclipse_all.ics")

      # Generate files by eclipse type
      types = lunar_eclipses.map(&:type).uniq
      types.each do |type|
        type_name = type.serialize.downcase
        type_eclipses = lunar_eclipses.select { |e| e.type == type }
        generate_ical_file(type_eclipses, "lunar/lunar_eclipse_#{type_name}.ics")
      end
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

      # Render the HTML
      html_content = template.result(
        solar_eclipses: solar_eclipses,
        lunar_eclipses: lunar_eclipses
      )

      # Write to file
      File.write(File.join(OUTPUT_DIR, "index.html"), html_content)
    end
  end
end
