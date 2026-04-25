require "icalendar"
require "fileutils"
require_relative "eclipse"

module Skyfeeds
  class IcalGenerator
    class << self
      def build_event(event)
        ical_event = Icalendar::Event.new

        datetime = build_datetime(event)

        ical_event.dtstart = datetime
        ical_event.dtstamp = datetime

        ical_event.summary = event.summary
        ical_event.uid = build_uid(event)
        ical_event.description = build_description(event)
        ical_event.url = event.url

        ical_event
      end

      def build_datetime(event)
        date_obj = event.date
        time_obj = event.time || Time.parse("#{date_obj}T12:00:00Z")

        DateTime.parse("#{date_obj.strftime('%Y-%m-%d')}T#{time_obj.strftime('%H:%M:%S')}")
      end

      def build_uid(event)
        event.uid_parts.join("-").downcase.tr(" ", "_")
      end

      def build_description(event)
        if event.is_a?(Skyfeeds::CelestialEvent)
          event.celestial_description
        else
          event.description
        end
      end

      # New method to create and write the calendar file
      def create_calendar(events, filename, output_dir)
        calendar = Icalendar::Calendar.new
        events.each do |event|
          calendar.add_event(build_event(event))
        end

        # Ensure directory exists
        FileUtils.mkdir_p(File.join(output_dir, File.dirname(filename)))

        # Write the calendar to the specified file
        File.write(File.join(output_dir, filename), calendar.to_ical)
      end
    end
  end
end
