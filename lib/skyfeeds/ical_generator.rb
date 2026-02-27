require "icalendar"
require "fileutils"

module Skyfeeds
  class IcalGenerator
    class << self
      def generate_ical_file(eclipses, filename, output_dir)
        cal = Icalendar::Calendar.new
        eclipses.each { |eclipse| cal.add_event(build_event(eclipse)) }

        # Write to file
        filepath = File.join(output_dir, filename)
        FileUtils.mkdir_p(File.dirname(filepath))
        File.write(filepath, cal.to_ical)
      end

      def build_event(eclipse)
        event = Icalendar::Event.new
        date_str = eclipse.date.strftime("%Y-%m-%d")
        time_str = eclipse.time.strftime("%H:%M:%S")
        datetime = DateTime.parse("#{date_str}T#{time_str}")

        event.dtstart = datetime
        event.dtstamp = datetime
        event.summary = build_summary(eclipse)
        event.uid = build_uid(eclipse, date_str, time_str)
        event.description = build_description(eclipse)
        event.url = eclipse.url
        event
      end

      def build_uid(eclipse, date_str, time_str)
        uid = "#{date_str}-#{time_str}-#{eclipse.type}-#{eclipse.category}"
        uid.downcase.tr(" ", "_")
      end

      def build_summary(eclipse)
        "#{eclipse.type.to_s.capitalize} #{eclipse.category.to_s.capitalize} Eclipse"
      end

      def build_description(eclipse)
        type_str = build_summary(eclipse)
        description = "Type: #{type_str}"

        if eclipse.region && !eclipse.region.empty?
          description += "\nRegion: #{format_region(eclipse.region)}"
        end

        description += "\nCountries: #{eclipse.countries.join(', ')}" if eclipse.countries&.any?
        description += "\nMore info: #{eclipse.url}"
        description
      end

      def format_region(region)
        # Expand NASA single-letter directional abbreviations (s Africa → S. Africa)
        region.gsub(/\b(?<dir>[nsewc]) /) do
          "#{Regexp.last_match[:dir].upcase}. "
        end
      end
    end
  end
end
